require "test_helper"

class NotesTest < ActionDispatch::IntegrationTest
  TURBO_STREAM = { "Accept" => "text/vnd.turbo-stream.html" }.freeze

  setup do
    sign_in users(:johan)
    @task = create_task
  end

  test "the owner adds a note to a task" do
    assert_difference -> { @task.notes.count } => 1 do
      post task_notes_path(@task), params: { note: { body: "First note" } }, headers: TURBO_STREAM
    end

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_includes response.body, "First note"
  end

  test "an empty note is not saved" do
    assert_no_difference -> { Note.count } do
      post task_notes_path(@task), params: { note: { body: "" } }, headers: TURBO_STREAM
    end

    assert_response :no_content
  end
end
