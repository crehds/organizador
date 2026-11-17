require "test_helper"

class AccountHardeningTest < ActionDispatch::IntegrationTest
  NEW_PASSWORD = "otra-clave-larga".freeze

  test "signed-in users also get 404 on sign-up, cancel and password routes, in both modes" do
    sign_in users(:juan)

    [true, false].each do |demo|
      with_demo_mode(demo) do
        [[:get, "/users/sign_up"], [:get, "/users/cancel"], [:get, "/users/password/new"],
         [:post, "/users/password"], [:post, "/users"], [:delete, "/users"]].each do |verb, path|
          send(verb, path, params: { user: { email: "x@example.com" } }, as: (:json unless verb == :get))

          assert_equal 404, response.status, "#{verb} #{path} demo=#{demo}"
        end
      end
    end
    assert User.exists?(users(:juan).id)
  end

  test "extra attributes, a missing current password or a bad confirmation change nothing" do
    with_demo_mode(false) do
      user = users(:outsider)
      sign_in user
      before = user.attributes.except("updated_at", "encrypted_password")
      evil = { email: "evil@x.com", id: 999, encrypted_password: "x", created_at: "2000-01-01",
               reset_password_token: "t" }

      patch "/users", params: { user: evil.merge(current_password: "123456") }
      put "/users", params: { user: evil.merge(current_password: "123456") }, as: :json
      patch "/users", params: { user: { password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD } }
      patch "/users",
            params: { user: { password: NEW_PASSWORD, password_confirmation: "other", current_password: "123456" } }

      assert_equal before, user.reload.attributes.except("updated_at", "encrypted_password")
      assert user.valid_password?("123456")
    end
  end

  test "a visitor cannot change the password through JSON either" do
    visitor = create_visitor
    sign_in visitor

    put "/users",
        params: { user: { password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD, current_password: "123456" } },
        as: :json

    assert visitor.reload.valid_password?("123456")
  end

  test "a password update without a CSRF token is rejected" do
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    with_demo_mode(false) do
      sign_in users(:outsider)
      get "/users/edit"

      assert_select "form[action='/users'] input[name=authenticity_token]"

      patch "/users", params: { user: { password: NEW_PASSWORD, password_confirmation: NEW_PASSWORD,
                                        current_password: "123456" } }

      assert_response :unprocessable_entity
      assert users(:outsider).reload.valid_password?("123456")
    end
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end
end
