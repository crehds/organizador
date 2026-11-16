require "test_helper"
require "rake"

class DemoTaskTest < ActiveSupport::TestCase
  setup do
    # `bin/rails test` may have loaded the tasks already; loading them twice would run the task twice.
    Rails.application.load_tasks unless Rake::Task.task_defined?("demo:reset")
    # Rake runs a task once per process unless it is re-enabled.
    Rake::Task["demo:reset"].reenable
  end

  test "demo:reset reloads the demo data" do
    visitor = User.create!(email: "visitor@example.com", password: "123456")

    output, = capture_io { Rake::Task["demo:reset"].invoke }

    assert_not User.exists?(visitor.id)
    assert_equal [8, 4, 29], [User.count, Category.count, Task.count]
    assert_match "Demo data has been reset.", output
  end

  test "outside demo mode demo:reset aborts with a clear message and deletes nothing" do
    visitor = User.create!(email: "visitor@example.com", password: "123456")
    before = [User.count, Category.count, Task.count]
    error = nil

    _output, errors = capture_io do
      with_demo_mode(false) { error = assert_raises(SystemExit) { Rake::Task["demo:reset"].invoke } }
    end

    assert_not error.success?
    assert_match "Demo mode is off", errors
    assert_equal before, [User.count, Category.count, Task.count]
    assert User.exists?(visitor.id)
  end
end
