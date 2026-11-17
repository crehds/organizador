require "test_helper"

class TasksTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  setup do
    # In demo mode a task may only use one of its owner's categories.
    categories(:desarrollo).update!(user: users(:johan))
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
    duplicated = { "0" => participant, "1" => participant }

    assert_no_difference -> { Task.count } do
      post tasks_path, params: { task: task_params(participating_users_attributes: duplicated) }
    end

    assert_redirected_to new_task_path
    assert_equal "Un participante no puede repetirse en la misma tarea.", flash[:alert]
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

  test "the owner deletes a task with its participants and notes" do
    sign_in users(:johan)
    @task.notes.create!(user: users(:johan), body: "Done")

    assert_difference -> { Task.count } => -1, -> { Participant.count } => -1, -> { Note.count } => -1 do
      delete task_path(@task)
    end

    assert_redirected_to tasks_url
  end

  test "shows the task code in the page title" do
    sign_in users(:johan)

    get task_path(@task)

    assert_select ".page-header .task-code", text: "Tarea #{@task.code}"
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
