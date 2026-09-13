Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Registers the :user Devise mapping (current_user, authenticate_user!) without
  # generating any of Devise's own routes — signup/login/logout are defined below.
  devise_for :users, skip: :all

  namespace :api do
    namespace :v1 do
      post "signup", to: "registrations#create"
      post "login", to: "sessions#create"
      delete "logout", to: "sessions#destroy"

      resources :animals, except: %i[new edit] do
        resources :events, except: %i[new edit], shallow: true
      end
    end
  end
end
