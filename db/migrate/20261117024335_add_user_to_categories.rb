class AddUserToCategories < ActiveRecord::Migration[8.1]
  # Nullable: existing categories, and every category of a private installation, stay shared with no owner.
  def change
    add_reference :categories, :user, foreign_key: true
  end
end
