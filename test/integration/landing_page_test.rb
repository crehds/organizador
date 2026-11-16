require "test_helper"

# Guests land on a page that explains the project instead of Devise's "sign in first" message.
class LandingPageTest < ActionDispatch::IntegrationTest
  test "guests get the landing page at the root" do
    get root_path

    assert_response :success
    assert_select "a[href=?]", "/test", text: "Probar el demo"
    assert_select "a[href=?]", new_user_session_path
    assert_select ".landing-page a", count: 2
  end

  test "signed in users get their task list at the root" do
    task = create_task
    sign_in users(:juan)

    get root_path

    assert_response :success
    assert_select ".tasks.index-page"
    assert_includes response.body, task.name
  end

  test "the landing page shows no user data and no signed-in chrome" do
    task = create_task(name: "Secreto de juan")

    get root_path

    assert_not_includes response.body, task.name
    User.pluck(:email).each { |email| assert_not_includes response.body, email }
    assert_select "nav.navbar", count: 0
    assert_select "form", count: 0
  end
end
