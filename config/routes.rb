Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  post "auth/login", to: "auth#login"
  post "auth/refresh-token", to: "auth#refresh_token"
  post "auth/set-initial-password", to: "auth#set_initial_password"
  post "auth/forgot-password", to: "auth#forgot_password"
  post "auth/reset-password", to: "auth#reset_password"
  post "auth/resend-verification-code", to: "auth#resend_verification_code"

  # Companies routes
  resources :companies, only: [ :index ]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
end
