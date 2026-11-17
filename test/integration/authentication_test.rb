require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "guests are sent to the sign in page" do
    get tasks_path

    assert_redirected_to new_user_session_path
  end

  test "a user signs in with email and password" do
    post user_session_path, params: { user: { email: "johan@tasker.com", password: "123456" } }
    assert_redirected_to root_path

    get tasks_path
    assert_response :success
  end

  test "a wrong password does not sign the user in" do
    post user_session_path, params: { user: { email: "johan@tasker.com", password: "wrong" } }

    get tasks_path
    assert_redirected_to new_user_session_path
  end
end
