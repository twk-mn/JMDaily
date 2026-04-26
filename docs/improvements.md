# JMDaily — Improvements & Roadmap

> This document tracks identified gaps, planned features, and implementation notes
> for work beyond the v1 MVP. Reference `spec01.md` for original product decisions.
>
> Status key: `[ ]` not started · `[~]` in progress · `[x]` done

---

## Priority Overview

| # | Area | Item | Priority |
|---|------|------|----------|
| 1 | Feature | Ad management system | High |
| 2 | Feature | Article scheduling (background job) | High |
| 3 | Feature | Contact submission admin inbox | High |
| 4 | Feature | User management admin UI | High |
| 5 | Security | Content Security Policy | High |
| 6 | Security | Session timeout for admin | High |
| 7 | Feature | RBAC — editor vs admin permissions | Medium |
| 8 | Feature | Full-text article body search | Medium |
| 9 | Feature | Image variants / responsive images | Medium |
| 10 | Feature | Email delivery configuration | Medium |
| 11 | Security | Password complexity enforcement | Medium |
| 12 | Security | Admin audit log | Medium |
| 13 | Feature | Tip submission form + inbox | Low |
| 14 | Feature | Newsletter subscriber capture | Low |
| 15 | Feature | Social sharing buttons | Low |
| 16 | Security | Two-factor authentication for admin | Low |
| 17 | Frontend | Custom 404/500 error pages | Low |
| 18 | Frontend | Print stylesheet for articles | Low |
| 19 | Ops | Sitemap auto-regeneration job | Low |
| 20 | Ops | Rotate default seed credentials | Immediate |
| 21 | Security | Cloudflare Turnstile on public-facing forms | High |
| 22 | Frontend | Admin nav overflow — group into dropdowns | High |

---

## Immediate Action

### [x] Rotate default seed credentials

The seeds file creates `admin@jmdaily.com` / `password123`. If this was ever
run in a non-development environment, those credentials must be changed immediately.

**Fix:** Update `db/seeds.rb` to only run in development and use ENV-provided passwords:

```ruby
raise "Seeds should only run in development" unless Rails.env.development?
```

---

## 1. Ad Management System

> Spec reference: section 17 (monetization) and section 7 (v1 non-goal, now a v1.5+ item)

### Background

The site currently has zero ad or monetization infrastructure. The goal is a clean,
flexible system that supports:

- **Direct-sold ads** — local businesses or sponsors buy a banner placement directly.
  These are image + link + optional label, with defined flight dates.
- **Programmatic ads** — AdSense or similar networks via embed code/script injection.
- **Custom HTML ads** — newsletter sponsor callouts, text-based sponsored content labels.

The system must respect the publication's credibility-first design principle:
ads should be placed deliberately, not injected everywhere automatically.

### Placement Zones

Define a fixed set of named zones. Views check for active ads in a zone and render them:

| Zone name | Location in UI |
|-----------|----------------|
| `header_banner` | Below main nav, above content — leaderboard (728×90 or 970×90) |
| `article_inline` | After 2nd paragraph of article body |
| `article_sidebar` | Sidebar next to article content (desktop only) |
| `article_footer` | Below article body, above related articles |
| `homepage_mid` | Between lead story and latest news list |
| `category_mid` | Between rows on category / archive pages |
| `footer_banner` | Above site footer |

### Data Model

**New table: `ads`**

```
id                  integer, primary key
name                string, not null           — internal label (e.g. "Myoko Tourism April")
ad_type             string, not null           — enum: direct | adsense | custom_html
placement_zone      string, not null           — enum: matches zone names above
status              string, default: "active"  — enum: active | paused | archived

# Direct ad fields
image               Active Storage attachment  — banner image file
link_url            string                     — destination URL when clicked
link_target         string, default: "_blank"  — "_blank" or "_self"
sponsor_label       string                     — optional "Sponsored by X" label

# Programmatic / custom HTML
script_code         text                       — raw embed/script HTML (AdSense tag, etc.)

# Scheduling
starts_at           datetime                   — nil means no start restriction
ends_at             datetime                   — nil means runs indefinitely

# Targeting (optional refinement, phase 2)
target_category_id  integer, FK categories     — nil means show on all categories
target_location_id  integer, FK locations      — nil means show everywhere

# Tracking (direct ads only)
impressions_count   integer, default: 0
clicks_count        integer, default: 0

# Ordering
priority            integer, default: 0        — higher = shown first if multiple match

created_at, updated_at
```

### Display Logic

A helper method `ad_for(zone)` in `ApplicationHelper`:

1. Query active ads for the given zone where today is within `starts_at..ends_at`
2. Order by `priority DESC`, take the highest-priority one
3. If `ad_type == "direct"`: render image wrapped in tracked link
4. If `ad_type == "adsense"` or `"custom_html"`: render `script_code` as raw HTML

Impression tracking: increment `impressions_count` when `ad_for` renders.
Click tracking: route clicks through `/ads/:id/click` before redirecting to `link_url`.

### Admin UI

New section in admin: **Ads** at `/admin/ads`

- Index: table of all ads with zone, type, status, flight dates, impressions, clicks
- New/Edit form: fields change based on `ad_type` selection (JS show/hide)
- Quick status toggle (active/paused) from index
- Delete with confirmation

### CSP Considerations

AdSense and most ad networks require relaxed CSP rules. When implementing ads:

- Re-enable `config/initializers/content_security_policy.rb`
- Allow `https://pagead2.googlesyndication.com` in `script-src` for AdSense
- Use `nonce:` based CSP rather than blanket `unsafe-inline`
- Direct image ads are served locally via Active Storage — no CSP changes needed

### Implementation Steps

- [x] Write migration for `ads` table
- [x] Create `Ad` model with validations and scopes
- [x] Create `Admin::AdsController` (index, new, create, edit, update, destroy)
- [x] Create admin views for ads
- [x] Create `ad_for(zone)` helper and `_ad.html.erb` partial
- [x] Add click tracking route and `AdsController#click` action
- [x] Insert `ad_for` calls into layout partials at each zone
- [x] Write specs for Ad model and click tracking
- [ ] Configure CSP to allow ad network scripts (deferred until ad networks are actually wired up)

---

## 2. Article Scheduling (Background Job)

### Background

Articles can be set to `scheduled` status with a `published_at` date/time, but there
is no mechanism to automatically publish them. This currently means "scheduled" is
effectively the same as "draft."

### Plan

- [x] Add `Solid Queue` to `Gemfile` (PostgreSQL-backed, no Redis needed)
- [x] Create `PublishScheduledArticlesJob` — queries `where(status: "scheduled").where("published_at <= ?", Time.current)`, bulk-updates to `published`
- [x] Schedule job to run every 5 minutes via `config/recurring.yml`
- [x] Solid Queue tables created via migration `20260410000002`
- [x] Active Job adapter set to `:solid_queue` in production
- [x] Regenerate sitemap after bulk publish — `PublishScheduledArticlesJob` enqueues `RegenerateSitemapJob` explicitly (since `update_all` skips the `SitemapSchedulable` callback)

---

## 3. Contact Submission Admin Inbox

### Background

`ContactSubmission` records are saved to the database but there is no admin UI to
view or manage them. Editors have no way to read contact form submissions without
database access.

### Plan

- [x] Create `Admin::ContactSubmissionsController` (index, show, destroy)
- [x] Create admin views — index list with unread badge + preview, show page with full message + reply link
- [x] Add to admin nav with live unread count badge
- [x] Add `read` boolean to `contact_submissions` (migration `20260410000003`), auto-marked on show
- [x] Configure email delivery (covered by item #10 — provider-agnostic SMTP via ENV)
- [x] `ContactMailer#new_submission` sends to editor email address stored in env (covered by item #10)

---

## 4. User Management Admin UI

### Background

Users can only be created/modified via Rails console. There is no UI to invite new
editors or change passwords.

### Plan

- [x] Create `Admin::UsersController` (index, new, create, edit, update, destroy)
- [x] New user form: name, email, role select, password + confirmation
- [x] Edit form: name, email, role — password change section optional (blank = no change)
- [x] Guards: cannot delete own account, cannot change own role
- [x] Index shows linked author profile with edit link
- [x] Restrict to admin-role users only (delivered via RBAC task #7 — `require_admin!` on Users)

---

## 5. Content Security Policy

### Background

`config/initializers/content_security_policy.rb` is fully commented out. CSP is one
of the most effective XSS mitigations available. It is especially important once
third-party ad scripts are injected into pages.

### Plan

- [x] CSP enabled in `config/initializers/content_security_policy.rb`
- [x] `script-src :self` with nonces (importmap compatible via `content_security_policy_nonce_generator`)
- [x] `style-src :unsafe_inline` for Trix editor + inline styles in views
- [x] `frame-ancestors :none` (clickjacking protection)
- [x] AdSense domains documented in comments, ready to uncomment when needed
- [x] Report-only mode available via commented-out line for safe testing

---

## 6. Admin Session Timeout

### Background

Admin sessions never expire. If a logged-in browser is left unattended, the session
remains valid indefinitely.

### Plan

- [x] In `Admin::BaseController#require_login`, check `session[:last_active_at]`
- [x] If more than 4 hours ago, clear session and redirect to login with a notice
- [x] Update `session[:last_active_at]` on every admin request via a `before_action`

---

## 7. RBAC — Editor vs Admin Permissions

### Background

The `User` model has `role: admin/editor` but all authenticated users have identical
admin permissions. Editors should be able to create/edit content but not manage
site structure or delete content.

### Plan

Define two permission tiers:

**Editor:** create articles, edit own articles, manage own author profile
**Admin:** everything including delete, manage categories/tags/locations/users/ads

- [x] `require_admin!` method added to `Admin::BaseController`
- [x] `before_action :require_admin!` applied to: Categories, Locations, StaticPages, Ads, Users
- [x] Editors see: Articles, Authors, Tags, Messages
- [x] Admins see everything
- [x] Admin nav split into editor/admin sections with `current_user.admin?` guard

---

## 8. Full-Text Article Body Search

### Background

Search currently queries only `title` and `dek` (deck). Article body content stored
in Action Text is not included. This misses most article text.

### Plan

- [x] Added `search_vector` tsvector column to articles (migration `20260410000004`)
- [x] PostgreSQL trigger keeps `search_vector` current on title/dek changes
- [x] Body text from Action Text included in vector via HTML-stripped join
- [x] Weighting: title (A) > dek (B) > body (C)
- [x] `Article.search(query)` scope uses `plainto_tsquery` + `ts_rank` ordering
- [x] `SearchController` updated — no extra gem required

---

## 9. Image Variants / Responsive Images

### Background

`image_processing` is in the Gemfile but it is not confirmed that image variants
are being generated and served at appropriate sizes. Without this, full-resolution
upload images are served everywhere.

### Plan

- [x] Named variants on `Article#featured_image`: `:thumb` (400×250), `:medium` (800×500), `:large` (1200×800) — all output WebP
- [x] Named variants on `Author#photo`: `:thumb` (96×96), `:small` (48×48) — WebP
- [x] All image tags updated to use named variants instead of inline resize options
- [x] `loading="lazy"` on all non-above-fold images (article cards, related articles)
- [x] `width`/`height` attributes added to prevent layout shift (CLS)
- [ ] Confirm Active Storage variant storage backend is configured for production (S3/CDN)

---

## 10. Email Delivery Configuration

### Background

There is no SMTP or transactional email provider configured. This blocks contact form
email notifications and any future mailer functionality.

### Plan

- [x] Production SMTP configured via ENV vars in `config/environments/production.rb` — provider-agnostic (Postmark defaults, works with Resend/SendGrid/etc)
- [x] Required ENV vars: `SMTP_HOST`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `FROM_EMAIL`, `EDITOR_EMAIL`, `APP_HOST`
- [x] Development: `:test` delivery (inspect `ActionMailer::Base.deliveries`); add `letter_opener_web` gem for browser inbox
- [x] `ApplicationMailer` from address reads from `FROM_EMAIL` env var
- [x] `ContactMailer#new_submission` — HTML + text templates, `reply-to` set to submitter's email, direct reply link + admin link
- [x] `deliver_later` in `PagesController` — delivery is async via Solid Queue

---

## 11. Password Complexity Enforcement

### Background

`has_secure_password` only enforces minimum length. No complexity requirements exist.

### Plan

- [x] Password validation on `User`: minimum 12 characters, requires uppercase + lowercase + digit
- [x] Validation only fires when `password_digest` changes — no impact on other user updates
- [x] Seed file updated to use `ADMIN_PASSWORD` env var; raises in production if unset; default dev password meets complexity rules

---

## 12. Admin Audit Log

### Background

There is no record of who published, edited, archived, or deleted content. For a
news publication this is important for editorial accountability.

### Plan

- [x] `AuditLog` model with `user_id`, `action`, `resource_type/id/label`, `metadata` (jsonb), `ip_address`
- [x] `after_action :log_mutation` in `Admin::BaseController` — fires on POST/PATCH/PUT/DELETE with successful/redirect responses
- [x] Resource resolved by convention (`controller_name.singularize` → instance variable)
- [x] `/admin/audit_logs` view — admin only, last 200 entries, colour-coded action badges
- [x] Errors in audit logging are rescued and logged — never break the actual request

---

## 13. Tip Submission Form + Inbox

### Background

`/submit-a-tip` exists as a route but appears to be a static page with no functional
form or storage for tips.

### Plan

- [x] Create `TipSubmission` model: `name`, `email`, `tip_body`, `read`, `created_at` (migration `20260410000006`)
- [x] Add tip form to the submit-a-tip static page — name/email optional, tip_body required
- [x] `PagesController#submit_tip` action + POST `/submit-a-tip` route
- [x] `TipMailer#new_tip` — notifies editor on new submission, links to admin inbox
- [x] Create `Admin::TipSubmissionsController` (index, show, destroy) — amber unread badges
- [x] Tips nav link added for all users (editor + admin) with live unread count badge
- [x] Rate limiting in Rack::Attack: 3 tip submissions per IP per minute

---

## 14. Newsletter Subscriber Capture

### Background

There is no email list infrastructure. Even a simple capture form positions the site
for a future newsletter.

### Plan (minimal — capture only, no send)

- [x] Create `NewsletterSubscriber` model: `email` (unique), `confirmed_at`, `unsubscribed_at`, `confirmation_token` (migration `20260410000007`)
- [x] Add signup form to footer — inline email + subscribe button
- [x] `NewsletterMailer#confirmation` — single-click email confirmation with secure token
- [x] `GET /newsletter/confirm?token=…` — confirms and clears token
- [x] `GET /newsletter/unsubscribe?email=…` — unsubscribes
- [x] Admin index at `/admin/newsletter_subscribers` — status badges, CSV export (admin-only)
- [x] Rate limiting: 5 signups per IP per minute
- [ ] Integration with Mailchimp or Resend audience list (optional, later)

---

## 15. Social Sharing Buttons

### Background

OG and Twitter card meta tags are present but article pages have no visible share
controls.

### Plan

- [x] Share bar added to article `show` page — X/Twitter, Facebook, copy-link button
- [x] Plain anchor links (`twitter.com/intent/tweet`, `facebook.com/sharer`) — no third-party JS widgets
- [x] `clipboard_controller.js` Stimulus controller — copies URL, shows "Copied!" feedback for 2s
- [x] Rendered via `shared/_share_buttons` partial, positioned between article body and tags

---

## 16. Two-Factor Authentication for Admin

### Background

Admin sessions are protected by password only. TOTP-based 2FA adds a second layer
that protects against credential theft.

### Plan

- [x] Added `rotp` and `rqrcode` gems
- [x] Migration `20260410000008`: added `totp_secret` and `totp_enabled_at` to `users`
- [x] `User` model: `otp_enabled?`, `generate_totp_secret!`, `enable_totp!`, `verify_otp`, `disable_totp!`, `otpauth_uri`
- [x] Login flow updated: password OK + 2FA enabled → redirect to OTP form, complete login on success
- [x] `Admin::TwoFactorController` — `show` (setup page with QR), `enable`, `disable`
- [x] QR code rendered inline as SVG via `rqrcode` — no external requests
- [x] 2FA nav link in admin header — green when enabled, gray when disabled
- [x] Works with any TOTP app (Google Authenticator, Authy, 1Password, etc.)

---

## 17. Custom Error Pages

### Background

Rails default error pages are shown on 404 and 500 errors. These should match the
site design.

### Plan

- [x] Replaced `public/404.html`, `public/422.html`, `public/500.html` with on-brand designs
- [x] Self-contained inline CSS — Georgia masthead, white background, site colours
- [x] 404 links to homepage + search; 422 and 500 link to homepage

---

## 18. Print Stylesheet

### Background

Article pages have no print styles. Printed or PDF-saved articles will include
navigation, ads, and other UI chrome.

### Plan

- [x] `app/assets/stylesheets/print.css` added — `@media print` block auto-included via `require_tree`
- [x] Hides: header, footer, nav, ads, share buttons, related articles sections
- [x] Shows publication name as page header via `body::before`
- [x] Prints full URLs after article links in prose body

---

## 19. Sitemap Auto-Regeneration

### Background

`sitemap_generator` is configured but the sitemap is not automatically updated when
new articles are published.

### Plan

- [x] `RegenerateSitemapJob` wraps `SitemapGenerator::Interpreter.run` with error logging
- [x] `Article` model triggers `RegenerateSitemapJob.perform_later` via `after_save` when status changes to `published`
- [x] Nightly fallback schedule at 3am in `config/recurring.yml` (catches bulk publishes from scheduler job)

---

## 21. Cloudflare Turnstile on Public-Facing Forms

### Background

Public forms — comments, contact form, tip submissions, newsletter signup — are
currently protected only by Rack::Attack rate limiting. That stops volume floods
but not low-and-slow scripted spam or human-operated form abuse. Cloudflare
Turnstile is a privacy-friendly, no-puzzle alternative to reCAPTCHA that runs
invisibly in most cases.

### Plan

- [x] Site key + secret key are admin-managed Settings (Settings → Security tab)
      — admins can paste them in without a redeploy. Secret key field renders as a password input.
- [x] Per-form toggles in admin Settings: comments, contact, tips, newsletter signup
- [x] `shared/_turnstile_widget` partial renders the Cloudflare widget only when
      the per-form toggle is on AND both keys are configured
- [x] `Turnstile.verify(token, ip)` server-side helper, fail-closed on network/parse errors
- [x] Wired into `CommentsController#create`, `PagesController#submit_contact` /
      `#submit_tip`, `NewsletterSubscriptionsController#create` via
      `turnstile_passed?(form_key)` on `ApplicationController`
- [x] Verification failure re-renders the form with a "Please complete the verification
      challenge" error, does not persist the submission
- [x] In test env, `Turnstile.test_verification_result` lets specs override the
      verification result without HTTP calls
- [x] CSP: `https://challenges.cloudflare.com` allowed in `script-src` and `frame-src`

---

## 22. Admin Nav Overflow — Group into Dropdowns

### Background

The admin top nav lists every section in a single horizontal flex row inside a
`max-w-7xl` container. With editor + admin links combined (Dashboard, Articles,
Authors, Tags, Messages, Comments, Tips, Categories, Locations, Pages, Ads,
Subscribers, Newsletter, Users, Activity Log, Settings, View Site) the row
overflows the viewport and forces horizontal scrolling on common laptop widths.

### Plan

- [x] Grouped into dropdowns driven by a small Stimulus `dropdown` controller
      (click to toggle, click-outside / Escape to close)
- [x] Final groupings:
  - Dashboard, Articles, Tags (top-level)
  - **Inbox ▾** — Messages / Comments / Tips with combined unread badge
  - **People ▾** — Authors, Users (admins only see Users)
  - **Promotion ▾** (admin) — Ads, Newsletter, Subscribers
  - **Site ▾** (admin) — Categories, Locations, Pages, Activity Log, Settings
- [x] "View Site →" on the right next to 2FA / user-avatar dropdown (name + email + Log out)
- [x] `aria-haspopup` / `aria-expanded` set on each trigger; Escape closes
- [x] Mobile: hamburger toggle (uses existing `mobile-menu` Stimulus controller)
      hides desktop nav under `md` and reveals a vertical panel with all
      sections; combined unread badge on the hamburger surfaces inbox activity
      without expanding the menu

---

## Notes

- All new admin sections should follow existing `Admin::BaseController` authentication pattern
- All new models should have corresponding RSpec model specs and factory_bot factories
- Migrations should be reviewed against PostgreSQL-specific features (jsonb, indexes) before running
- CSP changes should be tested in report-only mode before enforcement
- Ad system should be built before CSP is enforced, since ad scripts affect CSP requirements
