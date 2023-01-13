class Users::TestsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    user = User.find_by(email: "johan@tasker.com")
    sign_in user
    redirect_to tasks_path
  end
end
