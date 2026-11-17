require "test_helper"

class TaskPagesTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:johan)
    @task = create_task
  end

  test "each task's actions menu has its own accessible button" do
    create_task(name: "Tarea #2")

    get tasks_path

    assert_select "button[data-bs-toggle=dropdown][aria-label=?]", "Acciones de Tarea #1"
    assert_select "button[data-bs-toggle=dropdown][aria-label=?]", "Acciones de Tarea #2"
    assert_select "#taskMenu", count: 0
  end

  test "the task list shows Spanish dates" do
    get tasks_path

    assert_select ".task-card-meta", text: /Vence el #{I18n.l(@task.due_date, format: :long)}/
  end

  test "the detail page has no wide tables and names each participant's role" do
    get task_path(@task)

    assert_select "table", count: 0
    assert_select ".task-participant--responsable .participant-role", text: "Responsable"
  end

  test "a task without notes still has the list a new note joins" do
    get task_path(@task)

    assert_select "#notes", count: 1
    assert_select ".notes-empty", text: "Todavía no hay notas."
  end

  test "the edit form marks nothing as valid before it is checked and saves with a Spanish button" do
    get edit_task_path(@task)

    assert_select ".is-valid", count: 0
    assert_select "input[type=submit][value=?]", "Guardar cambios"

    get new_task_path

    assert_select "input[type=submit][value=?]", "Crear tarea"
  end

  test "the role select offers Spanish labels" do
    get edit_task_path(@task)

    assert_select "select#task_participating_users_attributes_0_role option[value=follower]", text: "Seguidor"
    assert_select "select#task_participating_users_attributes_0_role option[value=responsable]", text: "Responsable"
  end
end
