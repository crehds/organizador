require "test_helper"

# DEMO_MODE=true runs the public demo; any other value runs a private installation with no demo entry points.
class DemoModeTest < ActionDispatch::IntegrationTest
  test "outside demo mode /test answers like a missing route and signs nobody in" do
    detailed = Rails.application.env_config["action_dispatch.show_detailed_exceptions"]
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = false

    with_demo_mode(false) do
      get "/test"
      test_answer = [response.status, response.body]
      get "/no/such/route"

      assert_equal [response.status, response.body], test_answer
      assert_equal 404, test_answer.first
    end
    get tasks_path
    assert_redirected_to new_user_session_path
  ensure
    Rails.application.env_config["action_dispatch.show_detailed_exceptions"] = detailed
  end

  test "outside demo mode a signed in user also gets a missing route at /test" do
    sign_in users(:juan)

    with_demo_mode(false) { get "/test" }

    assert_response :not_found
  end

  test "the sign in page links to the demo only in demo mode" do
    get new_user_session_path
    assert_select "a[href=?]", "/test"

    with_demo_mode(false) { get new_user_session_path }

    assert_response :success
    assert_select "a[href=?]", "/test", count: 0
  end

  test "outside demo mode the demo email is an ordinary account: no banner and the account page opens" do
    sign_in users(:johan)

    with_demo_mode(false) do
      get tasks_path
      assert_select ".demo-banner", count: 0

      get edit_user_registration_path
      assert_response :success
    end
  end
end
