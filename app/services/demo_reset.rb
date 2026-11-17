# Deletes every record, visitor accounts included, and reloads the teammates from db/seeds.rb.
# Outside demo mode it refuses before deleting anything, because a private installation holds real data.
class DemoReset
  class Disabled < StandardError; end

  def self.call
    unless Rails.configuration.x.demo_mode
      raise Disabled, "Demo mode is off (DEMO_MODE is not \"true\"), so the demo reset deleted nothing."
    end

    ActiveRecord::Base.transaction do
      # Children before parents, so every delete respects the foreign keys.
      [Note, Participant, Task, Category, User].each(&:delete_all)
      Rails.application.load_seed
    end
  end
end
