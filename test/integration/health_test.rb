require "test_helper"

class HealthTest < ActionDispatch::IntegrationTest
  test "the health check answers without signing in" do
    get "/up"

    assert_response :success
  end
end
