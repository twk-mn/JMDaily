Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Admin
  namespace :admin do
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
    end
    resources :categories
    resources :tags
    resources :locations
    resources :authors
    resources :static_pages
    resources :ads
    resources :contact_submissions, only: [:index, :show, :destroy]
    resources :tip_submissions, only: [:index, :show, :destroy]
    resources :newsletter_subscribers, only: [:index, :destroy]
    resources :users
    resources :audit_logs, only: [:index]
  end

  # Ad click tracking
  get "ads/:id/click", to: "ads#click", as: :ad_click

  # Public routes
  root "home#index"

  # Search
  get "search", to: "search#index"

  # Static pages
  get  "about",            to: "pages#show",          defaults: { slug: "about" },            as: :about
  get  "contact",          to: "pages#show",          defaults: { slug: "contact" },           as: :contact
  post "contact",          to: "pages#submit_contact",                                         as: :submit_contact
  get  "submit-a-tip",     to: "pages#show",          defaults: { slug: "submit-a-tip" },      as: :submit_a_tip
  post "submit-a-tip",     to: "pages#submit_tip",                                             as: :submit_tip
  get  "privacy-policy",   to: "pages#show",          defaults: { slug: "privacy-policy" },    as: :privacy_policy
  get  "terms",            to: "pages#show",          defaults: { slug: "terms" },             as: :terms
  get  "corrections-policy", to: "pages#show",        defaults: { slug: "corrections-policy" }, as: :corrections_policy

  # Content pages
  resources :articles, only: [:show], path: "articles"
  resources :authors, only: [:show], param: :slug
  resources :tags, only: [:show], param: :slug

  # Location pages
  get "locations/:slug", to: "locations#show", as: :location

  # Category pages — these go last to avoid catching other routes
  get "news", to: "categories#show", defaults: { slug: "news" }
  get "politics", to: "categories#show", defaults: { slug: "politics" }
  get "business", to: "categories#show", defaults: { slug: "business" }
  get "community", to: "categories#show", defaults: { slug: "community" }
  get "weather-travel", to: "categories#show", defaults: { slug: "weather-travel" }
  get "events", to: "categories#show", defaults: { slug: "events" }
  get "opinion", to: "categories#show", defaults: { slug: "opinion" }

  # Newsletter
  post "newsletter/subscribe",   to: "newsletter_subscriptions#create",      as: :newsletter_subscribe
  get  "newsletter/confirm",     to: "newsletter_subscriptions#confirm",      as: :confirm_newsletter
  get  "newsletter/unsubscribe", to: "newsletter_subscriptions#unsubscribe",  as: :newsletter_unsubscribe

  # RSS
  get "feed", to: "feed#index", defaults: { format: :rss }
end
