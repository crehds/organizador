require "test_helper"

class PageLanguageTest < ActionDispatch::IntegrationTest
  test "pages declare Spanish, the language of their copy" do
    get root_path

    assert_select "html[lang=es]"
  end

  test "the navbar avatar is hidden from screen readers because the email is shown next to it" do
    sign_in users(:juan)

    get tasks_path

    assert_select "nav [aria-hidden=true] .user-avatar"
    assert_select "nav .navbar-text", text: "juan@tasker.com"
  end
end
