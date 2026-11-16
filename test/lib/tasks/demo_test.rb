require "test_helper"
require "rake"

class DemoTaskTest < ActiveSupport::TestCase
  setup do
    # `bin/rails test` may have loaded the tasks already; loading them twice would run the task twice.
    Rails.application.load_tasks unless Rake::Task.task_defined?("demo:reset")
  end

  test "demo:reset reloads the demo data" do
    visitor = User.create!(email: "visitor@example.com", password: "123456")

    output, = capture_io { Rake::Task["demo:reset"].invoke }

    assert_not User.exists?(visitor.id)
    assert_equal [8, 4, 29], [User.count, Category.count, Task.count]
    assert_match "Demo data has been reset.", output
  end
end
