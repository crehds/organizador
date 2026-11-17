# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class User < ApplicationRecord
  # /test signs every visitor in as this user, which db/seeds.rb creates.
  DEMO_EMAIL = "johan@tasker.com".freeze

  # No :registerable (accounts come from `bin/rails users:create`) and no :recoverable (production sends no mail),
  # so Devise draws no sign up or password reset routes. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :validatable
  has_many :participations, class_name: "Participant"
  has_many :tasks, through: :participations
  has_many :categories, dependent: :restrict_with_exception

  # Only the demo installation shares this account; in a private one the same email is an ordinary user.
  def demo?
    Rails.configuration.x.demo_mode && email == DEMO_EMAIL
  end
end
