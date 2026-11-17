class TasksController < ApplicationController
  load_and_authorize_resource
  before_action :set_task, only: %i[show edit update destroy]
  helper_method :participant_choices

  # GET /tasks or /tasks.json
  def index
    @tasks = Task.includes(:participants, :category, :owner, participating_users: :user).joins(:participants).where(
      "owner_id = ? OR participants.user_id = ?",
      current_user.id,
      current_user.id
    ).group("tasks.id", "users.id", "categories.id", "owners_tasks.id", "participating_users_tasks.id", "users_participants.id")
  end

  # GET /tasks/1 or /tasks/1.json
  def show; end

  # GET /tasks/new
  def new
    @task = Task.new
  end

  # GET /tasks/1/edit
  def edit; end

  # POST /tasks or /tasks.json
  def create
    @task = Task.new(task_params)
    @task.owner = current_user
    respond_to do |format|
      if @task.save
        format.html { redirect_to task_url(@task), notice: "Task was successfully created." }
        format.json { render :show, status: :created, location: @task }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tasks/1 or /tasks/1.json
  def update
    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to task_url(@task), notice: "Task was successfully updated." }
        format.json { render :show, status: :ok, location: @task }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @task.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tasks/1 or /tasks/1.json
  def destroy
    @task.destroy

    respond_to do |format|
      format.html { redirect_to tasks_url, notice: "Task was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_task
    @task = Task.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def task_params
    permitted = params.require(:task).permit(:name, :description, :due_date, :category_id,
                                             participating_users_attributes: %i[user_id role id _destroy])
    # A crafted request must not reach a category the user cannot see: the task then fails like one without a category.
    if permitted.key?(:category_id) && !visible_categories.exists?(permitted[:category_id])
      permitted[:category_id] = nil
    end
    reject_other_visitors(permitted[:participating_users_attributes]) if demo_mode?
    permitted
  end

  # The users the participant picker offers: in demo mode only the fictitious teammates, never another visitor.
  def participant_choices
    demo_mode? ? User.teammates : User.where.not(id: current_user.id)
  end

  # The server keeps the picker's demo rule: a participant outside it fails like one without a user.
  # Forms send the participants as a hash keyed by index, JSON may send an array.
  def reject_other_visitors(participants)
    (participants.respond_to?(:each_value) ? participants.each_value : Array(participants)).each do |participant|
      participant[:user_id] = nil if participant.key?(:user_id) && !participant_choices.exists?(participant[:user_id])
    end
  end
end
