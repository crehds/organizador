require "test_helper"

# Guests sign in at the root. Only the demo explains the project there and offers the demo account.
class SignInPageTest < ActionDispatch::IntegrationTest
  test "guests get the sign-in form at the root, with no separate landing page" do
    get root_path

    assert_response :success
    assert_select "form[action=?] input[name=?]", user_session_path, "user[email]"
    assert_select ".landing-page", count: 0
  end

  test "in demo mode the sign-in page explains the project and offers the demo" do
    [root_path, new_user_session_path].each do |path|
      get path

      assert_select "h1", "Organizador"
      assert_select "form[action=?] button", "/test", text: "Probar el demo"
      assert_includes response.body, "cuenta compartida"
      assert_select "form[action=?]", user_session_path
    end
  end

  test "outside demo mode the sign-in page is only the form" do
    with_demo_mode(false) do
      [root_path, new_user_session_path].each do |path|
        get path

        assert_response :success
        assert_select "form[action=?]", user_session_path
        assert_select "h1", count: 0
        assert_select "a[href=?]", "/test", count: 0
        assert_not_includes response.body, "Probar el demo"
        assert_not_includes response.body, "Platzi"
      end
    end
  end

  test "signed in users get their task list at the root" do
    task = create_task
    sign_in users(:juan)

    get root_path

    assert_response :success
    assert_select ".tasks.index-page"
    assert_includes response.body, task.name
  end

  test "the sign-in page at the root shows no user data and no signed-in chrome" do
    task = create_task(name: "Secreto de juan")

    get root_path

    assert_not_includes response.body, task.name
    User.pluck(:email).each { |email| assert_not_includes response.body, email }
    assert_select "nav.navbar", count: 0
  end
end
