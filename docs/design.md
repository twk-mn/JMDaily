# JMDaily Frontend Design Spec

**Scope:** Public-facing site (`/:locale/...`). Admin UI is intentionally separate and follows its own conventions.
**Tech:** Rails 8 views/partials, Tailwind CSS (via `tailwindcss-rails`), Stimulus/Turbo, multi-language via `SiteLanguage` + `ArticleTranslation`.
**Last updated:** 2026-04-24

---

## 1. Design Principles

1. **Clarity over density.** A reader should grasp what the site is within 2–3 seconds.
2. **Visual hierarchy.** One primary story, clear secondary content, everything else recedes.
3. **Trust by default.** Bylines, timestamps, corrections, and sources are visible — not buried.
4. **International-first.** Nothing is hardcoded. Text length, vertical rhythm, and fonts all tolerate English, Japanese, and any language added via the admin Settings → Languages tab.
5. **Accessible by default.** WCAG 2.1 AA is the floor, not a nice-to-have.
6. **Fast.** News is a drive-by medium. LCP budget applies before polish.
7. **Consistency.** Spacing, typography, color, and motion rules are the same on every page.

---

## 2. Layout System

### Containers

| Context | Max width | Rationale |
| --- | --- | --- |
| Top-level nav / footer | `max-w-7xl` | Full-bleed-feeling alignment |
| Homepage & category pages | `max-w-6xl` | Browse-oriented, multi-column |
| Article body (reading column) | `max-w-3xl` | 65–75 char line length |
| Forms (contact, newsletter confirm) | `max-w-md` | Focused input |

All containers use `mx-auto px-4 sm:px-6 lg:px-8`.

### Grid

- Homepage hero row: `grid grid-cols-1 lg:grid-cols-3 gap-6` (hero spans 2, stacked secondaries span 1)
- Card grids: `grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6`
- Article page: single column inside `max-w-3xl`; related articles below widen back to `max-w-6xl`

### Vertical rhythm

- Section spacing between blocks: `mt-10 md:mt-12`
- Within a component: `space-y-4`
- Never rely on ad-hoc margins. If you reach for `mt-7`, stop and pick from the scale.

---

## 3. Typography

### Font stack

```css
/* Latin */
font-family: "Inter", ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;

/* Japanese fallback applied automatically via the same family list */
font-family-jp-append: "Hiragino Sans", "Yu Gothic", "Noto Sans JP", sans-serif;
```

Load Inter via `rails_importmap` / `@font-face` with `font-display: swap`. Japanese characters fall through to the system JP stack — don't ship Noto Sans JP unless we measure a real need (it's 2MB+).

### Scale

| Role | Classes |
| --- | --- |
| Display (article H1) | `text-3xl md:text-4xl lg:text-5xl font-bold tracking-tight` |
| Section heading (H2) | `text-2xl md:text-3xl font-semibold` |
| Card title (H3) | `text-lg md:text-xl font-semibold` |
| Body | `text-base leading-relaxed` |
| Meta (byline, date, category) | `text-sm text-gray-500` |
| Caption / small | `text-xs text-gray-500` |

### Prose

Article body uses Tailwind Typography: `prose prose-lg md:prose-xl prose-gray dark:prose-invert max-w-none`. Override headings color if needed; otherwise trust the plugin.

### Multi-language text rules

- Never constrain to a fixed character count — German and Swedish run 30% longer than English.
- Use `lang` attribute on `<html>` and on any inline snippet in a different language (helps screen readers and hyphenation).
- Use `hyphens-auto` on body copy; don't force-break CJK.

---

## 4. Color System

Single accent: **indigo**. Matches the admin, reads as editorial-but-modern, has good AA contrast at 600/700.

### Light (default)

| Role | Token | Notes |
| --- | --- | --- |
| Background | `bg-white` | |
| Surface (cards) | `bg-white` / `bg-gray-50` | |
| Text primary | `text-gray-900` | |
| Text secondary | `text-gray-600` | Use 600, not 500 — 500 fails AA on white at `text-sm` |
| Text tertiary / meta | `text-gray-500` | Only above `text-base`; switch to 600 at smaller sizes |
| Border | `border-gray-200` | |
| Accent (links, CTAs) | `text-indigo-600 hover:text-indigo-500` | |
| Accent surface | `bg-indigo-600 hover:bg-indigo-500 text-white` | |
| Breaking/Alert | `bg-red-600 text-white` | Reserved for breaking news banner and corrections notices |

### Dark (opt-in, respects `prefers-color-scheme` + manual toggle)

| Role | Token |
| --- | --- |
| Background | `dark:bg-gray-950` |
| Surface | `dark:bg-gray-900` |
| Text primary | `dark:text-gray-100` |
| Text secondary | `dark:text-gray-300` |
| Border | `dark:border-gray-800` |
| Accent | `dark:text-indigo-400 dark:hover:text-indigo-300` |

**Contrast rule:** every text/background pair must meet WCAG AA (4.5:1 for body, 3:1 for large text). If unsure, check with a contrast tool before merging.

---

## 5. Components

### 5.1 Navigation bar

- Sticky: `sticky top-0 z-40 bg-white/90 dark:bg-gray-950/90 backdrop-blur border-b border-gray-200 dark:border-gray-800`
- Height: `h-16`
- Left: Logo (wordmark). Clickable → locale root.
- Center/right: max 5–6 top-level category links (News, Politics, Business, Community, Weather & Travel, Events, Opinion) — truncate to fit, overflow into "More" menu at `md`.
- Far right: search icon, language switcher, dark-mode toggle.
- Mobile: hamburger → full-screen drawer with the same links; `role="dialog" aria-modal="true"`.

**Skip link:** `<a href="#main" class="sr-only focus:not-sr-only ...">Skip to content</a>` as the very first interactive element.

### 5.2 Language switcher

Data source: `SiteLanguage.active` (ordered by `position`).

- Display: `<button>` showing the current flag + `native_name` (e.g. "🇯🇵 日本語").
- 2 languages → inline toggle. 3+ → popover menu.
- Each entry links to the same path in the other locale (use `I18n.locale`-aware URL helpers).
- Preserves the user's choice in the `locale` cookie (already wired in `ApplicationController`).

### 5.3 Breaking news banner

- Position: directly below the nav, full-bleed.
- `bg-red-600 text-white py-2`
- Contains the headline and a dismiss button (persists dismissal per-session).
- Only renders when an article has the `breaking` flag set and was published within the last 24h.
- Screen readers: `role="region" aria-label="Breaking news"`.

### 5.4 Hero article (homepage)

- 16:9 image: `aspect-[16/9] rounded-2xl object-cover` with `loading="eager"` and explicit `width`/`height` to avoid CLS.
- Category chip above the title (links to category).
- Title: `text-2xl md:text-3xl lg:text-4xl font-bold` — no clamp; let it breathe.
- 1–2 line excerpt: `text-base text-gray-600 line-clamp-2`.
- Byline + timestamp below.

### 5.5 Article card

Used in lists, grids, sidebars.

- Wrapper is `<a>` with full-card click target (`group`).
- Image: `aspect-[16/9] rounded-xl object-cover group-hover:opacity-95 transition`.
- Title: `text-lg font-semibold group-hover:text-indigo-600 transition-colors`.
- Optional: excerpt (`line-clamp-2`).
- Meta row: category · date · reading time (`· ` separator).

### 5.6 Section block

- Heading row: `flex items-end justify-between mb-4` with `text-xl md:text-2xl font-semibold` and a "View all →" link.
- Grid below.

### 5.7 Article page

Above the fold:
- Breadcrumbs: `Home / Category / Article` (`aria-label="Breadcrumb"`).
- Category chip.
- H1 (see scale).
- Standfirst / dek: `text-lg md:text-xl text-gray-600 leading-relaxed`.
- Meta row: author (linked) · published date · updated date (if differs) · reading time · location tag.
- Hero image with caption and credit (`text-xs text-gray-500`).

Body:
- `prose` column at `max-w-3xl`.
- Pull quotes: `<blockquote class="border-l-4 border-indigo-600 pl-4 italic my-6">`.
- Inline images: full-prose width with caption.
- Footnotes / source links at bottom of body.

Below the fold:
- **Corrections notice** (see §11): if present, `bg-yellow-50 border-l-4 border-yellow-400 p-4 text-sm` with date and what changed.
- Share row (Twitter/X, Facebook, LinkedIn, copy-link) — all `<button>` elements, no JS trackers.
- Author bio card.
- Related articles (3-up grid).
- Comments (see §5.11).

### 5.8 Search UI

- Inline search bar on the search page: full-width input with submit button.
- Results list: same card style as category pages. No results? See §13 (empty states).
- Preserve the query in the input after submit.
- Uses the existing `search_vector` tsvector backend.

### 5.9 Category / Tag / Author / Location pages

All share the same shell:
- Page header: name, description (if any), count.
- Then a card grid.
- Pagination at the bottom (see §5.12).

### 5.10 Newsletter capture

- Compact card: `bg-gray-50 dark:bg-gray-900 rounded-2xl p-6`.
- Single email input + button, inline on `sm+`, stacked on mobile.
- Success/error states handled via Turbo Stream (no full reload).
- Double opt-in flow already exists — link the confirmation in the success message.

### 5.11 Comments

- Threaded, single-level replies (per the existing `Comment` model).
- Each comment: avatar (or initial monogram), name, posted-at, body.
- "Pending moderation" state shown inline for the user's own comment until approved.
- Comment form: name, email (not shown), body; `required` on all three; email validation client + server side.
- Rate-limit notice if the server rejects.

### 5.12 Pagination

- At the bottom of any list: `Previous | Page X of Y | Next`.
- Hide Previous on page 1, Next on last page.
- Min touch target 44×44px.

### 5.13 Footer

- Three columns on desktop, stacked on mobile.
- Columns: About/Contact, Categories, Legal (Privacy, Terms, Corrections).
- Below columns: logo, copyright, language switcher (secondary placement — helps users who missed it in the nav), RSS feed link.

### 5.14 Ads

Ads exist and pay the bills, but they must never break the reading experience.

**Allowed slots:**
- `homepage_top`: below the hero row, full-width banner, labeled "Advertisement" above.
- `article_mid`: once per article, after roughly 50% of body. Never inside the first 400px.
- `sidebar` (desktop only): optional.

**Rules:**
- Every ad is wrapped in a container with `Advertisement` label (`text-xs uppercase text-gray-500`).
- Fixed aspect ratio — reserve space before the creative loads to avoid CLS.
- No auto-play video, no interstitials, no before-headline placement.
- Served via the existing `Ad` model with click tracking (`ads/:id/click`).

---

## 6. Homepage Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Nav (sticky)                                                │
├──────────────────────────────────────────────────────────────┤
│  (Breaking news banner, conditional)                         │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Hero (2/3)                           Stacked secondaries    │
│  ─────────────                        (3 cards, 1/3 col)     │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  [Ad: homepage_top]                                          │
├──────────────────────────────────────────────────────────────┤
│  Local News — grid 2–3 cols                                  │
├──────────────────────────────────────────────────────────────┤
│  Japan / Regional — grid                                     │
├──────────────────────────────────────────────────────────────┤
│  Weekly Recap — editorial block                              │
├──────────────────────────────────────────────────────────────┤
│  Opinion / Feature — 2-col editorial                         │
├──────────────────────────────────────────────────────────────┤
│  Newsletter capture card                                     │
├──────────────────────────────────────────────────────────────┤
│  Footer                                                      │
└──────────────────────────────────────────────────────────────┘
```

Each section title is a link to the full archive. Section order is editorially flexible — implement as a list of section partials driven by a homepage config so we can reorder without code changes later.

---

## 7. Accessibility (WCAG 2.1 AA)

Non-negotiable baseline:

- **Landmarks:** one `<header>`, `<nav>`, `<main id="main">`, `<footer>` per page.
- **Headings:** one H1 per page. Never skip levels.
- **Skip link:** first focusable element.
- **Focus ring:** `focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600`. Never remove without replacing.
- **Touch targets:** min 44×44px (Apple HIG), or 24×24px with `padding` making the hit area 44×44 (Safari 17+).
- **Images:** every `<img>` has `alt`. Decorative images use `alt=""`. Article hero images use the caption as context, alt as description of the image itself.
- **Color is never the only cue.** Status badges pair color with a label or icon.
- **Keyboard:** full site navigable without a mouse, including the language switcher, mobile menu, and comment form.
- **Motion:** respect `prefers-reduced-motion`. Disable non-essential transitions (`@media (prefers-reduced-motion: reduce)`).
- **Forms:** every input has a `<label>`. Errors announced via `aria-live="polite"` on the error summary.
- **Lang attribute:** `<html lang="<%= I18n.locale %>">` on every page.

Audit cadence: run axe-core against homepage, article, and category pages before any design-touching PR merges. Add it to CI once the pattern is stable.

---

## 8. SEO & Structured Data

A news site lives and dies by discoverability. Every article page emits:

### 8.1 Meta tags

```erb
<title><%= @article.title %> — Joetsu-Myoko Daily</title>
<meta name="description" content="<%= @article.excerpt.truncate(160) %>">
<link rel="canonical" href="<%= article_url(@article, locale: I18n.locale) %>">
```

### 8.2 hreflang (language alternates)

For each active locale that has a translation:

```erb
<% SiteLanguage.active_codes.each do |code| %>
  <% if @article.translation_for(code) %>
    <link rel="alternate" hreflang="<%= code %>" href="<%= article_url(@article, locale: code) %>">
  <% end %>
<% end %>
<link rel="alternate" hreflang="x-default" href="<%= article_url(@article, locale: "en") %>">
```

### 8.3 OpenGraph & Twitter

```erb
<meta property="og:type" content="article">
<meta property="og:title" content="<%= @article.title %>">
<meta property="og:description" content="<%= @article.excerpt %>">
<meta property="og:image" content="<%= @article.hero_image_url %>">
<meta property="og:url" content="<%= article_url(@article) %>">
<meta property="og:site_name" content="Joetsu-Myoko Daily">
<meta property="og:locale" content="<%= I18n.locale %>">
<meta property="article:published_time" content="<%= @article.published_at.iso8601 %>">
<meta property="article:modified_time" content="<%= @article.updated_at.iso8601 %>">
<meta property="article:author" content="<%= @article.author.name %>">
<meta property="article:section" content="<%= @article.category.name %>">
<% @article.tags.each do |tag| %>
  <meta property="article:tag" content="<%= tag.name %>">
<% end %>

<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="<%= @article.title %>">
<meta name="twitter:description" content="<%= @article.excerpt %>">
<meta name="twitter:image" content="<%= @article.hero_image_url %>">
```

### 8.4 JSON-LD

Emit a `NewsArticle` schema on article pages:

```json
{
  "@context": "https://schema.org",
  "@type": "NewsArticle",
  "headline": "...",
  "datePublished": "ISO8601",
  "dateModified": "ISO8601",
  "author": {"@type": "Person", "name": "...", "url": "..."},
  "publisher": {
    "@type": "Organization",
    "name": "Joetsu-Myoko Daily",
    "logo": {"@type": "ImageObject", "url": "..."}
  },
  "image": ["..."],
  "articleSection": "News",
  "inLanguage": "en",
  "mainEntityOfPage": "..."
}
```

Homepage emits `WebSite` with `SearchAction` so Google shows the sitelinks search box.

### 8.5 Sitemap & RSS

- `config/sitemap.rb` already wired — ensure every translated article emits entries for every active locale with proper `xhtml:link` hreflang tags. Ping Google after deploy.
- RSS feed at `/feed` (already exists). Add `/feed?locale=ja` hinting in `<link rel="alternate" type="application/rss+xml">` on every page.

### 8.6 Google News / IndexNow

- Register the site in Google News Publisher Center and Bing Webmaster Tools.
- Optional: IndexNow ping on publish for faster Bing/Yandex pickup.

### 8.7 Robots

- `robots.txt` allows everything, points at the sitemap.
- Admin routes have `<meta name="robots" content="noindex, nofollow">` (already in layout).
- Drafts and previews also emit `noindex`.

---

## 9. Performance

Budgets (measured on 4G Moto G4 emulation, Lighthouse):

| Metric | Target |
| --- | --- |
| LCP | < 2.5s |
| CLS | < 0.1 |
| INP | < 200ms |
| Total page weight (homepage) | < 500KB (excl. ads) |
| JS bundle (first load) | < 80KB gzipped |

### Images

- Use `image_tag` with `loading="lazy"` on everything below the fold; hero is `loading="eager" fetchpriority="high"`.
- Always set `width` and `height` (prevents CLS).
- Serve responsive srcsets — wire up `image_processing` / variant sizes for common widths (640, 960, 1280, 1920).
- Prefer WebP with JPEG fallback.

### Fonts

- `font-display: swap` everywhere.
- Preload only Inter 400 + 700 (the two weights we actually render above the fold).

### JS

- Stimulus + Turbo only. No framework bloat.
- Defer any third-party script that isn't critical (analytics, share widgets).
- No client-side routing.

### Caching

- Public pages: HTTP cache `Cache-Control: public, max-age=60, stale-while-revalidate=600` — fresh enough for news, cheap enough for CDN.
- Fingerprinted assets get `immutable, max-age=31536000`.

---

## 10. Interaction & Motion

- Default transition: `transition duration-200 ease-in-out`.
- Hover on cards: subtle image opacity change, title color shift. No scale > 1.02.
- Focus: always visible (see §7).
- Dark mode toggle animates the root via `colorScheme` change only — don't animate every surface color.
- **Respect `prefers-reduced-motion: reduce`.** Wrap non-essential animations in the media query.

---

## 11. Corrections & Transparency

Trust features aren't optional on a news site.

- **Corrections notice** on any article where `corrections.any?`:
  - `bg-yellow-50 border-l-4 border-yellow-400 p-4 my-6 text-sm`
  - "Correction — <date>: <what changed>"
- **Updated timestamp** in the byline if `updated_at > published_at + 1.hour`.
- **Corrections policy** linked from footer and from each corrections block.
- **Tip submission** link prominent in the footer.

---

## 12. Empty States & Errors

| State | Treatment |
| --- | --- |
| Category with no articles | Icon + "No stories here yet — check back soon." + link to homepage |
| Search no results | "No results for "query". Try a different term." + popular categories |
| Comments disabled on article | Plain text note, no form |
| 404 | Custom page: "Lost? Here's the homepage. Or search: [input]." |
| 500 | Static friendly page served by Rails public/500.html |
| Network / Turbo error | Flash with `role="alert"`, retry link |

All empty states use `text-center py-12 text-gray-500` as the baseline.

---

## 13. Dark Mode

- Default: `prefers-color-scheme` on first visit.
- Manual toggle in nav persists via `localStorage` (`theme: "light" | "dark" | "system"`).
- Set `<html class="dark">` via a tiny inline script in `<head>` **before** first paint to avoid flash of wrong theme.
- Test every component in both modes before shipping.

---

## 14. Anti-Patterns

- Autoplay video or audio.
- Interstitials, scroll-jacking modals, newsletter popups on first load.
- Cookie banners that block the page (use a discreet bottom bar if needed).
- More than 7 items in the top nav.
- Removing focus rings.
- Hardcoded English labels.
- Fixed-width buttons that clip translated text.
- Meta / decorative text colored `text-gray-400` or lighter on white — fails AA.
- Relying on hover to reveal important actions (mobile has no hover).

---

## 15. Implementation Strategy

Build order when touching the design:

1. Container, typography, and color tokens — lock these first.
2. Navigation + language switcher + footer (shell).
3. Article card component (used everywhere).
4. Article page (the core unit of the site).
5. Homepage sections.
6. Category / tag / author / location index pages.
7. Search, newsletter, comments.
8. Ads, breaking banner, corrections.
9. Dark mode pass.
10. A11y audit + SEO audit + Lighthouse pass before merging a design-touching PR.

---

## 16. Quality Gate (Pre-Merge Checklist)

For any PR that touches public-facing views:

- [ ] Renders correctly in light and dark mode
- [ ] Keyboard-navigable end to end (including any new interactive element)
- [ ] axe-core reports zero critical/serious issues on the changed pages
- [ ] Lighthouse Performance ≥ 90, Accessibility ≥ 95, SEO = 100 on the changed pages
- [ ] hreflang + OG + JSON-LD emitted where applicable
- [ ] No hardcoded user-facing strings (all via I18n)
- [ ] Images have dimensions and alt text
- [ ] Works on 375px viewport without horizontal scroll
- [ ] Respects `prefers-reduced-motion`
- [ ] CLS stays below 0.1 with slow-3G emulation

---

## 17. Final Gut-Check

Before shipping:

1. Can a first-time visitor tell what this site is in 3 seconds?
2. Is the main story unmistakable?
3. Does the page feel calm, not chaotic?
4. Would a screen-reader user reach the main story in one or two tabs?
5. Does it look right in Japanese?

If any answer is no, fix it before merge.

---

*End of spec.*
