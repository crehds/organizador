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
    assert_equal [8, 4, 29], [User.count, Category.count, Task.count]
  end
end
