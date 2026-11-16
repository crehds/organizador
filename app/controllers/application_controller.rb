class ApplicationController < ActionController::Base
  include Language

  before_action :authenticate_user!
  before_action :turbo_frame_request_variant
  helper_method :demo_mode?

  rescue_from CanCan::AccessDenied do |_exception|
    redirect_to root_path
  end

  def turbo_frame_request_variant
    request.variant = :turbo_frame if turbo_frame_request?
  end

  rescue_from ActiveRecord::RecordNotUnique do |_exception|
    flash[:alert] = "participants cant be repeated in the same task"
    redirect_to new_task_path
  end

  private

  # Read on every request, not when the routes are drawn, so tests can switch it.
  def demo_mode?
    Rails.configuration.x.demo_mode
  end
end
