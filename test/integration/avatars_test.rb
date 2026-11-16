require "test_helper"

# Avatars are drawn by the app, so pages make no requests to an external image service.
class AvatarsTest < ActionDispatch::IntegrationTest
  setup do
    @task = create_task
    @task.notes.create!(user: users(:johan), body: "Hola")
    sign_in users(:johan)
  end

  test "the task list shows local avatars" do
    get tasks_path

    assert_select ".task-participant [role=img][aria-label=?]", "juan@tasker.com", text: "JU"
    assert_select "nav [role=img][aria-label=?]", "johan@tasker.com", text: "JO"
    assert_not_includes response.body, "robohash"
  end

  test "the task page shows local avatars for participants and notes" do
    get task_path(@task)

    assert_select ".task-participant [role=img][aria-label=?]", "juan@tasker.com", text: "JU"
    assert_select ".note-element [role=img][aria-label=?]", "johan@tasker.com", text: "JO"
    assert_not_includes response.body, "robohash"
  end
end
