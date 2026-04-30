# JMDaily — TODO

Working list of bugs, features, and polish items for the next several PRs.
Larger backlog and design notes live in [docs/improvements.md](docs/improvements.md).

Last updated: 2026-04-30.

---

## Critical bugs

These were reported live on the running site. Fix order generally matches risk: the R2 fix landed in #78 and may also resolve some downstream symptoms, so re-test before assuming the rest are still broken.

- [x] **R2 `InvalidRequest` on article publish** — `aws-sdk-s3` was sending checksum headers R2 doesn't support. Fixed in #78.
- [ ] **Published articles return 404 on the public site** — likely a translation-slug lookup or locale routing mismatch in `ArticlesController#show`.
- [ ] **Cannot edit articles in admin dashboard** — admin edit action fails. May be related to the S3 error above; re-test after #78 deploys.
- [ ] **Settings don't persist** — site name, tagline, and other values revert after save. Investigate the `Setting` model read/write path and any env-var overrides clobbering DB values.
- [ ] **Cloudflare Turnstile API key has no effect** — likely the same root cause as the general settings bug; verify after that fix lands. (Improvements #21.)

---

## Features

- [ ] **DB-backed UI string translations** — menus, site name, tagline, category names, tag labels, and other chrome strings need to follow whatever locales are added via `SiteLanguage` admin. English fallback when no translation exists yet. Decision still pending: gem (`I18n::Backend::ActiveRecord`) vs. custom `t_ui` helper. See [memory/project_ui_i18n.md](.claude/projects/-Users-fred-Documents-Work-JMDaily/memory/project_ui_i18n.md).
- [ ] **Slug uniqueness + short URL** — add a date or short ID into article slugs so two articles with the same headline don't collide. Also expose a short canonical alias (e.g. `/article/123456789`) that resolves to the full URL.
- [ ] **Language-targeted ads** — add a `locale` filter to the ad model so an ad can be shown only when the visitor is reading in a specific language. Update `Ad.pick_for_zone` and the admin form.
- [ ] **Local seed data covering the full site** — articles in multiple languages, authors with social links and photos, categories, tags, locations, corrections, comments, ads. Goal: clone the repo, run `db:seed`, and have a fully exercisable site without poking around in the admin.

---

## Polish backlog

Tight-scope items continuing the silent-drop / SEO theme from #72–#78.

- [ ] **Author show page OG meta + Person JSON-LD** — surfaces the new social URLs from #77 to crawlers via `Person.sameAs`. Author pages currently set only `<title>`.
- [ ] **JSON-LD on category / tag / location index pages** — `CollectionPage`/`ItemList` schemas. Parallel to #75/#76 but for list pages.
- [ ] **OG meta on tag / location / static pages** — currently no `og_image` or `meta_description`. Pull from the lead article (or page body for static).
- [ ] **Image `loading="lazy"` audit** — author bio photo, article-show author photo, and a few other below-fold images miss the attribute.

---

## From [docs/improvements.md](docs/improvements.md) — still open

The bulk of that document has shipped (see grep against `app/models` + `app/jobs`). Items confirmed still pending:

- [ ] **#18 Print stylesheet for articles** — only `print:hidden` on the preview banner today; nothing for the article body itself.
- [ ] **#21 Cloudflare Turnstile on public-facing forms** — partially done; tracked above as a critical bug pending verification.

If anything in `improvements.md` looks unaddressed when revisiting, re-verify against the current `app/` tree before adding to this list — most of it is already shipped (Ad system, scheduling job, Contact/Tip inboxes, RBAC, full-text search, audit log, sitemap regen, password complexity, 2FA, custom 404/500, admin nav dropdowns, etc.).
