policy do
  id "myapp/v1"

  body do
    variable "db-password"
    group "secrets-managers"
    group "secrets-users"
  
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
  
    grant do
      role group("secrets-users")
      member group("secrets-managers")
    end
  end
end
