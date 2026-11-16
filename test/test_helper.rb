ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    fixtures :all

    # Built here, not as fixtures: loading fixtures with foreign keys needs a PostgreSQL superuser.
    def create_task(name: "Tarea #1", owner: users(:johan), participant: users(:juan))
      Task.create!(
        name:,
        description: "Bienvenida",
        due_date: Date.current + 15,
        category: categories(:desarrollo),
        owner:,
        participating_users: [Participant.new(user: participant, role: :responsable)]
      )
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
