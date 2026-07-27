Rails.application.routes.draw do
  require "sidekiq/web"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Route always exists; admin check lives in SidekiqAdminAuth middleware.
  mount Sidekiq::Web => "/sidekiq"

  devise_for :users,
    only: :omniauth_callbacks,
    controllers: {
      omniauth_callbacks: "users/omniauth_callbacks"
    }

  namespace :api do
    namespace :v1 do
      scope :auth, controller: :auth do
        post :sign_in
        post :sign_up
        get :me
        patch :profile
      end

      resources :bookings, only: [:index, :show, :create] do
        collection do
          post :price_preview
        end
      end

      resources :conversations, only: [:index, :show] do
        collection do
          post :support
          post :booking
        end
        member do
          post :messages, action: :create_message
        end
      end

      resource :home_spotlight, only: [:show]
      resources :products, only: [:index, :show]
    end
  end

  scope "(:locale)", locale: /en|vi/ do
    root "home#index"

    devise_for :users,
      skip: :omniauth_callbacks,
      controllers: {
        registrations: "users/registrations"
      }

    resources :users, only: [:show]
    resources :products, only: [:index, :show]

    resources :bookings, only: [:index, :show, :new, :create] do
      member do
        patch :cancel
        patch :pay
        patch :confirm_received
        post :chat
      end
    end

    resources :conversations, only: [:index, :show] do
      collection do
        post :support
      end
      member do
        post :messages, action: :create_message
      end
    end

    namespace :owner do
      resources :products

      resources :bookings, only: [:index, :show] do
        member do
          patch :accept
          patch :reject
          patch :complete
          post :chat
        end
      end
    end

    namespace :admin do
      root "dashboard#index"

      resources :users, only: [:index, :show, :edit, :update]
      resources :products, only: [:index, :show, :edit, :update]
      resources :bookings, only: [:index, :show, :edit, :update]
      resources :payouts, only: [:index, :show, :update]
      resources :conversations, only: [:index, :show] do
        member do
          post :messages, action: :create_message
        end
      end

      resource :home_spotlight, only: [:edit, :update]
      resource :account, only: [:edit, :update]
    end
  end
end
