# POST /demo/reset with "Authorization: Bearer <DEMO_RESET_TOKEN>" restores the demo data.
# Outside demo mode, or without DEMO_RESET_TOKEN, it raises RoutingError, so it answers exactly like a missing route.
class DemoResetsController < ActionController::API
  def create
    expected = ENV.fetch("DEMO_RESET_TOKEN", nil)
    raise ActionController::RoutingError, "Not Found" if !Rails.configuration.x.demo_mode || expected.blank?
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(bearer_token, expected)

    DemoReset.call
    head :no_content
  end

  private

  def bearer_token
    request.authorization.to_s[/\ABearer (.+)\z/i, 1].to_s
  end
end
