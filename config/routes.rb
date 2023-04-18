Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :users
    end
  end

  namespace :api do
    namespace :v2 do
      resources :users
      post "/login", to: "sessions#create"
      delete "/logout", to: "sessions#destroy"
    end
  end
end
