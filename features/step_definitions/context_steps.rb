Given(/^I login as "([^"]*)"$/) do |user|
  step %Q(I set the environment variable "CONJUR_AUTHN_LOGIN" to "#{user}@#{user_namespace}")
  step %Q(I set the environment variable "CONJUR_USE_AUTHN_LOCAL" to "true")
end

Then(/^the group "([^"]*)" belongs to the group "([^"]*)"$/) do |first, second|
  first = [ namespace, first ].join('/')
  second = [ namespace, second ].join('/')
  expect($conjur.group(first).role.memberships.map(&:roleid)).to include($conjur.group(second).role.roleid)
end

Then(/^the groups "([^"]*)" and "([^"]*)" have no relationship$/) do |first, second|
  first = [ namespace, first ].join('/')
  second = [ namespace, second ].join('/')
  expect($conjur.group(first).role.memberships.map(&:roleid)).to_not include($conjur.group(second).role.roleid)
  expect($conjur.group(second).role.memberships.map(&:roleid)).to_not include($conjur.group(first).role.roleid)
end
