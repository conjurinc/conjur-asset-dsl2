id "myapp/v1"
records do
  variable "db-password"
end
# Multiple records groups simply collapse in the YAML
records do
  group "secrets-managers"
  group "secrets-users"
end

permissions do
  permit %w(update) do
    resource variable("db-password")
    role group("secrets-managers")
    exclusive true
  end
  permit %w(read execute) do
    resource variable("db-password")
    role group("secrets-users")
    exclusive true
  end
end

grants do
  grant do
    role group("secrets-users")
    member group("secrets-managers")
  end
end
