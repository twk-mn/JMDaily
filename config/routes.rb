Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Admin
  namespace :admin do
    get "login", to: "sessions#new"
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy"

    resources :articles
    resources :categories
    resources :tags
    resources :locations
    resources :authors
    resources :static_pages
    resources :ads
  end

  # Ad click tracking
  get "ads/:id/click", to: "ads#click", as: :ad_click

  # Public routes
  root "home#index"

  # Search
  get "search", to: "search#index"

  # Static pages
  get "about", to: "pages#show", defaults: { slug: "about" }
  get "contact", to: "pages#show", defaults: { slug: "contact" }
  post "contact", to: "pages#submit_contact"
  get "submit-a-tip", to: "pages#show", defaults: { slug: "submit-a-tip" }
  get "privacy-policy", to: "pages#show", defaults: { slug: "privacy-policy" }
  get "terms", to: "pages#show", defaults: { slug: "terms" }
  get "corrections-policy", to: "pages#show", defaults: { slug: "corrections-policy" }

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

  # RSS
  get "feed", to: "feed#index", defaults: { format: :rss }
end
