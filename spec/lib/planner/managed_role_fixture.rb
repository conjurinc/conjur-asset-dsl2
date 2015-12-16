grant do
  role managed_role(layer('bastion'), "users")
  member group("developers")
end

grant do
  role group("users")
  role managed_role(layer('bastion'), "users")
  member group("developers")
end
