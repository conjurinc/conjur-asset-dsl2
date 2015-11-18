When(/^I load the policy "([^"]*)"$/) do |text|
  load_policy text
end

When(/^I load the policy:$/) do |text|
  load_policy text
end
  
When(/^I plan the policy as (text|yaml)(?: with options "(.*?)")?:$/) do |format, options, text|
  options = inject_namespace(options) if options
  specify_cli_environment
  step "I run `conjur policy load --namespace #{namespace} --dry-run --syntax ruby --format #{format} #{options}` interactively"
  last_command_started.write(text)
  last_command_started.stdin.close
  step "the exit status should be 0"
end
