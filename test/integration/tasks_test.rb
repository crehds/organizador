require "test_helper"

class TasksTest < ActionDispatch::IntegrationTest
  setup do
    @task = create_task
  end

  test "lists the tasks the user owns" do
    sign_in users(:johan)

    get tasks_path

    assert_response :success
    assert_includes response.body, @task.name
  end

  test "lists the tasks the user participates in" do
    sign_in users(:juan)

    get tasks_path

    assert_response :success
    assert_includes response.body, @task.name
  end

  test "hides tasks the user has nothing to do with" do
    sign_in users(:outsider)

    get tasks_path

    assert_response :success
    assert_not_includes response.body, @task.name
  end

  test "creates a task with a participant" do
    sign_in users(:johan)

    assert_difference -> { Task.count } => 1, -> { Participant.count } => 1 do
      post tasks_path, params: { task: task_params }
    end

    task = Task.find_by!(name: "Deploy to Railway")
    assert_redirected_to task_url(task)
    assert_equal users(:johan), task.owner
    assert_equal [users(:juan)], task.participants.to_a
    assert task.code.present?
  end

  test "rejects a task without participants" do
    sign_in users(:johan)

    assert_no_difference -> { Task.count } do
      post tasks_path, params: { task: task_params.except(:participating_users_attributes) }
    end

    assert_response :unprocessable_entity
  end

  test "rejects a due date that is not in the future" do
    sign_in users(:johan)

    assert_no_difference -> { Task.count } do
      post tasks_path, params: { task: task_params(due_date: Date.current) }
    end

    assert_response :unprocessable_entity
  end

  test "rejects the same participant twice" do
    sign_in users(:johan)
    participant = { user_id: users(:juan).id, role: "responsable" }

    assert_no_difference -> { Task.count } do
      post tasks_path, params: { task: task_params(participating_users_attributes: { "0" => participant, "1" => participant }) }
    end

    assert_redirected_to new_task_path
    assert_equal "participants cant be repeated in the same task", flash[:alert]
  end

  test "the owner edits a task" do
    sign_in users(:johan)

    get edit_task_path(@task)
    assert_response :success

    patch task_path(@task), params: { task: { name: "Renamed" } }
    assert_redirected_to task_url(@task)
    assert_equal "Renamed", @task.reload.name
  end

  test "a participant can see a task but not change it" do
    sign_in users(:juan)

    get task_path(@task)
    assert_response :success

    patch task_path(@task), params: { task: { name: "Renamed" } }
    assert_redirected_to root_path
    assert_equal "Tarea #1", @task.reload.name
  end

  test "an outsider cannot see a task" do
    sign_in users(:outsider)

    get task_path(@task)

    assert_redirected_to root_path
  end

  private

  def task_params(**overrides)
    {
      name: "Deploy to Railway",
      description: "Put the app online",
      due_date: Date.current + 7,
      category_id: categories(:desarrollo).id,
      participating_users_attributes: { "0" => { user_id: users(:juan).id, role: "responsable" } }
    }.merge(overrides)
  end
end
