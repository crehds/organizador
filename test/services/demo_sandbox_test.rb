require "test_helper"
require "minitest/mock"

class DemoSandboxServiceTest < ActiveSupport::TestCase
  setup do
    capture_io { Rails.application.load_seed }
  end

  test "each new visitor deletes visitors older than 24 hours with all their data, and keeps everyone else" do
    old_visitor = travel_to(25.hours.ago) { DemoSandbox.call }
    old_task = Task.where(owner: old_visitor).first
    old_task.notes.create!(user: old_visitor, body: "Hola")
    young_visitor = travel_to(23.hours.ago) { DemoSandbox.call }
    old_member = travel_to(3.days.ago) { User.create!(email: "socio@example.com", password: "123456") }
    old_member_category = Category.create!(name: "suya", description: "--", user: old_member)
    old_member_task = create_task(owner: old_member, category: old_member_category)
    teammates = User.teammates.ids
    User.teammates.each { |teammate| teammate.update!(created_at: 3.days.ago) }

    new_visitor = DemoSandbox.call

    assert_not User.exists?(old_visitor.id)
    assert_equal [0, 0, 0, 0], [Category.where(user: old_visitor).count, Task.where(owner: old_visitor).count,
                                Participant.where(task_id: old_task.id).count, Note.where(user: old_visitor).count]
    assert_equal [young_visitor, new_visitor].map(&:id).sort, User.visitors.ids.sort
    assert_equal [4, 29], [young_visitor.categories.count, Task.where(owner: young_visitor).count]
    assert_equal teammates.sort, User.teammates.ids.sort
    assert User.exists?(old_member.id)
    assert Task.exists?(old_member_task.id)
    assert Category.exists?(old_member_category.id)
    assert User.exists?(users(:johan).id)
  end

  test "outside demo mode it refuses before deleting or creating anything" do
    old_visitor = travel_to(25.hours.ago) { DemoSandbox.call }
    before = [User.count, Category.count, Task.count, Participant.count]

    with_demo_mode(false) do
      error = assert_raises(DemoSandbox::Disabled) { DemoSandbox.call }
      assert_match "DEMO_MODE", error.message
    end

    assert_equal before, [User.count, Category.count, Task.count, Participant.count]
    assert User.exists?(old_visitor.id)
  end

  test "a failure while copying the sample data leaves no half-made visitor" do
    before = [User.count, Category.count, Task.count, Participant.count]

    Task.stub(:create!, ->(*) { raise ActiveRecord::RecordInvalid }) do
      assert_raises(ActiveRecord::RecordInvalid) { DemoSandbox.call }
    end

    assert_equal before, [User.count, Category.count, Task.count, Participant.count]
  end
end
