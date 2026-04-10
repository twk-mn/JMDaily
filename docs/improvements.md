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

---

## Immediate Action

### [ ] Rotate default seed credentials

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
- [ ] Configure CSP to allow ad network scripts
- [ ] Write specs for Ad model and click tracking

---

## 2. Article Scheduling (Background Job)

### Background

Articles can be set to `scheduled` status with a `published_at` date/time, but there
is no mechanism to automatically publish them. This currently means "scheduled" is
effectively the same as "draft."

### Plan

- [ ] Add `Solid Queue` (or confirm existing job backend) to `Gemfile`
- [ ] Create `PublishScheduledArticlesJob` — queries `where(status: "scheduled").where("published_at <= ?", Time.current)`, updates each to `published`
- [ ] Schedule job to run every 5 minutes via `config/recurring.yml` (Rails 8 built-in with Solid Queue)
- [ ] Regenerate sitemap after bulk publish

---

## 3. Contact Submission Admin Inbox

### Background

`ContactSubmission` records are saved to the database but there is no admin UI to
view or manage them. Editors have no way to read contact form submissions without
database access.

### Plan

- [ ] Create `Admin::ContactSubmissionsController` (index, show, destroy)
- [ ] Create admin views — index list with preview, show page with full message
- [ ] Add to admin sidebar nav
- [ ] Add `read` boolean to `contact_submissions` (migration) for tracking read state
- [ ] Configure email delivery (Postmark or Resend) so new submissions also notify via email
- [ ] Add mailer: `ContactMailer#new_submission` sends to editor email address stored in env

---

## 4. User Management Admin UI

### Background

Users can only be created/modified via Rails console. There is no UI to invite new
editors or change passwords.

### Plan

- [ ] Create `Admin::UsersController` (index, new, create, edit, update, destroy)
- [ ] Require `admin` role to access (see RBAC section)
- [ ] New user form: name, email, role (admin/editor), temporary password or invite flow
- [ ] Edit form: name, email, role — separate password change form
- [ ] Add to admin sidebar, visible only to admin-role users

---

## 5. Content Security Policy

### Background

`config/initializers/content_security_policy.rb` is fully commented out. CSP is one
of the most effective XSS mitigations available. It is especially important once
third-party ad scripts are injected into pages.

### Plan

- [ ] Define a baseline CSP in the initializer:
  - `default-src 'self'`
  - `img-src 'self' data: blob: *.active_storage`
  - `script-src 'self' 'nonce-...'`
  - `style-src 'self' 'nonce-...'`
  - `font-src 'self'`
- [ ] Update once ad network domains are known (AdSense, etc.)
- [ ] Test in report-only mode first: `Content-Security-Policy-Report-Only`
- [ ] Enable enforcement after confirming no breakage

---

## 6. Admin Session Timeout

### Background

Admin sessions never expire. If a logged-in browser is left unattended, the session
remains valid indefinitely.

### Plan

- [ ] In `Admin::BaseController#require_login`, check `session[:last_active_at]`
- [ ] If more than 4 hours ago, clear session and redirect to login with a notice
- [ ] Update `session[:last_active_at]` on every admin request via a `before_action`

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

- [ ] Add `require_admin!` method to `Admin::BaseController`
- [ ] Apply `before_action :require_admin!` to:
  - Destroy actions across all controllers
  - `Admin::CategoriesController` (full)
  - `Admin::LocationsController` (full)
  - `Admin::TagsController` (full)
  - `Admin::UsersController` (full)
  - `Admin::AdsController` (full)
- [ ] Hide restricted nav items from editor-role users in admin layout

---

## 8. Full-Text Article Body Search

### Background

Search currently queries only `title` and `dek` (deck). Article body content stored
in Action Text is not included. This misses most article text.

### Plan

- [ ] Add `pg_search` gem (PostgreSQL full-text search)
- [ ] Configure `PgSearch::Multisearch` on `Article` for `title`, `dek`, and Action Text body
- [ ] Or: use raw `tsvector` column updated via DB trigger (faster, no extra gem)
- [ ] Update `SearchController#index` to use new search scope
- [ ] Add weighting: title matches rank higher than body matches

---

## 9. Image Variants / Responsive Images

### Background

`image_processing` is in the Gemfile but it is not confirmed that image variants
are being generated and served at appropriate sizes. Without this, full-resolution
upload images are served everywhere.

### Plan

- [ ] Define named variants on `Article` (featured image): `:thumb` (400×250), `:medium` (800×500), `:large` (1200×750)
- [ ] Update article card partials to use `variant(:thumb)` and `variant(:medium)` appropriately
- [ ] Update article show page to use `variant(:large)`
- [ ] Define `:thumb` variant on `Author` photo
- [ ] Add `loading="lazy"` attributes to all non-above-fold images
- [ ] Confirm Active Storage variant storage backend is configured for production

---

## 10. Email Delivery Configuration

### Background

There is no SMTP or transactional email provider configured. This blocks contact form
email notifications and any future mailer functionality.

### Plan

- [ ] Choose provider: **Postmark** (spec recommendation) or **Resend**
- [ ] Add provider gem to Gemfile
- [ ] Configure `config/environments/production.rb` with SMTP or API settings via ENV vars
- [ ] Create `ContactMailer#new_submission` to notify on contact form submissions
- [ ] Add a `FROM_EMAIL` and `EDITOR_EMAIL` env var to application config docs

---

## 11. Password Complexity Enforcement

### Background

`has_secure_password` only enforces minimum length. No complexity requirements exist.

### Plan

- [ ] Add format validation to `User` model on `password`:
  - Minimum 12 characters
  - At least one uppercase, one lowercase, one digit
- [ ] Or add `strong_password` gem for configurable complexity rules
- [ ] Ensure validation only applies when password is being set (not on every user update)

---

## 12. Admin Audit Log

### Background

There is no record of who published, edited, archived, or deleted content. For a
news publication this is important for editorial accountability.

### Plan

- [ ] Create `AuditLog` model: `user_id`, `action` (string), `resource_type`, `resource_id`, `resource_label`, `metadata` (jsonb), `created_at`
- [ ] Add `after_action` callback in `Admin::BaseController` to log create/update/destroy actions
- [ ] Create `/admin/audit_log` index view — admin only, read-only, paginated
- [ ] Retain for 90 days (add cleanup job)

---

## 13. Tip Submission Form + Inbox

### Background

`/submit-a-tip` exists as a route but appears to be a static page with no functional
form or storage for tips.

### Plan

- [ ] Create `TipSubmission` model: `name`, `email`, `tip_body`, `read`, `created_at`
- [ ] Add tip form to the static page (or replace with a dedicated template)
- [ ] Create `Admin::TipSubmissionsController` (index, show, destroy)
- [ ] Add rate limiting in Rack::Attack (already in place for contact form — mirror it)
- [ ] Send email notification on new tip (reuse ContactMailer pattern)

---

## 14. Newsletter Subscriber Capture

### Background

There is no email list infrastructure. Even a simple capture form positions the site
for a future newsletter.

### Plan (minimal — capture only, no send)

- [ ] Create `NewsletterSubscriber` model: `email` (unique), `confirmed_at`, `unsubscribed_at`, `created_at`
- [ ] Add signup form to homepage sidebar or footer
- [ ] Confirm email via single-click confirmation mailer
- [ ] Admin index at `/admin/newsletter_subscribers` — export to CSV
- [ ] Integration with Mailchimp or Resend audience list (optional, later)

---

## 15. Social Sharing Buttons

### Background

OG and Twitter card meta tags are present but article pages have no visible share
controls.

### Plan

- [ ] Add minimal share links to article `show` page: X/Twitter, Facebook, copy-link button
- [ ] Use plain anchor links (`https://twitter.com/intent/tweet?url=...`) — no third-party
  JS widget to avoid tracking and CSP complications
- [ ] Stimulus controller for copy-to-clipboard behavior on the link button

---

## 17. Custom Error Pages

### Background

Rails default error pages are shown on 404 and 500 errors. These should match the
site design.

### Plan

- [ ] Create `public/404.html` and `public/500.html` with styled, on-brand content
- [ ] Or: use dynamic error pages via `config.exceptions_app = routes` for full layout support
- [ ] Ensure 404 page links back to homepage and search

---

## 18. Print Stylesheet

### Background

Article pages have no print styles. Printed or PDF-saved articles will include
navigation, ads, and other UI chrome.

### Plan

- [ ] Add `@media print` styles to `application.css`:
  - Hide: header, footer, nav, ads, sidebar, share buttons, related articles
  - Show: article title, byline, body, publication name, URL

---

## 19. Sitemap Auto-Regeneration

### Background

`sitemap_generator` is configured but the sitemap is not automatically updated when
new articles are published.

### Plan

- [ ] Add `SitemapRegenerateJob` that calls `SitemapGenerator::Sitemap.create`
- [ ] Trigger from `Article` model `after_save` when status changes to `published`
- [ ] Or: run on a nightly schedule via `config/recurring.yml`

---

## Notes

- All new admin sections should follow existing `Admin::BaseController` authentication pattern
- All new models should have corresponding RSpec model specs and factory_bot factories
- Migrations should be reviewed against PostgreSQL-specific features (jsonb, indexes) before running
- CSP changes should be tested in report-only mode before enforcement
- Ad system should be built before CSP is enforced, since ad scripts affect CSP requirements
