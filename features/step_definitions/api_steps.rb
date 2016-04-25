Given(/^I add a public key for "([^"]*)":$/) do |user, key|
  $conjur.add_public_key [ user, user_namespace ].join("@"), key
end
