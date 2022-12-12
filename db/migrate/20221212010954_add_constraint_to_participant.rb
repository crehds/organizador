class AddConstraintToParticipant < ActiveRecord::Migration[7.0]
  def change
    add_index :participants, %i[user_id task_id], unique: true
  end
end
