require "test_helper"

# In demo mode visitors never know their password and the teammates are fictitious, so no account can change.
class DemoAccountTest < ActionDispatch::IntegrationTest
  ALERT = "Las cuentas del demo no se pueden cambiar.".freeze

  setup do
    @visitor = create_visitor
  end

  test "a visitor cannot open the account page" do
    sign_in @visitor

    get edit_user_registration_path

    assert_redirected_to root_path
    assert_equal ALERT, flash[:alert]
  end

  test "a visitor cannot change the password" do
    sign_in @visitor

    patch user_registration_path,
          params: { user: { password: "abcdef", password_confirmation: "abcdef", current_password: "123456" } }

    assert_redirected_to root_path
    assert_equal ALERT, flash[:alert]
    assert @visitor.reload.valid_password?("123456")
  end

  test "a visitor cannot change the account through JSON, and the removed cancel route deletes nothing" do
    sign_in @visitor
    before = @visitor.reload.attributes

    patch "/users", params: { user: { email: "x@tasker.com", current_password: "123456" } }, as: :json
    put "/users", params: { user: { password: "abcdef", password_confirmation: "abcdef", current_password: "123456" } },
                  as: :json
    delete "/users.json"

    assert_equal before, @visitor.reload.attributes
  end

  test "a password sign-in with odd email casing does not exist in demo mode either" do
    post user_session_path, params: { user: { email: " #{@visitor.email.upcase} ", password: "123456" } }

    assert_response :not_found
    get edit_user_registration_path
    assert_redirected_to new_user_session_path
  end

  test "in demo mode every account is locked, teammates and other users included" do
    [users(:juan), users(:johan)].each do |user|
      sign_in user

      patch user_registration_path,
            params: { user: { password: "abcdef", password_confirmation: "abcdef", current_password: "123456" } }

      assert_redirected_to root_path
      assert_equal ALERT, flash[:alert]
      assert user.reload.valid_password?("123456")
    end
  end

  test "in a private installation users still open their account page" do
    with_demo_mode(false) do
      sign_in users(:outsider)

      get edit_user_registration_path

      assert_response :success
    end
  end
end
