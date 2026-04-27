Rails.application.routes.draw do
  # Routes accept any plausible ISO 639-1 style locale segment. The active list
  # lives in SiteLanguage; ApplicationController#set_locale 404s requests for
  # locales that aren't currently active. Keeping the route regex permissive
  # means admins can add or remove languages at runtime without a server
  # restart — no route recompilation required.
  LOCALE_SEGMENT = /[a-z]{2,3}/

  # Health check (no locale needed)
  get "up" => "rails/health#show", as: :rails_health_check

  # Admin (English-only, no locale prefix)
  namespace :admin do
    root to: "dashboard#index"

    get    "login",          to: "sessions#new"
    post   "login",          to: "sessions#create"
    delete "logout",         to: "sessions#destroy"
    get    "login/verify",   to: "sessions#verify_otp",   as: :two_factor_verify
    post   "login/verify",   to: "sessions#confirm_otp",  as: :two_factor_confirm

    get    "two-factor",         to: "two_factor#show",    as: :two_factor
    post   "two-factor/enable",  to: "two_factor#enable",  as: :two_factor_enable
    delete "two-factor",         to: "two_factor#disable", as: :two_factor_disable

    resources :articles do
      member { get :preview }
      collection { post :bulk }
    end
    resources :categories
    resources :tags
    resources :locations
    resources :authors
    resources :static_pages
    resources :ads
    resources :contact_submissions, only: [ :index, :show, :destroy ]
    resources :tip_submissions, only: [ :index, :show, :destroy ]
    resources :newsletter_subscribers, only: [ :index, :destroy ]
    resources :comments, only: [ :index, :destroy ] do
      member do
        post :approve
        post :reject
      end
    end
    resources :newsletter_issues do
      member do
        post :send_issue
        get  :preview
      end
    end
    resources :users
    resources :audit_logs, only: [ :index ]

    # Settings (admin-only, see Admin::SettingsController)
    get  "settings",         to: "settings#show",   as: :settings
    get  "settings/:tab",    to: "settings#show",   as: :settings_tab, constraints: { tab: /general|security|newsletter|languages/ }
    patch "settings",        to: "settings#update"

    resources :site_languages, only: [ :create, :update, :destroy ], path: "settings/languages" do
      member do
        post :activate
        post :deactivate
      end
      collection do
        post :reorder
      end
    end
  end

  # Ad click tracking (no locale needed)
  get "ads/:id/click", to: "ads#click", as: :ad_click

  # RSS / Sitemap (no locale needed)
  get "feed", to: "feed#index", defaults: { format: :rss }

  # Root: detect preferred locale from cookie / Accept-Language and redirect.
  root to: redirect { |_, req|
    locale = req.cookies["locale"]
    locale = "en" unless SiteLanguage.active_codes.include?(locale.to_s)
    "/#{locale}"
  }

  # All public routes are scoped under /:locale
  scope "/:locale", constraints: { locale: LOCALE_SEGMENT } do
    # Home
    root to: "home#index", as: :locale_root

    # Search
    get "search", to: "search#index"

    # Static pages
    get  "about",             to: "pages#show", defaults: { slug: "about" },              as: :about
    get  "contact",           to: "pages#show", defaults: { slug: "contact" },             as: :contact
    post "contact",           to: "pages#submit_contact",                                  as: :submit_contact
    get  "submit-a-tip",      to: "pages#show", defaults: { slug: "submit-a-tip" },        as: :submit_a_tip
    post "submit-a-tip",      to: "pages#submit_tip",                                      as: :submit_tip
    get  "privacy-policy",    to: "pages#show", defaults: { slug: "privacy-policy" },      as: :privacy_policy
    get  "terms",             to: "pages#show", defaults: { slug: "terms" },               as: :terms
    get  "corrections-policy", to: "pages#show", defaults: { slug: "corrections-policy" }, as: :corrections_policy

    # Articles and comments
    resources :articles, only: [ :show ], path: "articles" do
      resources :comments, only: [ :create ], shallow: true
    end

    # Authors, tags
    resources :authors, only: [ :show ], param: :slug
    resources :tags, only: [ :show ], param: :slug

    # Locations
    get "locations/:slug", to: "locations#show", as: :location

    # Category pages — last to avoid catching other routes
    get "news",           to: "categories#show", defaults: { slug: "news" }
    get "politics",       to: "categories#show", defaults: { slug: "politics" }
    get "business",       to: "categories#show", defaults: { slug: "business" }
    get "community",      to: "categories#show", defaults: { slug: "community" }
    get "weather-travel", to: "categories#show", defaults: { slug: "weather-travel" }
    get "events",         to: "categories#show", defaults: { slug: "events" }
    get "opinion",        to: "categories#show", defaults: { slug: "opinion" }

    # Newsletter subscriptions
    post "newsletter/subscribe",   to: "newsletter_subscriptions#create",     as: :newsletter_subscribe
    get  "newsletter/confirm",     to: "newsletter_subscriptions#confirm",     as: :confirm_newsletter
    get  "newsletter/unsubscribe", to: "newsletter_subscriptions#unsubscribe", as: :newsletter_unsubscribe
  end

  # Legacy redirect: old /articles/:slug → /en/articles/:slug
  get "articles/:slug", to: redirect("/en/articles/%{slug}")
end
