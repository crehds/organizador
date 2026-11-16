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

  test "the demo login signs in as the demo user" do
    task = create_task

    get "/test"
    assert_redirected_to tasks_path

    follow_redirect!
    assert_response :success
    assert_includes response.body, task.name
  end
end
