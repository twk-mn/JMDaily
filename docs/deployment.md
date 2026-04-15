# Deployment Guide — Railway + Cloudflare R2

This guide walks through deploying JMDaily to [Railway](https://railway.com) with [Cloudflare R2](https://developers.cloudflare.com/r2/) for image storage.

---

## Overview

The app runs as two Railway services sharing one Postgres database:

| Service | What it does |
|---------|-------------|
| **web** | Puma web server — handles HTTP requests |
| **worker** | SolidQueue — runs background jobs (newsletter sending, sitemap regeneration, scheduled article publishing) |

---

## Step 1 — Cloudflare R2

Images and file uploads are stored on R2. Do this first so you have the credentials ready.

### 1a. Create a Cloudflare account

Go to [cloudflare.com](https://cloudflare.com) and sign up (free).

### 1b. Create an R2 bucket

1. In the Cloudflare dashboard, click **R2** in the left sidebar
2. Click **Create bucket**
3. Name it `jmdaily-production` (or whatever you prefer — you'll set `R2_BUCKET` to match)
4. Region: leave as **Automatic**
5. Click **Create bucket**

### 1c. Enable public access

Public access lets images be served directly from R2 without going through your app server.

1. Open the bucket → **Settings** tab
2. Under **Public access**, click **Allow Access**
3. Note the public bucket URL — it looks like:
   `https://pub-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.r2.dev`
   You don't need to set this as an env var right now, but it's useful to know.

### 1d. Create an API token

1. In the R2 sidebar, click **Manage R2 API Tokens**
2. Click **Create API Token**
3. Give it a name (e.g. `jmdaily-production`)
4. Under **Permissions**, add **Workers R2 Storage** → **Read & Write**
5. Specify bucket: select `jmdaily-production`
6. Click **Create API Token**
7. **Save these immediately** — the secret key is only shown once:
   - Access Key ID → `R2_ACCESS_KEY_ID`
   - Secret Access Key → `R2_SECRET_ACCESS_KEY`

### 1e. Find your Account ID

On any R2 page, your Account ID is in the URL:
`https://dash.cloudflare.com/<ACCOUNT_ID>/r2/...`

That value is your `R2_ACCOUNT_ID`.

---

## Step 2 — Railway project

### 2a. Create the project

1. Go to [railway.com](https://railway.com) and sign up / log in
2. Click **New Project** → **Deploy from GitHub repo**
3. Connect your GitHub account and select the `JMDaily` repository
4. Railway will detect the `Dockerfile` automatically

### 2b. Add a Postgres database

1. In your project, click **+ New** → **Database** → **PostgreSQL**
2. Railway provisions the database and automatically sets `DATABASE_URL` in your project environment

### 2c. Configure environment variables

In the Railway project, click **Variables** and add each of the following:

#### Required

| Variable | Value | Notes |
|----------|-------|-------|
| `RAILS_MASTER_KEY` | _(contents of `config/master.key`)_ | Open the file locally and paste the contents |
| `APP_HOST` | `yourdomain.com` | Your production domain, no `https://` |
| `EDITOR_EMAIL` | `you@example.com` | Where contact form and tip emails are delivered |
| `R2_ACCOUNT_ID` | _(from step 1e)_ | |
| `R2_ACCESS_KEY_ID` | _(from step 1d)_ | |
| `R2_SECRET_ACCESS_KEY` | _(from step 1d)_ | |
| `R2_BUCKET` | `jmdaily-production` | Must match the bucket name from step 1b |
| `SMTP_USERNAME` | _(Postmark server API token)_ | Create at postmarkapp.com |
| `SMTP_PASSWORD` | _(same as SMTP_USERNAME)_ | Postmark uses the same value for both |

#### Optional

| Variable | Default | Notes |
|----------|---------|-------|
| `RAILS_LOG_LEVEL` | `info` | Set to `debug` to troubleshoot |
| `JOB_CONCURRENCY` | `2` | Number of SolidQueue worker processes |
| `SENTRY_DSN` | _(blank)_ | Error tracking — get from sentry.io |
| `SMTP_HOST` | `smtp.postmarkapp.com` | Only change if not using Postmark |
| `SMTP_PORT` | `587` | |

> **Note:** `DATABASE_URL` is set automatically by the Railway Postgres plugin — do not set it manually.

### 2d. Add the worker service

Railway runs one process per service. The background job worker needs its own service.

1. In your project, click **+ New** → **GitHub Repo** (same repo again)
2. In the new service settings, override the start command:
   - Go to **Settings** → **Deploy** → **Custom Start Command**
   - Set it to: `bundle exec rails solid_queue:start`
3. Point it at the same environment variables (Railway lets you share variable groups, or just add them again)

Alternatively, if you're on a paid Railway plan, you can define both services in a `railway.json` — but the manual approach above works fine.

### 2e. Set your custom domain

1. In the **web** service → **Settings** → **Networking** → **Custom Domain**
2. Add your domain (e.g. `jmdaily.com`)
3. Railway shows you a CNAME record — add it in your DNS provider
4. Railway handles SSL automatically via Let's Encrypt

---

## Step 3 — First deploy

Once env vars are set, trigger a deploy:

1. Push any commit to `main` (or click **Deploy** in the Railway dashboard)
2. Railway builds the Docker image and runs `bin/docker-entrypoint`, which runs `rails db:prepare` — this creates the database schema on first boot
3. Watch the deploy logs — a successful boot looks like:

```
* Listening on http://0.0.0.0:3000
```

### Verify everything works

- `https://yourdomain.com/up` → should return `200 OK`
- `https://yourdomain.com/en` → homepage loads
- `https://yourdomain.com/en/admin` → admin login page
- Upload a featured image to an article → confirm it appears after saving

---

## Step 4 — Create the first admin user

Rails console via Railway:

1. In the Railway dashboard, open the **web** service
2. Click **Shell** (or use the Railway CLI: `railway run rails console`)
3. Run:

```ruby
User.create!(
  name: "Your Name",
  email: "you@example.com",
  password: "a-strong-password",
  password_confirmation: "a-strong-password",
  role: "admin"
)
```

---

## Background jobs

The worker service runs these automatically:

| Job | Schedule | What it does |
|-----|----------|-------------|
| `PublishScheduledArticlesJob` | Every 5 minutes | Publishes articles whose `published_at` has passed |
| `RegenerateSitemapJob` | Daily at 3am | Rebuilds `sitemap.xml` |
| `SolidQueue::Job` cleanup | Hourly | Clears finished job records |

Newsletter broadcasts are triggered manually from the admin panel.

---

## Ongoing deploys

Every push to `main` triggers a new Railway deploy automatically. Migrations run on boot via `rails db:prepare` — this is safe for additive migrations but worth reviewing before deploying destructive schema changes.

---

## Troubleshooting

**App crashes on boot**
- Check `RAILS_MASTER_KEY` is set correctly — it should be the raw hex string from `config/master.key`
- Check `DATABASE_URL` is set (should be automatic from the Postgres plugin)

**Images not uploading**
- Verify all four `R2_*` env vars are set
- Confirm the R2 bucket has public access enabled
- Check the worker service logs — Active Storage variants are processed in the background

**Emails not sending**
- Confirm `SMTP_USERNAME` and `SMTP_PASSWORD` are your Postmark server API token
- In Postmark, make sure the sending domain (`APP_HOST`) is verified

**Health check failing (`/up` returns non-200)**
- Usually means the app crashed on boot — check deploy logs for the error
