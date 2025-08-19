Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'auth/registrations'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "application#index"

  constraints(AdminConstraint) do
    namespace :admin do
      resources :users do
        member do
          get :subscription
        end
      end
    end
  end

  resources :subscriptions, only: %i[create]
  resources :user_downloads, only: :index
  resources :reports do
    member do
      post :download_excel
      post :download
      get :render_download
      get :intersection_captions
      get 'intersection_captions/:intersection_id/edit', to: 'reports#edit_intersection_caption', as: :edit_intersection_caption
      post :intersection_captions, to: 'reports#create_intersection_caption'
      delete 'intersection_captions/:intersection_id', to: 'reports#destroy_intersection_caption', as: :destroy_intersection_caption
    end
  end

  get 'subscription', to: 'users#subscription', as: :subscription
  match 'subscriptions/:id/cancel', via: %i[get post], to: 'users#cancel_subscription', as: :cancel_subscription
  get 'subscriptions/:id/edit', to: 'users#edit_subscription', as: :edit_subscription
  post 'webhooks/:source', to: 'webhooks#create'

  get :contact, to: 'application#contact', as: :contact

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
  mount MissionControl::Jobs::Engine, at: "/jobs"
end