permit %w(read execute) do
  resource variable("db-password")
  role group("developers")
end
