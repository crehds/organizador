# == Schema Information
#
# Table name: categories
#
#  id          :bigint           not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :bigint
#
class Category < ApplicationRecord
  # The owner, set only in demo mode so each visitor keeps their own categories; a private installation leaves it
  # empty and shares every category.
  belongs_to :user, optional: true
  has_many :tasks, dependent: :restrict_with_error

  validates :name, :description, presence: true
  validates :name, uniqueness: { case_sensitive: false, scope: :user_id }
end
