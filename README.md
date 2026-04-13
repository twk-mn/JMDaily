# JMDaily

A local news publication platform built with Ruby on Rails. Supports article publishing, newsletters, reader comments, ads, and a full admin CMS.

## Tech Stack

- **Ruby** 3.4.7 / **Rails** 8.1.3
- **PostgreSQL** — primary database + full-text search
- **Tailwind CSS** — styling
- **Hotwire** (Turbo + Stimulus) — SPA-like interactivity without a JS framework
- **Active Storage** + image_processing — featured image uploads with WebP variants
- **Action Text** (Trix) — rich-text article body
- **Solid Queue** — background jobs backed by PostgreSQL (no Redis required)
- **Pagy** — pagination
- **Rack::Attack** — rate limiting
- **Sentry** — error monitoring (production only)

## Features

### Public site

- Article listing by category, tag, author, and location
- Full-text search
- Reader comments (moderated, with honeypot spam protection)
- Newsletter subscription with double opt-in confirmation
- RSS feed and auto-generated sitemap
- Ad display with click tracking

### Admin CMS (`/admin`)

- Dashboard with at-a-glance stats and recent activity
- Article editor with rich text, featured image upload, scheduling, and bulk actions
- Category, tag, author, location, and static page management
- Comment moderation (approve / reject)
- Newsletter: compose issues, preview rendered email, send to all active subscribers
- Newsletter subscriber management
- Ad management
- Contact and tip submission inbox
- Audit log
- Two-factor authentication (TOTP)

## Setup

### Prerequisites

- Ruby 3.4.7 (managed via `.ruby-version`)
- PostgreSQL 14+
- Node.js (for Tailwind CSS build)

### Local development

```bash
# Install dependencies
bundle install

# Create and migrate the database
bin/rails db:create db:migrate

# (Optional) Seed sample data
bin/rails db:seed

# Start all processes (web + CSS watcher + Solid Queue worker)
bin/dev
```

The app runs at `http://localhost:3000`. The admin panel is at `/admin`.

### Environment variables

| Variable | Required | Description |
| --- | --- | --- |
| `DATABASE_URL` | Development default works | PostgreSQL connection string |
| `SECRET_KEY_BASE` | Yes (production) | Rails secret key |
| `SENTRY_DSN` | No | Sentry error reporting DSN (production only) |
| `SMTP_*` | Yes (production) | Mail delivery settings |

### Creating the first admin user

```bash
bin/rails console
User.create!(email: "you@example.com", password: "...", role: "admin")
```

## Testing

```bash
# Run the full test suite
bundle exec rspec

# Run with coverage report
COVERAGE=true bundle exec rspec
```

Coverage must remain above 80% (enforced by SimpleCov).

## CI

GitHub Actions runs four jobs on every push and pull request:

| Job | Tool |
| --- | --- |
| Security scan | Brakeman |
| Dependency audit | Bundler Audit |
| Style | RuboCop (rubocop-rails-omakase) |
| Tests | RSpec with PostgreSQL 17 service |

## Deployment

The app is a standard Rails 8 application. It expects:

- A PostgreSQL database
- Solid Queue worker process (`bin/jobs`) running alongside the web server
- Active Storage configured (local disk by default; configure S3 or similar for production)

A `Procfile.dev` is provided for local multi-process development via `bin/dev`.
