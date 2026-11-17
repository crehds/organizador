# "Probar el demo" (POST /test) gives each visitor a disposable account of their own and opens the task list.
# A private installation has no demo, so both /test routes answer exactly like a missing route.
class Users::TestsController < ApplicationController
  # shortcut: counts live in this process, which is enough while one Puma process serves the demo (threads, no
  # workers); move them to a shared cache store once the demo runs more processes or instances.
  # The default store, Rails.cache, discards everything in tests, so the limit could not be tested.
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new

  skip_before_action :authenticate_user!
  # Prepended so it runs before the CSRF check and the limit: outside demo mode nothing is counted and every
  # request, tokenless POSTs included, answers not found.
  prepend_before_action :require_demo_mode
  rate_limit to: 10, within: 1.hour, store: RATE_LIMIT_STORE, only: :create, with: lambda {
    redirect_to new_user_session_path, alert: "Creaste demasiadas cuentas de prueba. Vuelve a intentarlo en una hora."
  }

  # Old links to /test keep working, but only the button creates an account.
  def new
    redirect_to new_user_session_path
  end

  def create
    sign_in DemoSandbox.call
    redirect_to tasks_path
  rescue DemoSandbox::Unavailable => e
    Rails.logger.error(e.message)
    redirect_to new_user_session_path, alert: "El demo no está disponible en este momento."
  end

  private

  def require_demo_mode
    raise ActionController::RoutingError, "Not Found" unless demo_mode?
  end
end
