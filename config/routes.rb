Rails.application.routes.draw do
  # Sign in and sign out only (see the Devise modules in User): accounts come from `bin/rails users:create`.
  devise_for :users

  devise_scope :user do
    get "test", to: "users/tests#new"
    # The account page, where users change their password; there is no sign up or cancellation.
    resource :registration, only: %i[edit update], path: "users", controller: "users/registrations",
                            as: :user_registration
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
