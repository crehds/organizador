Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }

  devise_scope :user do
    get "test", to: "users/tests#new"
  end

  resources :tasks do
    resources :notes, only: [:create], controller: "tasks/notes"
  end
  resources :categories
  post "demo/reset", to: "demo_resets#create"

  # Railway's health check; answers 200 once the app boots.
  get "up" => "rails/health#show", as: :rails_health_check
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Signed in users keep their task list at "/"; guests get the landing page there.
  authenticated :user do
    root "tasks#index", as: :authenticated_root
  end
  root "pages#home"
end
