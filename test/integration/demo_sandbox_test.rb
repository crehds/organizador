require "test_helper"
require "minitest/mock"

# "Probar el demo" (POST /test) gives each visitor a disposable account of their own.
class DemoSandboxTest < ActionDispatch::IntegrationTest
  setup do
    Users::TestsController::RATE_LIMIT_STORE.clear
    capture_io { Rails.application.load_seed }
  end

  test "Probar el demo creates a visitor with its own sample data and opens the task list" do
    assert_difference -> { User.visitors.count } => 1 do
      post "/test"
    end

    visitor = User.visitors.sole
    assert_redirected_to tasks_path
    assert_equal %w[conceptualización desarrollo ejercicios mercadeo], visitor.categories.pluck(:name).sort
    tasks = Task.where(owner: visitor)
    assert_equal 29, tasks.count
    assert_equal [visitor.id], tasks.joins(:category).distinct.pluck("categories.user_id")
    assert_equal [29 * 3, 29 * 3], [Participant.where(task: tasks).count,
                                    tasks.joins(:participants).where(users: { email: User::TEAMMATE_EMAILS }).count]

    follow_redirect!
    assert_response :success
    assert_select "nav .navbar-text", text: visitor.email
    assert_includes response.body, "Tarea #29"
  end

  test "each visitor gets separate data, and nobody sees another visitor's tasks" do
    post "/test"
    first = User.visitors.sole
    post "/test"
    second = User.visitors.where.not(id: first.id).sole

    assert_equal 29, Task.where(owner: second).count
    assert_empty first.categories.ids & second.categories.ids
    get tasks_path
    assert_select "nav .navbar-text", text: second.email
    assert_not_includes response.body, first.email
  end

  test "the password is random and never shown" do
    password = "contrasena-que-nadie-ve-#{SecureRandom.hex(4)}"
    bodies = []

    SecureRandom.stub(:base58, password) do
      post "/test"
      bodies << response.body
      follow_redirect!
      bodies << response.body
    end

    visitor = User.visitors.sole
    assert visitor.valid_password?(password)
    assert_not visitor.valid_password?("123456")
    bodies.each { |body| assert_not_includes body, password }
    assert_not_includes flash.to_h.values.join, password
  end

  test "GET /test creates nothing and sends old links to the sign-in page" do
    assert_no_difference -> { User.count } do
      get "/test"
    end

    assert_redirected_to new_user_session_path
  end

  test "outside demo mode GET and POST /test answer like a missing route and create nothing" do
    detailed = Rails.application.env_config["action_dispatch.show_detailed_exceptions"]
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false

    with_demo_mode(false) do
      assert_no_difference -> { User.count } do
        get "/test"
        get_answer = [response.status, response.body]
        post "/test"
        post_answer = [response.status, response.body]
        post "/no/such/route"

        assert_equal [[response.status, response.body]] * 2, [get_answer, post_answer]
        assert_equal 404, post_answer.first
      end
    end
  ensure
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = detailed
  end

  test "one address can create ten accounts an hour; the next attempt creates nothing" do
    10.times { post "/test" }
    assert_equal 10, User.visitors.count
    assert_redirected_to tasks_path

    assert_no_difference -> { User.count } do
      post "/test"
    end

    assert_redirected_to new_user_session_path
    assert_equal "Creaste demasiadas cuentas de prueba. Vuelve a intentarlo en una hora.", flash[:alert]
  end

  test "without the teammates the demo shows a message and creates nothing" do
    Participant.delete_all
    User.teammates.delete_all

    assert_no_difference -> { User.count } do
      post "/test"
    end

    assert_redirected_to new_user_session_path
    follow_redirect!
    assert_select "#flash_alert", "El demo no está disponible en este momento."
  end
end
