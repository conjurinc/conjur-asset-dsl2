group "developers"

group "developers" do
  gidnumber 1102
  annotation 'name', "Developers"
end

group "developers" do
  owner Conjur::DSL2::Types::Role.new('foreign-account:group:operations')
end

variable "db-password" do
  kind "database password"
end

role "job", "cook"

resource "food", "bacon" do
  annotation 'tastes', "Yummy"
end

user 'alice'
