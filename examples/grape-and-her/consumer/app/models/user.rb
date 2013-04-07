class User
  include Her::Model

  # Attributes
  attributes :email, :fullname, :organization_id

  # Associations
  belongs_to :organization

  # Parsing options
  parse_root_in_json true
  include_root_in_json true
end
