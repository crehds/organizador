module Users
  # Every visitor shares the demo account through /test, so nobody may edit or cancel it.
  class RegistrationsController < Devise::RegistrationsController
    # Devise defines edit, update and destroy in the parent class.
    before_action :protect_demo_account, only: %i[edit update destroy] # rubocop:disable Rails/LexicallyScopedActionFilter

    private

    def protect_demo_account
      redirect_to root_path, alert: "The demo account cannot be changed." if current_user.demo?
    end
  end
end
