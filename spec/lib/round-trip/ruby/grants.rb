grants do
  grant do
    role group("everyone")
    member group("developers")
    member group("support")
    member group("marketing")
    member group("ops"), admin_option: true
  end
  
  grant do
    managed_role layer("webservice"), "use_host"
    member group("developers")
    exclusive true
  end
end
