class Users::TestsController < ApplicationController
  skip_before_action :authenticate_user!

  def new
    user = User.find_by(email: User::DEMO_EMAIL)
    return redirect_to new_user_session_path, alert: "The demo is not available right now." unless user

    sign_in user
    redirect_to tasks_path
  end
end
