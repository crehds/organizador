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
  # "Probar el demo" gives each visitor an account under this domain; .invalid is reserved and receives no mail.
  VISITOR_DOMAIN = "visitante.invalid".freeze
  # Fictitious participants of the visitors' sample tasks; db/seeds.rb gives them random passwords nobody knows.
  TEAMMATE_EMAILS = %w[juan andrea leon andres natalia camilo rusbel].map { |name| "#{name}@tasker.com" }.freeze

  # No :registerable (accounts come from `bin/rails users:create`) and no :recoverable (production sends no mail),
  # so Devise draws no sign up or password reset routes. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :validatable
  has_many :participations, class_name: "Participant"
  has_many :tasks, through: :participations
  has_many :categories, dependent: :restrict_with_exception

  scope :visitors, -> { where("email LIKE ?", "%@#{VISITOR_DOMAIN}") }
  scope :teammates, -> { where(email: TEAMMATE_EMAILS) }

  # Only the demo creates visitors; in a private installation the same email is an ordinary user.
  def visitor?
    Rails.configuration.x.demo_mode && email.end_with?("@#{VISITOR_DOMAIN}")
  end
end
