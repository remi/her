class User < ActiveRecord::Base
  # Associations
  belongs_to :organization

  # Validations
  validates :email, presence: true
  validates :fullname, presence: true
  validates :organization, presence: true
end
