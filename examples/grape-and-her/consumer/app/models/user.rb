class User < Model
  # Attributes
  attributes :email, :fullname, :organization_id

  # Associations
  belongs_to :organization
end
