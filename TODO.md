# JMDaily — TODO

Working list of bugs, features, and polish items for the next several PRs.
Larger backlog and design notes live in [docs/improvements.md](docs/improvements.md).

Last updated: 2026-05-03.

---

## Critical bugs

- [x] **R2 `InvalidRequest` on article publish** — `aws-sdk-s3` sent checksum headers R2 doesn't support. Fixed in #78.
- [x] **Published articles return 404 on the public site** — article-level slug drifted from per-locale translation slug; tag/location/author index pages didn't preload `:translations` so `to_param` fell back to the article slug, which `ArticlesController#show` couldn't resolve. Fixed in #80 by preloading translations and adding a 301 fallback for stale article-slug URLs.
- [x] **Settings don't persist** — `Setting.get` cached reads via `Rails.cache` keyed on a per-process cache version. The default cache store is per-process, so writes in one Puma worker left other workers serving stale values until the TTL expired. Cache layer dropped in #80; same fix applied to `SiteLanguage`.
- [x] **Cloudflare Turnstile API key has no effect** — same root cause as the settings persistence bug, fixed by #80.
- [x] **Admin Edit returns 404 on Locations, Categories, Tags, Articles, Authors, Static Pages** — every model with a slug overrode `to_param`, so admin edit URLs carried a slug, but every `set_*` callback still did `Model.find(params[:id])`. Fixed in #91 with a shared `find_resource` helper that accepts either an integer id or a slug; the article controller also resolves through `ArticleTranslation.slug` since `Article#to_param` returns the locale-current translation slug when translations are eager-loaded.

---

## Features

### In flight / open

- [ ] **Translatable taxonomies and chrome (Locations, Categories, Tags, Authors, Static Pages, menus, site name, tagline)** — every user-facing label tied to a record needs a per-locale variant that follows whatever languages are active in `SiteLanguage`, with English as the fallback when a translation is missing. Two-part design conversation pending:
  - **Model attributes** (Location#name, Category#description, Tag#name, Author#bio, StaticPage#title/body, etc.): introduce a translations table per model (similar to `ArticleTranslation`), or use a JSONB `translations` column, or pull in a gem like `mobility` / `globalize`. The `ArticleTranslation` shape is the closest precedent in this repo and could generalize.
  - **UI chrome strings** (menu labels, button text, footer copy): pick between `I18n::Backend::ActiveRecord` (gem-driven, integrates with the `t()` helper) vs. a custom `t_ui` helper backed by a `UiString` model. See [memory/project_ui_i18n.md](.claude/projects/-Users-fred-Documents-Work-JMDaily/memory/project_ui_i18n.md).

  Need a design call before implementing — both halves benefit from the same decision. Add a corresponding admin form column for every active language (with the English value as the placeholder/fallback).

- [ ] **WordPress-style settings, actually wired into the site** — current settings are minimal (site name, tagline, admin email, timezone, Turnstile keys, newsletter provider) and several aren't even read by the layout (e.g. `og:site_name` is hardcoded, the masthead text is hardcoded). Two threads here:
  1. **Surface what we save** — wire `site_name`, `tagline`, `admin_email`, `timezone` into the layout / mailers / `og:site_name` so editing them in admin actually shows up on the public site.
  2. **Expand the catalog** — bring the settings tabs closer to a CMS like WordPress: General (site title, tagline, default timezone, language order), Reading (posts-per-page, default homepage layout, RSS items count), Writing (default category, default article type, default author), Comments (moderation policy, holding for first-time commenters, blocked words list — separate from the per-form Turnstile toggle that already exists), Media (image variant sizes), Permalinks (article URL pattern, category URL pattern), Privacy (analytics opt-in, cookie banner copy). Each new key needs a `DEFINITIONS` entry, a form widget, and an actual reader in the relevant view/service.

  Likely splits into multiple PRs — a "wire existing settings into the layout" PR first (highest leverage, no new schema), then per-tab feature PRs.

### Shipped

- [x] **Slug uniqueness + short URL** — articles with colliding headlines now auto-suffix `-YYYY-MM-DD-N`; `/article/:id` 301s to the canonical translation URL. Shipped in #86.
- [x] **Language-targeted ads** — `Ad.target_locale` filters which language sees an ad, with admin form selector. Shipped in #89.
- [x] **Local seed data covering the full site** — `db:seed` now populates 4 authors with social links, 7 EN+JA articles across categories, a correction, mixed-status comments, and locale-targeted ads in development/test. Shipped in #90.

---

## Polish backlog (all shipped)

Tight-scope items continuing the silent-drop / SEO theme from #72–#78.

- [x] **Author show page OG meta + Person JSON-LD** — #82.
- [x] **JSON-LD on category / tag / location index pages** — `CollectionPage` + `ItemList`. #83.
- [x] **OG meta on tag / location / static pages** — #84.
- [x] **Image `loading="lazy"` audit** — #85.

---

## From [docs/improvements.md](docs/improvements.md) — still open

- [x] **#18 Print stylesheet for articles** — proper opt-out via `data-print-hide`, fixing a CSS bug where the prior `content: none` rule didn't actually hide chrome. #87.
- [x] **#21 Cloudflare Turnstile on public-facing forms** — settings cache fix landed in #80; verified live.

If anything in `improvements.md` looks unaddressed when revisiting, re-verify against the current `app/` tree before adding to this list — most of it is already shipped (Ad system, scheduling job, Contact/Tip inboxes, RBAC, full-text search, audit log, sitemap regen, password complexity, 2FA, custom 404/500, admin nav dropdowns, etc.).
