class Organization
  include Her::Model

  # Associations
  has_many :users

  # Parsing options
  parse_root_in_json true
  include_root_in_json true
end
