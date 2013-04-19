class Organization < Model
  # Attributes
  attributes :name

  # Associations
  has_many :users
end
