require "test_helper"

class ParticipantTest < ActiveSupport::TestCase
  test "roles keep their stored integers" do
    assert_equal({ "responsable" => 1, "follower" => 2 }, Participant.roles)
    assert_equal "responsable", Participant.new(role: 1).role
    assert_equal "follower", Participant.new(role: 2).role
  end
end
