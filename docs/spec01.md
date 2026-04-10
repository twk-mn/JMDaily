# Joetsu-Myoko Daily — Product Spec v1

## 1. Product Summary

**Joetsu-Myoko Daily** is an English-language local news site focused primarily on **Joetsu** and **Myoko**, with occasional coverage of **Itoigawa** and nearby areas when relevant.

The site should feel like a **real local news publication**, not a blog, tourism page, or expat diary.

The initial version should prioritize:

* fast publishing
* high trust and readability
* strong SEO foundations
* low editorial friction
* room to expand later into a more complete local media product

---

## 2. Core Goal

Launch a credible local news site that can:

* publish news quickly and cleanly
* rank in search for local English-language queries
* become a trusted source for Joetsu/Myoko news in English
* serve as a “finished thing” that can later be expanded into a stronger media property

---

## 3. Editorial Positioning

### Primary coverage area

* Joetsu
* Myoko

### Secondary / occasional coverage

* Itoigawa
* wider regional stories relevant to residents, visitors, investors, and foreign readers

### Core content types

* local news
* politics / city decisions
* infrastructure / transport
* weather disruptions / snowfall / road closures
* tourism and seasonal events
* business openings / closures
* community stories
* schools / local initiatives
* occasional analysis / explainers

### Tone

* professional
* neutral
* clear English
* locally informed
* concise rather than dramatic

Not tabloid. Not booster propaganda. Not “Top 10 cafes you must visit before you die.”

---

## 4. Target Audience

### Primary audience

* English-speaking residents in Joetsu / Myoko
* foreign residents in the wider region
* long-term visitors and families
* internationally minded Japanese readers comfortable with English

### Secondary audience

* tourists researching the area
* former residents
* investors / business people monitoring local developments
* people considering moving to the region

---

## 5. Product Principles

1. **Credibility first**

   * clean layout
   * proper bylines
   * dates and updates shown clearly
   * no spammy ad clutter

2. **Fast to publish**

   * publishing a basic article should be frictionless
   * admin should not feel like wrestling a CMS from 2009

3. **SEO from the start**

   * article schema
   * clean URLs
   * metadata and OG tags
   * category and location pages

4. **Scalable structure**

   * launch simple, but with a content model that supports future growth

5. **Mobile-first**

   * a large portion of local/news traffic will be mobile

---

## 6. MVP Scope

### Must-have v1 features

#### Public site

* homepage
* article detail pages
* category pages
* tag pages
* location pages (Joetsu, Myoko, Itoigawa)
* article search
* about page
* contact page
* simple tips / submissions page
* privacy policy
* terms

#### Editorial/admin

* secure admin login
* create / edit / schedule / publish articles
* drafts
* featured image upload
* article preview
* category and tag assignment
* location assignment
* SEO title / meta description fields
* author management
* status fields (draft, scheduled, published)

#### SEO / technical

* sitemap.xml
* robots.txt
* RSS feed
* Open Graph / Twitter card tags
* canonical URLs
* JSON-LD schema for articles
* clean slug URLs

#### Trust / publication signals

* bylines
* published at + updated at
* editorial contact
* basic corrections policy page

---

## 7. Explicit Non-Goals for v1

Do **not** overbuild early.

Skip these for v1 unless they are nearly free:

* comments
* forums
* native subscriptions/paywall
* multilingual publishing workflow
* user accounts for readers
* newsletter platform built in-house
* ad network management system
* mobile app
* real-time dashboards
* complex newsroom permissions
* AI summarization everywhere just because AI exists

These are expansion items, not launch blockers.

---

## 8. Site Architecture

### Main navigation

* Home
* News
* Politics
* Business
* Community
* Weather / Travel
* Events
* Opinion / Analysis (optional, later if needed)
* About

### Homepage sections

* lead story
* latest news
* Joetsu section
* Myoko section
* weather / travel disruption strip
* events highlights
* featured analysis / explainer
* newsletter signup block (if used)

### Footer

* About
* Contact
* Tip submission
* Privacy Policy
* Terms
* Corrections Policy
* RSS
* Social links

---

## 9. Content Model

### Article

Fields:

* title
* slug
* dek / short summary
* body (rich text)
* status
* published_at
* updated_at
* featured_image
* featured_image_caption
* seo_title
* meta_description
* canonical_url (optional)
* source_notes (private/admin only)
* article_type
* visibility
* author
* primary_category
* tags
* locations
* featured boolean
* breaking / urgent boolean

### Author

Fields:

* name
* slug
* bio
* photo
* role/title
* social links

### Category

Examples:

* News
* Politics
* Business
* Community
* Weather & Travel
* Events
* Opinion

### Tag

Examples:

* snowfall
* city council
* shinkansen
* road closures
* tourism
* schools

### Location

Examples:

* Joetsu
* Myoko
* Itoigawa

### Static page

* About
* Contact
* Submit a tip
* Corrections Policy
* Privacy Policy
* Terms

---

## 10. Editorial Workflow

### Simple v1 workflow

1. Create article draft
2. Add title, dek, body, image
3. Assign category, tags, and location
4. Add SEO fields
5. Preview
6. Publish or schedule

### Suggested article statuses

* draft
* scheduled
* published
* archived

### Future optional statuses

* under_review
* needs_update
* corrected

---

## 11. Design Direction

### Brand feel

* calm
* trustworthy
* newspaper-like but modern
* simple typography
* strong spacing
* not cluttered

### Visual priorities

* strong masthead
* clear hierarchy
* readable body text
* visible timestamps
* restrained use of accent color
* fast loading

### Avoid

* overly startup-y SaaS look
* giant rounded cards everywhere
* tourism brochure visuals
* dark patterns
* excessive motion

---

## 12. Tech Stack Recommendation

Because the goal is to actually build something, expand it later, and keep control:

### App stack

* **Ruby on Rails**
* PostgreSQL
* Hotwire (Turbo + Stimulus)
* Tailwind CSS
* Active Storage for uploads
* background jobs via Solid Queue / Sidekiq depending on deployment choice

### CMS/editor approach

Use a **custom admin** inside Rails rather than bolting on a giant headless CMS for v1.

Rich text options:

* Action Text for speed
* or Tiptap later if you want more newsroom-like editing

### Search

* PostgreSQL full-text search for v1
* optional Meilisearch later if needed

### Deployment

Reasonable options:

* Render
* Hatchbox + VPS
* Kamal on a VPS later if you want tighter control

For speed and low hassle, **Render or Hatchbox** are sensible.

### Email

* Postmark or Resend for contact forms / editorial emails

### Analytics

* Plausible or Umami

### Image/CDN

* Cloudflare in front of the app
* optionally S3-compatible object storage later if media grows

---

## 13. URL Structure

Keep URLs boring and clean.

### Suggested patterns

* `/`
* `/news`
* `/politics`
* `/business`
* `/community`
* `/weather-travel`
* `/events`
* `/locations/joetsu`
* `/locations/myoko`
* `/locations/itoigawa`
* `/articles/:slug`
* `/authors/:slug`
* `/tags/:slug`
* `/about`
* `/contact`
* `/submit-a-tip`

Optional later:

* date-based archive URLs
* `/breaking`
* `/newsletter`

---

## 14. Homepage Content Logic

### Lead story

* latest featured article

### Latest news list

* reverse chronological, excluding already featured lead

### Local sections

* latest 3–5 articles tagged to Joetsu
* latest 3–5 articles tagged to Myoko

### Travel / weather strip

* manually flagged urgent content such as:

  * road closures
  * train disruptions
  * snow warnings
  * typhoon updates

### Events block

* selected event articles or a simple events content type later

---

## 15. SEO Foundations

This is non-negotiable if the site is meant to matter.

### Required

* unique title tags
* meta descriptions
* XML sitemap
* canonical tags
* proper H1/H2 structure
* article schema
* organization schema
* author pages
* alt text on images
* internal linking between related stories

### Content SEO opportunities

* explainers on local systems in English

  * garbage rules
  * snow removal policies
  * school schedules
  * local elections
  * train lines and disruptions
  * hospital / clinic guides
  * seasonal weather survival guides

These can bring evergreen traffic while news brings freshness.

---

## 16. Trust / Legitimacy Features

To avoid looking fake or disposable:

* visible masthead/logo
* real About page
* named authors or editor identity
* corrections policy
* clear contact information
* timestamps on every article
* “last updated” when applicable
* no anonymous AI sludge

Optional later:

* editorial standards page
* source methodology page

---

## 17. Monetization (Later, Not Launch-Blocking)

Potential later revenue paths:

* local sponsorships
* newsletter sponsorships
* local business ads
* affiliate links for local tourism / hotels / services where appropriate
* premium regional business briefings
* classified listings / events promotion
* job board section

Do **not** design the whole site around monetization from day one. First make something people would actually trust and use.

---

## 18. Future Expansion Paths

### v1.5

* newsletter signup integration
* simple event listings
* related articles block
* editor’s picks
* breaking news badge logic
* better search
* featured series / explainers

### v2

* bilingual workflow (English + Japanese summaries or mirrored content)
* newsletter archives
* business directory
* local jobs board
* weather alert widgets / integrations
* sponsored listings
* reader accounts / saved articles
* premium membership or donor support

---

## 19. Suggested Database Models

### Core models

* User
* Author
* Article
* Category
* Tag
* ArticleTag
* Location
* ArticleLocation
* StaticPage

### Optional models for near-future

* SiteSetting
* ContactSubmission
* TipSubmission
* NewsletterSignup
* Event
* Redirect

---

## 20. Admin Requirements

### Admin article index should support

* filter by status
* filter by category
* filter by author
* filter by location
* search by title
* sort by updated date / publish date

### Admin article form should support

* title
* slug
* dek
* body editor
* featured image upload
* caption
* author
* categories / tags / locations
* SEO fields
* publish controls
* preview link
* feature toggle

---

## 21. Security / Operational Basics

Minimum baseline:

* HTTPS only
* secure admin authentication
* rate limiting on forms
* spam protection on contact / tip forms
* backups
* error tracking
* image validation
* audit trail for article changes if feasible

Suggested tools:

* Sentry or Bugsnag
* Rack Attack
* simple backup routine for database

---

## 22. Performance Requirements

### v1 targets

* fast page load on mobile
* optimized images
* minimal JS on public pages
* caching for homepage and article pages where reasonable

This is one of the reasons Rails + Hotwire is a better fit than turning the site into a JavaScript carnival.

---

## 23. MVP Build Sequence

### Phase 1 — foundations

* Rails app setup
* auth/admin foundation
* article/content models
* basic public layout

### Phase 2 — publishing

* article CRUD
* categories/tags/locations
* homepage + article pages
* author pages

### Phase 3 — legitimacy + SEO

* metadata
* schema
* sitemap
* RSS
* static pages

### Phase 4 — polish

* search
* related article logic
* homepage curation
* mobile polish

---

## 24. Launch Criteria

The site is ready to launch when:

* articles can be created and published cleanly
* homepage looks credible on desktop and mobile
* article pages are readable and fast
* SEO metadata is in place
* static trust pages exist
* there are at least 10–20 solid starter articles / explainers / local guides

Do not launch with two posts and a dream.

---

## 25. Recommended v1 Positioning Copy

### Masthead

**Joetsu-Myoko Daily**

### Tagline options

* Local news for Joetsu, Myoko, and the surrounding region
* English-language local news from Joetsu and Myoko
* Local reporting, explainers, and updates from Joetsu-Myoko

---

## 26. Final Recommendation

Build **v1 as a focused Rails product** with a custom admin, not as a giant CMS project.

The winning move is:

* launch something real
* keep editorial workflow simple
* make it look trustworthy
* establish SEO foundations early
* leave room for weather, events, newsletters, and directories later

This is not complicated in concept. The danger is not underbuilding.
The danger is trying to build the Financial Times of Niigata before publishing article number three.
