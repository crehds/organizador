require "test_helper"

# db:prepare loads db/seeds.rb on a new database, so the seeds decide what a new installation starts with.
class SeedsTest < ActiveSupport::TestCase
  setup do
    [Note, Participant, Task, Category, User].each(&:delete_all)
  end

  test "in demo mode the seeds create only the teammates, with random passwords nobody knows" do
    capture_io { Rails.application.load_seed }

    assert_equal [7, 0, 0], [User.count, Category.count, Task.count]
    assert_equal User::TEAMMATE_EMAILS.sort, User.pluck(:email).sort
    assert_not User.exists?(email: "johan@tasker.com")
    assert_equal 7, User.distinct.count(:encrypted_password)
    User.find_each { |user| assert_not user.valid_password?("123456"), user.email }
  end

  test "running the seeds again gives existing teammates a new random password" do
    juan = User.create!(email: "juan@tasker.com", password: "123456")

    capture_io { Rails.application.load_seed }

    assert_equal 7, User.count
    assert_not juan.reload.valid_password?("123456")
  end

  test "outside demo mode the seeds create nothing and print one line saying why" do
    output, = capture_io { with_demo_mode(false) { Rails.application.load_seed } }

    assert_equal [0, 0, 0, 0], [User.count, Category.count, Task.count, Participant.count]
    assert_equal "Demo mode is off (DEMO_MODE is not \"true\"), so no demo data was loaded.\n", output
  end
end
