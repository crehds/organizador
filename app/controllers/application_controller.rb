class ApplicationController < ActionController::Base
  include Language

  before_action :authenticate_user!
  before_action :turbo_frame_request_variant

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

  # The demo banner's "Crear mi cuenta" asks for the sign up page; any other value keeps Devise's default,
  # so sign out never redirects to a URL taken from the request.
  def after_sign_out_path_for(scope)
    params[:next] == "sign_up" ? new_user_registration_path : super
  end
end
