class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :animals, dependent: :restrict_with_error
  has_many :events, through: :animals
  has_many :reminders_sent, class_name: "ReminderSent", dependent: :destroy

  PHONE_FORMAT = /\A\+?[1-9]\d{7,14}\z/

  validates :phone_number, format: { with: PHONE_FORMAT, message: "must be a valid phone number in international format" }, allow_blank: true
end
