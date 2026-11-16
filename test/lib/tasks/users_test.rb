require "test_helper"
require "rake"

# There is no public sign-up: accounts are created with `bin/rails users:create EMAIL=...`.
class UsersTaskTest < ActionDispatch::IntegrationTest
  setup do
    # `bin/rails test` may have loaded the tasks already; loading them twice would run the task twice.
    Rails.application.load_tasks unless Rake::Task.task_defined?("users:create")
    @previous_email = ENV.fetch("EMAIL", nil)
  end

  teardown do
    ENV["EMAIL"] = @previous_email
  end

  test "outside demo mode it creates the user and prints the email and a random password once, which signs in" do
    output, = with_demo_mode(false) { create_user("nueva@example.com") }
    password = output[/^Password: (\S+)$/, 1]

    assert_match "nueva@example.com", output
    assert_operator password.length, :>=, 16
    assert_equal 1, output.scan(password).size
    post user_session_path, params: { user: { email: "nueva@example.com", password: } }
    get tasks_path
    assert_response :success
  end

  test "in demo mode it creates users too, each with its own password" do
    first, = create_user("uno@example.com")
    second, = create_user("dos@example.com")
    passwords = [first, second].map { |output| output[/^Password: (\S+)$/, 1] }

    assert User.find_by(email: "uno@example.com").valid_password?(passwords.first)
    assert User.find_by(email: "dos@example.com").valid_password?(passwords.second)
    assert_not_equal passwords.first, passwords.second
  end

  test "a missing, invalid or taken email fails with a clear message and creates nothing" do
    { nil => "Email can't be blank", "" => "Email can't be blank", "not-an-email" => "Email is invalid",
      " JOHAN@Tasker.com " => "Email has already been taken" }.each do |email, message|
      error = nil
      output, errors = capture_io do
        assert_no_difference("User.count") { error = assert_raises(SystemExit) { create_user(email, capture: false) } }
      end

      assert_not error.success?, email.inspect
      assert_match message, errors
      assert_match "bin/rails users:create EMAIL=", errors
      assert_empty output
    end
  end

  private

  def create_user(email, capture: true)
    ENV["EMAIL"] = email
    # Rake runs a task once per process unless it is re-enabled.
    Rake::Task["users:create"].reenable
    capture ? capture_io { Rake::Task["users:create"].invoke } : Rake::Task["users:create"].invoke
  end
end
