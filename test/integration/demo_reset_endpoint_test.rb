require "test_helper"

class DemoResetEndpointTest < ActionDispatch::IntegrationTest
  TOKEN = "test-demo-reset-token".freeze

  setup do
    @previous_token = ENV.fetch("DEMO_RESET_TOKEN", nil)
    ENV["DEMO_RESET_TOKEN"] = TOKEN
    @visitor = User.create!(email: "visitor@example.com", password: "123456")
  end

  teardown do
    ENV["DEMO_RESET_TOKEN"] = @previous_token
  end

  test "without DEMO_RESET_TOKEN the endpoint does not exist" do
    [nil, ""].each do |unset|
      ENV["DEMO_RESET_TOKEN"] = unset
      # An empty token must not match an empty variable.
      post "/demo/reset", headers: { "Authorization" => "Bearer " }

      assert_response :not_found
    end
    assert User.exists?(@visitor.id)
  end

  test "without DEMO_RESET_TOKEN the answer matches a missing route" do
    ENV["DEMO_RESET_TOKEN"] = nil
    detailed = Rails.application.env_config["action_dispatch.show_detailed_exceptions"]
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false

    post "/demo/reset"
    reset_answer = [response.status, response.body]
    post "/no/such/route"

    assert_equal [response.status, response.body], reset_answer
  ensure
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = detailed
  end

  test "outside demo mode the endpoint answers like a missing route, even with the right token" do
    detailed = Rails.application.env_config["action_dispatch.show_detailed_exceptions"]
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false

    with_demo_mode(false) do
      post "/demo/reset", headers: { "Authorization" => "Bearer #{TOKEN}" }
      reset_answer = [response.status, response.body]
      post "/no/such/route"

      assert_equal [response.status, response.body], reset_answer
      assert_equal 404, reset_answer.first
    end
    assert User.exists?(@visitor.id)
  ensure
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = detailed
  end

  test "other verbs and method overrides never reset" do
    auth = { "Authorization" => "Bearer #{TOKEN}" }

    %i[get put patch delete].each do |verb|
      send(verb, "/demo/reset", headers: auth)

      assert_response :not_found
    end
    post "/demo/reset", params: { _method: "delete" }, headers: auth

    assert_response :not_found
    assert User.exists?(@visitor.id)
  end

  test "a removed or whitespace variable never authorizes, and a session does not count" do
    ENV.delete("DEMO_RESET_TOKEN")
    post "/demo/reset", headers: { "Authorization" => "Bearer " }

    assert_response :not_found

    ENV["DEMO_RESET_TOKEN"] = "   "
    post "/demo/reset", headers: { "Authorization" => "Bearer    " }

    assert_response :not_found

    ENV["DEMO_RESET_TOKEN"] = TOKEN
    # A real sign-in, which only a private installation offers; the sign_in test helper would write the session
    # cookie on the next request itself.
    with_demo_mode(false) do
      post user_session_path, params: { user: { email: "johan@tasker.com", password: "123456" } }
    end
    post "/demo/reset"

    assert_response :unauthorized
    assert_nil response.headers["Set-Cookie"]
    assert User.exists?(@visitor.id)
  end

  test "a missing or wrong token is rejected and nothing is deleted" do
    [{}, { "Authorization" => "Bearer wrong-token" }, { "Authorization" => TOKEN }].each do |headers|
      post("/demo/reset", headers:)

      assert_response :unauthorized
    end
    assert User.exists?(@visitor.id)
  end

  test "the right token resets the demo data" do
    capture_io { post "/demo/reset", headers: { "Authorization" => "Bearer #{TOKEN}" } }

    assert_response :no_content
    assert_not User.exists?(@visitor.id)
    assert_equal [7, 0, 0], [User.count, Category.count, Task.count]
    assert_equal User::TEAMMATE_EMAILS.sort, User.pluck(:email).sort
  end
end
