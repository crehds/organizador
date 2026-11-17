require "test_helper"

# The interface is written only in Spanish, so dates and labels stay Spanish whatever the browser asks for.
class LocaleTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:johan)
    @task = create_task
  end

  test "dates and labels are Spanish for every browser language" do
    ["es-AR,es;q=0.9", "en-US,en;q=0.9", "zh-CN,zh;q=0.9", "", "*", "x-klingon"].each do |value|
      get tasks_path, headers: { "Accept-Language" => value }

      assert_response :success, "Accept-Language #{value.inspect}"
      assert_includes response.body, I18n.l(@task.due_date, format: :long, locale: :es), "Accept-Language #{value.inspect}"
      assert_select "a.dropdown-item", text: "Editar"
    end
  end

  test "flash messages are Spanish too" do
    patch task_path(@task), params: { task: { name: "Renamed" } }, headers: { "Accept-Language" => "en-US" }

    assert_equal "Tarea actualizada.", flash[:notice]
  end
end
