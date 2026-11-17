require "test_helper"

# In demo mode a task may only add the fictitious teammates, never another visitor; a private installation offers
# every other user.
class ParticipantChoicesTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email: "ana@example.com", password: "123456")
    @category = Category.create!(name: "propia", description: "--", user: @owner)
    @task = create_task(owner: @owner, category: @category, participant: users(:juan))
    @other_visitor = User.create!(email: "otro@#{User::VISITOR_DOMAIN}", password: "123456")
    sign_in @owner
  end

  test "in demo mode the picker lists only the teammates" do
    get edit_task_path(@task)

    assert_response :success
    assert_equal [users(:juan).id.to_s], participant_options
  end

  test "in a private installation the picker lists every other user" do
    with_demo_mode(false) { get edit_task_path(@task) }

    assert_response :success
    assert_equal User.where.not(id: @owner.id).ids.map(&:to_s).sort, participant_options.sort
  end

  test "in demo mode a crafted request cannot add another visitor, through the form or JSON" do
    crafted = { "0" => { user_id: @other_visitor.id, role: "responsable" } }

    assert_no_difference -> { Participant.count } do
      post tasks_path, params: { task: task_params(participating_users_attributes: crafted) }
      assert_response :unprocessable_entity
      post tasks_path, params: { task: task_params(participating_users_attributes: crafted.values) }, as: :json
      assert_response :unprocessable_entity
      patch task_path(@task), params: { task: { participating_users_attributes: crafted } }
      assert_response :unprocessable_entity
      existing = { id: @task.participating_users.first.id, user_id: @other_visitor.id }
      patch task_path(@task), params: { task: { participating_users_attributes: [existing] } }, as: :json
      assert_response :unprocessable_entity
    end

    assert_equal [users(:juan)], @task.reload.participants.to_a
  end

  test "in demo mode a teammate is added" do
    assert_difference -> { Task.count } => 1 do
      post tasks_path, params: { task: task_params }
    end

    assert_equal [users(:juan)], Task.find_by!(name: "Deploy to Railway").participants.to_a
  end

  test "in a private installation any other user is added" do
    with_demo_mode(false) do
      assert_difference -> { Task.count } => 1 do
        post tasks_path, params: { task: task_params(participating_users_attributes: {
                                                       "0" => { user_id: @other_visitor.id, role: "follower" }
                                                     }) }
      end
    end

    assert_equal [@other_visitor], Task.find_by!(name: "Deploy to Railway").participants.to_a
  end

  private

  def participant_options
    css_select("select#task_participating_users_attributes_0_user_id option").pluck("value").compact_blank
  end

  def task_params(**overrides)
    {
      name: "Deploy to Railway", description: "Put the app online", due_date: Date.current + 7,
      category_id: @category.id,
      participating_users_attributes: { "0" => { user_id: users(:juan).id, role: "responsable" } }
    }.merge(overrides)
  end
end
