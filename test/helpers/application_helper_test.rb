require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "the avatar shows the first two letters of the email in uppercase" do
    assert_equal "JU", avatar("juan@tasker.com").text
  end

  test "the avatar is a circle of the given size" do
    assert_includes avatar("juan@tasker.com", size: 38)["style"], "--avatar-size: 38px"
    assert_includes avatar("juan@tasker.com")["style"], "--avatar-size: 60px"
  end

  test "the same email always gets the same color" do
    assert_equal hue("juan@tasker.com"), hue("juan@tasker.com")
  end

  test "different emails can get different colors" do
    hues = %w[johan@tasker.com juan@tasker.com outsider@tasker.com ana@example.com].map { |email| hue(email) }

    assert_operator hues.uniq.size, :>, 1
  end

  test "the avatar names the user for assistive technology" do
    span = avatar("juan@tasker.com")

    assert_equal "img", span["role"]
    assert_equal "juan@tasker.com", span["aria-label"]
    assert_equal "juan@tasker.com", span["title"]
  end

  private

  def avatar(email, **)
    Nokogiri::HTML5.fragment(avatar_for(User.new(email:), **)).at_css("span")
  end

  def hue(email)
    avatar(email)["style"][/--avatar-hue: (\d+)/, 1]
  end
end
