require "test_helper"

# /test signs every visitor in as johan, so johan's account must stay as the seeds made it.
class DemoAccountTest < ActionDispatch::IntegrationTest
  ALERT = "The demo account cannot be changed.".freeze

  test "the demo user cannot open the account page" do
    sign_in users(:johan)

    get edit_user_registration_path

    assert_redirected_to root_path
    assert_equal ALERT, flash[:alert]
  end

  test "the demo user cannot change the account" do
    sign_in users(:johan)

    patch user_registration_path, params: { user: { email: "changed@tasker.com", current_password: "123456" } }

    assert_redirected_to root_path
    assert_equal ALERT, flash[:alert]
    assert_equal "johan@tasker.com", users(:johan).reload.email
  end

  test "the demo user cannot cancel the account" do
    sign_in users(:johan)

    delete user_registration_path

    assert_redirected_to root_path
    assert_equal ALERT, flash[:alert]
    assert User.exists?(users(:johan).id)
  end

  test "other users still open their account page" do
    sign_in users(:outsider)

    get edit_user_registration_path

    assert_response :success
  end

  test "other users still change their account" do
    sign_in users(:outsider)

    patch user_registration_path, params: { user: { email: "changed@tasker.com", current_password: "123456" } }

    assert_equal "changed@tasker.com", users(:outsider).reload.email
  end

  test "other users still cancel their account" do
    sign_in users(:outsider)

    delete user_registration_path

    assert_not User.exists?(users(:outsider).id)
  end

  test "visitors still sign up" do
    post user_registration_path,
         params: { user: { email: "visitor@example.com", password: "123456", password_confirmation: "123456" } }

    assert User.exists?(email: "visitor@example.com")
  end
end
