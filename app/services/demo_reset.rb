# Deletes every record, visitor accounts included, and reloads the demo data from db/seeds.rb.
class DemoReset
  def self.call
    ActiveRecord::Base.transaction do
      # Children before parents, so every delete respects the foreign keys.
      [Note, Participant, Task, Category, User].each(&:delete_all)
      Rails.application.load_seed
    end
  end
end
