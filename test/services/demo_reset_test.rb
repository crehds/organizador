require "test_helper"
require "minitest/mock"

class DemoResetTest < ActiveSupport::TestCase
  setup do
    @visitor = User.create!(email: "visitor@example.com", password: "123456")
    @category = Category.create!(name: "visitas", description: "--")
    @task = create_task(name: "Tarea de visita", owner: @visitor)
    @task.notes.create!(user: @visitor, body: "Hola")
  end

  test "deletes what visitors left and reloads only the teammates" do
    capture_io { DemoReset.call }

    assert_not User.exists?(@visitor.id)
    assert_not Category.exists?(@category.id)
    assert_not Task.exists?(@task.id)
    assert_equal 0, Note.count
    assert_equal [7, 0, 0], [User.count, Category.count, Task.count]
    assert_equal User::TEAMMATE_EMAILS.sort, User.pluck(:email).sort
  end

  test "outside demo mode it refuses before deleting anything" do
    before = [User.count, Category.count, Task.count, Participant.count, Note.count]

    with_demo_mode(false) do
      error = assert_raises(DemoReset::Disabled) { DemoReset.call }
      assert_match "DEMO_MODE", error.message
    end

    assert_equal before, [User.count, Category.count, Task.count, Participant.count, Note.count]
    assert User.exists?(@visitor.id)
  end

  test "a failing seed leaves the data as it was" do
    before = [User.count, Category.count, Task.count, Participant.count, Note.count]

    Rails.application.stub(:load_seed, -> { raise "seed failed" }) do
      assert_raises(RuntimeError) { DemoReset.call }
    end

    assert_equal before, [User.count, Category.count, Task.count, Participant.count, Note.count]
  end

  test "a failure in the middle of the seed file leaves every row as it was" do
    rows = lambda do
      [User.order(:id).pluck(:id, :email, :encrypted_password), Category.order(:id).pluck(:id, :name),
       Task.order(:id).pluck(:id, :name), Note.order(:id).pluck(:id)]
    end
    before = rows.call
    calls = 0
    original = User.method(:find_or_initialize_by)
    failing = lambda do |*args, **kwargs, &block|
      calls += 1
      raise "seed failed at teammate #{calls}" if calls == 4

      original.call(*args, **kwargs, &block)
    end

    User.stub(:find_or_initialize_by, failing) { assert_raises(RuntimeError) { capture_io { DemoReset.call } } }

    assert_equal before, rows.call
    assert_not User.exists?(email: "andrea@tasker.com")
  end
end
