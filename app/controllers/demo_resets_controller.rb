# POST /demo/reset with "Authorization: Bearer <DEMO_RESET_TOKEN>" restores the demo data.
# Without DEMO_RESET_TOKEN the endpoint answers 404, as if it did not exist.
class DemoResetsController < ActionController::API
  def create
    expected = ENV.fetch("DEMO_RESET_TOKEN", nil)
    return head :not_found if expected.blank?
    return head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(bearer_token, expected)

    DemoReset.call
    head :no_content
  end

  private

  def bearer_token
    request.authorization.to_s[/\ABearer (.+)\z/i, 1].to_s
  end
end
