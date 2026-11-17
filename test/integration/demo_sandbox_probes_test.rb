require "test_helper"
require "minitest/mock"

# Regression tests from the independent verification and the review of the one-click demo.
class DemoSandboxProbesTest < ActionDispatch::IntegrationTest # rubocop:disable Metrics/ClassLength
  setup do
    Users::TestsController::RATE_LIMIT_STORE.clear
    capture_io { Rails.application.load_seed }
  end

  def with_forgery_protection
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end

  test "outside demo mode POST /test answers 404 even with forgery protection on" do
    with_forgery_protection do
      with_demo_mode(false) do
        assert_no_difference(-> { User.count }) { post "/test" }
        assert_response :not_found
      end
    end
  end

  test "POST /test needs the token from the sign-in page" do
    with_forgery_protection do
      assert_no_difference(-> { User.count }) { post "/test" }
      get "/"
      token = css_select("form[action='/test'] input[name=authenticity_token]").first["value"]

      assert_difference(-> { User.visitors.count } => 1) { post "/test", params: { authenticity_token: token } }
    end
  end

  test "a single-hash participant naming another visitor answers 422 and changes nothing" do
    other = DemoSandbox.call
    me = DemoSandbox.call
    sign_in me
    task = Task.where(owner: me).first
    participant = task.participating_users.first

    attributes = { id: participant.id, user_id: other.id }
    patch "/tasks/#{task.id}.json", as: :json, params: { task: { participating_users_attributes: attributes } }

    assert_response :unprocessable_entity
    assert_not_equal other.id, participant.reload.user_id
  end

  test "a single-hash participant with a teammate still updates the role" do
    me = DemoSandbox.call
    sign_in me
    participant = Task.where(owner: me).first.participating_users.follower.first

    attributes = { id: participant.id, role: "responsable" }
    patch "/tasks/#{participant.task_id}.json", as: :json,
                                                params: { task: { participating_users_attributes: attributes } }

    assert_response :success
    assert_predicate participant.reload, :responsable?
  end

  test "another visitor's category is not found on every action, HTML and JSON" do
    owner = DemoSandbox.call
    visitor = DemoSandbox.call
    category = owner.categories.first
    before = category.attributes
    path = "/categories/#{category.id}"
    requests = [[:get, path, {}], [:get, "#{path}.json", {}], [:get, "#{path}/edit", {}],
                [:patch, path, { params: { category: { name: "x" } } }],
                [:patch, "#{path}.json", { params: { category: { name: "x" } }, as: :json }],
                [:delete, path, {}], [:delete, "#{path}.json", {}]]

    statuses = requests.map do |verb, url, options|
      # A 404 does not commit the session cookie in integration tests, so each request signs in again.
      sign_in visitor
      send(verb, url, **options)
      response.status
    end

    assert_equal [404] * 7, statuses
    assert_equal before, category.reload.attributes
  end

  test "a participant id from another visitor's task is not found and stays as it was" do
    owner = DemoSandbox.call
    me = DemoSandbox.call
    sign_in me
    mine = Task.where(owner: me).first
    theirs = Task.where(owner:).first.participating_users.first
    before = theirs.attributes

    patch "/tasks/#{mine.id}",
          params: { task: { participating_users_attributes: { "0" => { id: theirs.id, _destroy: "1" } } } }

    assert_response :not_found
    assert_equal before, theirs.reload.attributes
  end

  test "a failed cleanup is logged and the new visitor still gets an account" do
    failing_cleanup = -> { raise ActiveRecord::InvalidForeignKey, "a row still points at an expired visitor" }
    logged = StringIO.new
    previous_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(logged)

    DemoSandbox.stub(:delete_expired_visitors, failing_cleanup) do
      assert_difference(-> { User.visitors.count } => 1) { post "/test" }
    end

    assert_redirected_to tasks_path
    assert_match "a row still points at an expired visitor", logged.string
  ensure
    Rails.logger = previous_logger
  end

  test "the demo reset also removes the accounts and categories the sandbox created" do
    visitor = DemoSandbox.call

    capture_io { DemoReset.call }

    assert_not User.exists?(visitor.id)
    assert_equal 0, User.visitors.count
    assert_equal [0, 0], [Category.count, Task.count]
    assert_equal User::TEAMMATE_EMAILS.sort, User.pluck(:email).sort
  end

  test "cleanup removes visitors just past 24 hours and keeps those just under" do
    past = DemoSandbox.call
    under = DemoSandbox.call
    past.update!(created_at: 24.hours.ago - 60)
    under.update!(created_at: 24.hours.ago + 60)
    Note.create!(task: Task.where(owner: past).first, user: under, body: "on an expired task")

    DemoSandbox.call

    assert_not User.exists?(past.id)
    assert_equal [29, 4], [Task.where(owner: under).count, under.categories.count]
    assert_equal 0, Note.where(user: under).count
  end
end
