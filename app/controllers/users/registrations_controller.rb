module Users
  # The account page only changes the password; the email stays as `bin/rails users:create` made it.
  # Every visitor shares the demo account through /test, so nobody may change it.
  class RegistrationsController < Devise::RegistrationsController
    # Devise defines edit, update and destroy in the parent class.
    before_action :protect_demo_account, only: %i[edit update destroy] # rubocop:disable Rails/LexicallyScopedActionFilter

    private

    def account_update_params
      super.slice(:password, :password_confirmation, :current_password)
    end

    def protect_demo_account
      redirect_to root_path, alert: "The demo account cannot be changed." if current_user.demo?
    end
  end
end
