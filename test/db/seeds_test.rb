require "test_helper"

# db:prepare loads db/seeds.rb on a new database, so the seeds decide what a new installation starts with.
class SeedsTest < ActiveSupport::TestCase
  setup do
    [Note, Participant, Task, Category, User].each(&:delete_all)
  end

  test "in demo mode the seeds load the demo data" do
    capture_io { Rails.application.load_seed }

    assert_equal [8, 4, 29], [User.count, Category.count, Task.count]
    assert User.exists?(email: User::DEMO_EMAIL)
  end

  test "outside demo mode the seeds create nothing and print one line saying why" do
    output, = capture_io { with_demo_mode(false) { Rails.application.load_seed } }

    assert_equal [0, 0, 0, 0], [User.count, Category.count, Task.count, Participant.count]
    assert_equal "Demo mode is off (DEMO_MODE is not \"true\"), so no demo data was loaded.\n", output
  end
end
