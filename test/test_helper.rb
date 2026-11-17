ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    fixtures :all

    # The demo notice on the sign-in page and the app banner (S7).
    DEMO_NOTICE = "Es un demo: tu cuenta es temporal y se borra a las 24 horas. " \
                  "Si cierras sesión o el navegador, no podrás volver a entrar.".freeze

    # Built here, not as fixtures: loading fixtures with foreign keys needs a PostgreSQL superuser.
    def create_task(name: "Tarea #1", owner: users(:johan), participant: users(:juan),
                    category: categories(:desarrollo))
      Task.create!(
        name:,
        description: "Bienvenida",
        due_date: Date.current + 15,
        category:,
        owner:,
        participating_users: [Participant.new(user: participant, role: :responsable)]
      )
    end

    # A demo visitor with a known password; "Probar el demo" gives real visitors a random one nobody sees.
    def create_visitor
      User.create!(email: "visitante-prueba@#{User::VISITOR_DOMAIN}", password: "123456")
    end

    # The app reads DEMO_MODE at request time, so a test can switch it and restore it afterwards.
    def with_demo_mode(enabled)
      previous = Rails.configuration.x.demo_mode
      Rails.configuration.x.demo_mode = enabled
      yield
    ensure
      Rails.configuration.x.demo_mode = previous
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers

    # Devise 4.9.3 builds its mappings while the routes load, which Rails 8 defers; sign_in needs them first.
    setup { Rails.application.reload_routes_unless_loaded }
  end
end
