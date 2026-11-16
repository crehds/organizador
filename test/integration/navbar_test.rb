require "test_helper"

# Signing out must not depend on opening a menu, so the email and the button sit in the navbar itself.
class NavbarTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:juan)
  end

  test "the navbar shows the signed in user's email" do
    get tasks_path

    assert_select "nav .navbar-text", text: "juan@tasker.com"
  end

  test "the sign out button is in the navbar, not inside a dropdown menu" do
    get tasks_path

    assert_select "nav form[action=?] input[name=_method][value=delete]", destroy_user_session_path
    assert_select "nav form[action=?] button", destroy_user_session_path, text: "Cerrar sesión"
    assert_select ".dropdown-menu form[action=?]", destroy_user_session_path, count: 0
  end
end
