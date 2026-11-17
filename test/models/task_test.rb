require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "task names are unique per owner, ignoring case, in both modes" do
    [true, false].each do |demo|
      with_demo_mode(demo) do
        name = "Bienvenida #{demo}"
        create_task(name:, owner: users(:johan))

        assert create_task(name:, owner: users(:outsider)).persisted?, "demo=#{demo}"
        repeated = Task.new(name: name.upcase, description: "--", category: categories(:desarrollo),
                            owner: users(:johan), participating_users: [Participant.new(user: users(:juan))])
        assert_not repeated.valid?, "demo=#{demo}"
        assert repeated.errors.added?(:name, :taken, value: name.upcase), "demo=#{demo}"
      end
    end
  end
end
