module Users
  # The account page only changes the password; the email stays as `bin/rails users:create` made it.
  # In demo mode every account comes from the seeds with a public password, so nobody may change one.
  class RegistrationsController < Devise::RegistrationsController
    # Devise defines edit, update and destroy in the parent class.
    before_action :protect_demo_accounts, only: %i[edit update destroy] # rubocop:disable Rails/LexicallyScopedActionFilter

    private

    def account_update_params
      super.slice(:password, :password_confirmation, :current_password)
    end

    def protect_demo_accounts
      redirect_to root_path, alert: "Demo accounts cannot be changed." if demo_mode?
    end
  end
end
