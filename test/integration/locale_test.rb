require "test_helper"

class LocaleTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:johan)
    @task = create_task
  end

  test "uses the browser language when the app has it" do
    get tasks_path, headers: { "Accept-Language" => "es-AR,es;q=0.9" }

    assert_response :success
    assert_includes response.body, I18n.l(@task.created_at, format: :long, locale: :es)
  end

  test "falls back to the default language for unsupported browser languages" do
    get tasks_path, headers: { "Accept-Language" => "zh-CN,zh;q=0.9" }

    assert_response :success
    assert_includes response.body, I18n.l(@task.created_at, format: :long, locale: :en)
  end
end
