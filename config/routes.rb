Rails.application.routes.draw do
  resource :cart, only: [:show] do
    post :add_item
    delete :remove_item
    patch :update_quantity
  end

  # Checkout flow
  get "checkout", to: "checkout#new", as: :checkout
  get "checkout/shipping", to: "checkout#shipping", as: :checkout_shipping
  get "checkout/payment", to: "checkout#payment", as: :checkout_payment
  post "checkout/process", to: "checkout#process_checkout", as: :checkout_process
  get "checkout/confirmation", to: "checkout#confirmation", as: :checkout_confirmation

  resources :coffees, only: [:index, :show]
  get "home/index"
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "sessions#new"
end
