require "test_helper"

class TaskFormTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:johan)
  end

  test "the category select is marked as required" do
    get new_task_path

    assert_select "select#task_category_id[required]"
    assert_select "label[for=task_category_id] abbr[title=obligatorio]", text: "*"
  end

  test "a task without a category is rejected" do
    params = {
      name: "No category", description: "d", due_date: Date.current + 3, category_id: "",
      participating_users_attributes: { "0" => { user_id: users(:juan).id, role: "responsable" } }
    }

    assert_no_difference -> { Task.count } do
      post tasks_path, params: { task: params }
    end

    assert_response :unprocessable_entity
  end

  test "the role select offers the enum roles and keeps the saved role" do
    task = create_task
    task.participating_users.first.update!(role: :follower)

    get edit_task_path(task)

    assert_select "select#task_participating_users_attributes_0_role option[value=responsable]"
    assert_select "select#task_participating_users_attributes_0_role option[selected][value=follower]"
  end
end
