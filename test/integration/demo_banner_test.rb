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
end
