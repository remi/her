class User < ActiveRecord::Base
  # Associations
  belongs_to :organization

  # Validations
  validate :email, presence: true, email: true
  validate :fullname, presence: true
  validate :organization, presence: true
end
