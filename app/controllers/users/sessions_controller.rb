module Users
  # In demo mode nobody signs in with a password: visitors use "Probar el demo", and older demo accounts may still
  # have the public seed password until the next reset. A private installation keeps Devise's sign-in.
  class SessionsController < Devise::SessionsController
    # Prepended so it runs before the CSRF check: the route answers exactly like a missing one.
    # Devise defines create in the parent class.
    prepend_before_action :reject_password_sign_in, only: :create # rubocop:disable Rails/LexicallyScopedActionFilter

    private

    def reject_password_sign_in
      raise ActionController::RoutingError, "Not Found" if demo_mode?
    end
  end
end
