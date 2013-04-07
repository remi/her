class Organization < ActiveRecord::Base
  # Associations
  has_many :users

  # Validations
  validate :name, presence: true
end
