Given(/^I login as "([^"]*)"$/) do |user|
  step %Q(I set the environment variable "CONJUR_AUTHN_LOGIN" to "#{user}@#{user_namespace}")
  step %Q(I set the environment variable "CONJUR_USE_AUTHN_LOCAL" to "true")
end
