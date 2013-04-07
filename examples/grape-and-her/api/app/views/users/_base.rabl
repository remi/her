attribute :id
attribute :email
attribute :fullname
attribute :organization_id

child :organization do
  extends("organizations/base")
end
