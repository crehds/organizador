class ApplicationController < ActionController::Base
  before_action :set_locale

  before_action :authenticate_user!

  def set_locale
    I18n.locale = "es"
  end

  rescue_from ActiveRecord::RecordNotUnique do |_exception|
    flash[:alert] = "participants cant be repeated in the same task"
    redirect_to new_task_path
  end
end
