require "test_helper"

# Production serves only fingerprinted assets, so the stylesheet must point at the fingerprinted icon fonts.
class IconFontsTest < ActionDispatch::IntegrationTest
  test "the stylesheet loads Font Awesome's solid font from a fingerprinted asset" do
    css = Rails.application.assets["application.css"].to_s
    fonts = css.scan(/url\(["']?([^"')]*fa-solid-900[^"')]*)["']?\)/).flatten

    assert_not_empty fonts
    fonts.each do |font|
      assert_match %r{\A/assets/fa-solid-900-\h+\.(woff2|ttf)\z}, font

      get font

      assert_response :success, font
    end
  end
end
