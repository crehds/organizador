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

  test "the demo user cannot change the password" do
    sign_in users(:johan)

    patch user_registration_path,
          params: { user: { password: "abcdef", password_confirmation: "abcdef", current_password: "123456" } }

    assert_redirected_to root_path
    assert_equal ALERT, flash[:alert]
    assert users(:johan).reload.valid_password?("123456")
  end

  test "the demo user cannot change or cancel the account through JSON" do
    sign_in users(:johan)
    before = users(:johan).reload.attributes

    patch "/users", params: { user: { email: "x@tasker.com", current_password: "123456" } }, as: :json
    put "/users", params: { user: { password: "abcdef", password_confirmation: "abcdef", current_password: "123456" } },
                  as: :json
    delete "/users.json"

    assert_equal before, users(:johan).reload.attributes
  end

  test "signing in with odd email casing does not get around the guard" do
    post user_session_path, params: { user: { email: " JOHAN@Tasker.com ", password: "123456" } }

    get edit_user_registration_path

    assert_redirected_to root_path
  end

  test "other users still open their account page" do
    sign_in users(:outsider)

    get edit_user_registration_path

    assert_response :success
  end
end
