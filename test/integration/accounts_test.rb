require "test_helper"

# Accounts come from `bin/rails users:create`; afterwards users can only change their own password.
class AccountsTest < ActionDispatch::IntegrationTest
  NEW_PASSWORD = { password: "nueva-clave", password_confirmation: "nueva-clave" }.freeze

  test "there is no sign-up, account cancellation or password reset route" do
    helpers = Rails.application.routes.url_helpers

    %i[new_user_registration_path cancel_user_registration_path new_user_password_path
       edit_user_password_path user_password_path].each do |helper|
      assert_not helpers.respond_to?(helper), helper
    end
  end

  test "sign-up, cancellation and password reset requests answer not found in either mode" do
    sign_up = { user: { email: "visitor@example.com", password: "123456", password_confirmation: "123456" } }

    [true, false].each do |demo|
      with_demo_mode(demo) do
        get "/users/sign_up"
        assert_response :not_found
        post("/users", params: sign_up)
        assert_response :not_found
        get "/users/cancel"
        assert_response :not_found
        get "/users/password/new"
        assert_response :not_found
        post "/users/password", params: { user: { email: "juan@tasker.com" } }
        assert_response :not_found
        get "/users/password/edit", params: { reset_password_token: "token" }
        assert_response :not_found
      end
    end
    assert_not User.exists?(email: "visitor@example.com")
  end

  test "a signed in user cannot cancel the account" do
    sign_in users(:outsider)

    delete "/users"

    assert_response :not_found
    assert User.exists?(users(:outsider).id)
  end

  test "no page links to sign-up or password reset, in either mode" do
    [true, false].each do |demo|
      with_demo_mode(demo) do
        [root_path, new_user_session_path].each do |path|
          get path

          assert_select "a[href*=sign_up], a[href*=password]", { count: 0 }, "#{path} in demo=#{demo}"
          assert_no_match(/Crear una cuenta|Sign up|Forgot/, response.body)
        end
      end
    end
  end

  test "the account page has the password fields only, with no email field and no cancel button" do
    sign_in users(:outsider)

    get edit_user_registration_path

    assert_response :success
    assert_select "input[name='user[email]']", count: 0
    assert_select "input[name='user[password]']"
    assert_select "input[name='user[password_confirmation]']"
    assert_select "input[name='user[current_password]']"
    assert_select "form[action=?] input[name=_method][value=delete]", user_registration_path, count: 0
  end

  test "a user changes the password with the current password" do
    sign_in users(:outsider)

    patch user_registration_path, params: { user: NEW_PASSWORD.merge(current_password: "123456") }

    assert_redirected_to root_path
    assert users(:outsider).reload.valid_password?("nueva-clave")
  end

  test "a wrong current password changes nothing" do
    sign_in users(:outsider)

    patch user_registration_path, params: { user: NEW_PASSWORD.merge(current_password: "wrong") }

    assert users(:outsider).reload.valid_password?("123456")
  end

  test "an email change is ignored, through the form and through JSON" do
    sign_in users(:outsider)

    patch user_registration_path,
          params: { user: NEW_PASSWORD.merge(email: "changed@tasker.com", current_password: "123456") }
    put "/users", params: { user: { email: "json@tasker.com", current_password: "nueva-clave" } }, as: :json

    assert_equal "outsider@tasker.com", users(:outsider).reload.email
    assert users(:outsider).valid_password?("nueva-clave")
  end
end
