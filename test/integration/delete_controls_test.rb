require "test_helper"

# Turbo ignores `method: :delete` links, so delete controls must be forms that send `_method=delete`.
class DeleteControlsTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:johan)
  end

  test "deleting a task asks for confirmation and sends a DELETE" do
    task = create_task

    get tasks_path

    assert_select "form[action=?][data-turbo-confirm] input[name=_method][value=delete]", task_path(task)
  end

  test "deleting a category asks for confirmation and sends a DELETE" do
    get categories_path

    assert_select "form[action=?][data-turbo-confirm] input[name=_method][value=delete]",
                  category_path(categories(:desarrollo))
  end

  test "signing out sends a DELETE" do
    get tasks_path

    assert_select "form[action=?] input[name=_method][value=delete]", destroy_user_session_path
  end

  test "cancelling the account asks for confirmation and sends a DELETE" do
    get edit_user_registration_path

    assert_select "form[action=?][data-turbo-confirm] input[name=_method][value=delete]", user_registration_path
  end
end
