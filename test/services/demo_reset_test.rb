require "test_helper"
require "minitest/mock"

class DemoResetTest < ActiveSupport::TestCase
  setup do
    @visitor = User.create!(email: "visitor@example.com", password: "123456")
    @category = Category.create!(name: "visitas", description: "--")
    @task = create_task(name: "Tarea de visita", owner: @visitor)
    @task.notes.create!(user: @visitor, body: "Hola")
  end

  test "deletes what visitors left and reloads the demo data" do
    capture_io { DemoReset.call }

    assert_not User.exists?(@visitor.id)
    assert_not Category.exists?(@category.id)
    assert_not Task.exists?(@task.id)
    assert_equal 0, Note.count
    assert_equal [8, 4, 29], [User.count, Category.count, Task.count]
    assert User.exists?(email: "johan@tasker.com")
  end

  test "a failing seed leaves the data as it was" do
    before = [User.count, Category.count, Task.count, Participant.count, Note.count]

    Rails.application.stub(:load_seed, -> { raise "seed failed" }) do
      assert_raises(RuntimeError) { DemoReset.call }
    end

    assert_equal before, [User.count, Category.count, Task.count, Participant.count, Note.count]
  end
end
