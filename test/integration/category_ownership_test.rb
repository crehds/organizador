require "test_helper"

# Demo visitors share one database, so in demo mode each user reaches only their own categories.
# A private installation keeps sharing every category.
class CategoryOwnershipTest < ActionDispatch::IntegrationTest
  setup do
    @ana = User.create!(email: "ana@example.com", password: "123456")
    @beto = User.create!(email: "beto@example.com", password: "123456")
    @ana_category = Category.create!(name: "desarrollo", description: "Ana", user: @ana)
    @beto_category = Category.create!(name: "desarrollo", description: "Beto", user: @beto)
    sign_in @ana
  end

  test "in demo mode the list shows only the user's own categories, in HTML and JSON" do
    get categories_path

    assert_response :success
    assert_includes response.body, "Ana"
    assert_not_includes response.body, "Beto"
    assert_not_includes response.body, categories(:unused).name

    get categories_path(format: :json)

    assert_equal [@ana_category.id], response.parsed_body.pluck("id")
  end

  test "in demo mode another user's category answers not found to show, edit, update and destroy" do
    requests = [
      [:get, category_path(@beto_category)], [:get, category_path(@beto_category, format: :json)],
      [:get, edit_category_path(@beto_category)],
      [:patch, category_path(@beto_category), { category: { name: "robada" } }],
      [:patch, category_path(@beto_category, format: :json), { category: { name: "robada" } }],
      [:delete, category_path(@beto_category)], [:delete, category_path(@beto_category, format: :json)]
    ]

    requests.each do |verb, path, params|
      # A not found error skips saving the session, so each request signs in again.
      sign_in @ana
      send(verb, path, params:)

      assert_response :not_found, "#{verb} #{path}"
    end
    assert_equal %w[desarrollo Beto], @beto_category.reload.values_at(:name, :description)
  end

  test "in demo mode a new category belongs to its creator, and names repeat only across owners" do
    assert_difference -> { @ana.categories.count } => 1 do
      post categories_path, params: { category: { name: "mercadeo", description: "--" } }
    end
    assert_redirected_to category_url(@ana.categories.find_by!(name: "mercadeo"))

    assert_no_difference -> { Category.count } do
      post categories_path, params: { category: { name: "DESARROLLO", description: "--" } }
    end
    assert_response :unprocessable_entity
  end

  test "in demo mode a task cannot point to another user's category, through the form or JSON" do
    task = create_task(owner: @ana, category: @ana_category)

    assert_no_difference -> { Task.count } do
      post tasks_path, params: { task: task_params(category_id: @beto_category.id) }
      assert_response :unprocessable_entity
      post tasks_path, params: { task: task_params(category_id: @beto_category.id) }, as: :json
      assert_response :unprocessable_entity
      assert response.parsed_body["category"].present?
    end

    patch task_path(task), params: { task: { category_id: @beto_category.id } }
    assert_response :unprocessable_entity
    patch task_path(task), params: { task: { category_id: @beto_category.id } }, as: :json
    assert_response :unprocessable_entity
    assert_equal @ana_category, task.reload.category
  end

  test "in demo mode the task form offers only the user's own categories" do
    get new_task_path

    assert_select "select#task_category_id option[value=?]", @ana_category.id.to_s
    assert_select "select#task_category_id option[value=?]", @beto_category.id.to_s, count: 0
    assert_select "select#task_category_id option[value=?]", categories(:desarrollo).id.to_s, count: 0
  end

  test "in demo mode a task with the user's own category is created" do
    assert_difference -> { Task.count } => 1 do
      post tasks_path, params: { task: task_params(category_id: @ana_category.id) }
    end

    assert_equal @ana_category, Task.find_by!(name: "Deploy to Railway").category
  end

  test "in a private installation every user sees, edits and uses every category" do
    with_demo_mode(false) do
      sign_in @beto
      post categories_path, params: { category: { name: "diseño", description: "--" } }
      shared = Category.find_by!(name: "diseño")
      sign_in @ana

      get categories_path
      assert_includes response.body, "diseño"
      assert_includes response.body, categories(:desarrollo).name
      patch category_path(shared), params: { category: { description: "compartida" } }
      assert_redirected_to category_url(shared)
      assert_difference -> { Task.count } => 1 do
        post tasks_path, params: { task: task_params(category_id: shared.id) }
      end
      get new_task_path
      assert_select "select#task_category_id option[value=?]", shared.id.to_s

      assert_nil shared.reload.user
      assert_equal "compartida", shared.description
    end
  end

  private

  def task_params(**overrides)
    {
      name: "Deploy to Railway", description: "Put the app online", due_date: Date.current + 7,
      participating_users_attributes: { "0" => { user_id: users(:juan).id, role: "responsable" } }
    }.merge(overrides)
  end
end
