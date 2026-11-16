require "test_helper"

class AssociationsTest < ActiveSupport::TestCase
  test "every association resolves its class" do
    broken = [User, Task, Category, Note, Participant].flat_map do |model|
      model.reflect_on_all_associations.filter_map do |association|
        association.klass
        nil
      rescue NameError => e
        "#{model}##{association.name}: #{e.message.lines.first.strip}"
      end
    end

    assert_empty broken
  end
end
