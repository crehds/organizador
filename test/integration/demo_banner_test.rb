require "test_helper"

# /test signs visitors in as johan; the banner tells them so and lets them leave or sign up.
class DemoBannerTest < ActionDispatch::IntegrationTest
  test "the demo user sees the banner with its two buttons" do
    sign_in users(:johan)

    get tasks_path

    assert_select ".demo-banner", text: /Estás en el demo/
    assert_select ".demo-banner form[action=?]", destroy_user_session_path, count: 2
    assert_select ".demo-banner form[action=?] button", destroy_user_session_path, text: "Crear mi cuenta"
    assert_select ".demo-banner form[action=?] input[name=next][value=sign_up]", destroy_user_session_path
    assert_select ".demo-banner form[action=?] button", destroy_user_session_path, text: "Salir"
  end

  test "other users do not see the banner" do
    sign_in users(:juan)

    get tasks_path

    assert_select ".demo-banner", count: 0
  end

  test "guests do not see the banner on the sign in page" do
    get new_user_session_path

    assert_response :success
    assert_select ".demo-banner", count: 0
  end

  test "Crear mi cuenta signs the demo user out and opens the sign up page" do
    sign_in users(:johan)

    delete destroy_user_session_path, params: { next: "sign_up" }

    assert_redirected_to new_user_registration_path
    get tasks_path
    assert_redirected_to new_user_session_path
  end

  test "Salir signs the demo user out and goes where sign out always went" do
    sign_in users(:johan)

    delete destroy_user_session_path

    assert_redirected_to root_path
    get tasks_path
    assert_redirected_to new_user_session_path
  end

  test "any other next value is ignored, so sign out never redirects to a URL from the request" do
    ["https://evil.example", "//evil.example", "/tasks", ""].each do |target|
      sign_in users(:johan)

      delete destroy_user_session_path, params: { next: target }

      assert_redirected_to root_path, "next=#{target.inspect}"
    end
  end

  test "hostile and non-string next values fall back to the root" do
    ["%2F%2Fevil.example", "/\\evil.example", "javascript:alert(1)", " sign_up", "SIGN_UP",
     "sign_up\n", ["sign_up"], { "a" => "sign_up" }].each do |target|
      sign_in users(:johan)
      delete destroy_user_session_path, params: { next: target }

      assert_redirected_to root_path, target.inspect
    end
  end

  test "sign out forms carry a CSRF token and a tokenless sign out keeps the session" do
    ActionController::Base.allow_forgery_protection = true
    sign_in users(:johan)
    get tasks_path

    assert_select ".demo-banner form input[name=authenticity_token]", count: 2
    assert_select "nav form input[name=authenticity_token]", count: 1

    delete destroy_user_session_path, params: { next: "sign_up" }

    assert_response :unprocessable_entity
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "Crear mi cuenta ends on the sign up form, signed out" do
    sign_in users(:johan)
    delete destroy_user_session_path, params: { next: "sign_up" }
    follow_redirect!

    assert_select "form[action=?]", user_registration_path
    assert_select ".demo-banner", count: 0
  end
end
