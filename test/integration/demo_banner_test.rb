require "test_helper"

# Visitors get a temporary account from "Probar el demo"; the banner tells them so and lets them leave.
class DemoBannerTest < ActionDispatch::IntegrationTest
  setup do
    @visitor = create_visitor
  end

  test "a visitor sees the banner with its sign out button and no sign-up button" do
    sign_in @visitor

    get tasks_path

    assert_select ".demo-banner", count: 1
    assert_select ".demo-banner p", text: SignInPageTest::NOTICE
    assert_select ".demo-banner form[action=?]", destroy_user_session_path, count: 1
    assert_select ".demo-banner form[action=?] button", destroy_user_session_path, text: "Salir"
    assert_select ".demo-banner input[name=next]", count: 0
    assert_not_includes response.body, "Crear mi cuenta"
  end

  test "other users do not see the banner" do
    sign_in users(:juan)

    get tasks_path

    assert_select ".demo-banner", count: 0
  end

  test "Salir signs the visitor out and goes where sign out always went" do
    sign_in @visitor

    delete destroy_user_session_path

    assert_redirected_to root_path
    get tasks_path
    assert_redirected_to new_user_session_path
    assert User.exists?(@visitor.id)
  end

  test "sign out forms carry a CSRF token and a tokenless sign out keeps the session" do
    ActionController::Base.allow_forgery_protection = true
    sign_in @visitor
    get tasks_path

    assert_select ".demo-banner form input[name=authenticity_token]", count: 1
    assert_select "nav form input[name=authenticity_token]", count: 1

    delete destroy_user_session_path

    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = false
  end
end
