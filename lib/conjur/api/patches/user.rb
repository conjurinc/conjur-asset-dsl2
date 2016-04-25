require 'conjur/api'

class Conjur::User
  # The attribute synchronization expects a +public_keys+ method on the User, so add one.
  # The expected form is a list, so split the raw pubkeys result on newlines.
  def public_keys
    conjur_api.public_keys(login).split("\n")
  end
end
