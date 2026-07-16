Rails.application.routes.draw do
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  scope "(:locale)", locale: /en|vi/ do
    root "home#index"

    devise_for :users

    resources :products, only: [:index, :show]

    resources :bookings, only: [:index, :show, :new, :create] do
      member do
        patch :cancel
      end
    end

    namespace :owner do
      resources :products

      resources :bookings, only: [:index, :show] do
        member do
          patch :accept
          patch :reject
          patch :complete
        end
      end
    end

    namespace :admin do
      root "dashboard#index"

      resources :users, only: [:index, :show, :edit, :update]
      resources :products, only: [:index, :show, :edit, :update]
      resources :bookings, only: [:index, :show, :edit, :update]
    end
  end
end
