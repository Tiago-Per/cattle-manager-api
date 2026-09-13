Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :animals, except: %i[new edit] do
        resources :events, except: %i[new edit], shallow: true
      end
    end
  end
end
