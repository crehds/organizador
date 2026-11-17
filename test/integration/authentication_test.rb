require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "guests are sent to the sign in page" do
    get tasks_path

    assert_redirected_to new_user_session_path
  end

  test "in a private installation a user signs in with email and password" do
    with_demo_mode(false) do
      post user_session_path, params: { user: { email: "johan@tasker.com", password: "123456" } }
      assert_redirected_to root_path

      get tasks_path
      assert_response :success
    end
  end

  test "in a private installation a wrong password does not sign the user in" do
    with_demo_mode(false) do
      post user_session_path, params: { user: { email: "johan@tasker.com", password: "wrong" } }

      get tasks_path
      assert_redirected_to new_user_session_path
    end
  end

  # Upgraded demos can keep accounts with the old public password until the reset runs; none of them may sign in.
  test "in demo mode password sign-in answers like a missing route and signs nobody in" do
    [users(:juan).email, users(:johan).email, create_visitor.email].each do |email|
      post user_session_path, params: { user: { email:, password: "123456" } }

      assert_response :not_found, email
      get tasks_path
      assert_redirected_to new_user_session_path
    end
  end

  test "in demo mode signing out still works" do
    sign_in create_visitor

    delete destroy_user_session_path

    assert_redirected_to root_path
    get tasks_path
    assert_redirected_to new_user_session_path
  end
end
