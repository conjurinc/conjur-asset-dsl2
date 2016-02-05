When(/^I load the policy "([^"]*)"$/) do |text|
  load_policy text
end

When(/^I load the policy:$/) do |text|
  load_policy text
end
  
When(/^I plan the policy as (text|yaml)(?: with options "(.*?)")?:$/) do |format, options, text|
  options = inject_namespace(options) if options
  specify_cli_environment
  cmd = "conjur policy2 load --namespace #{namespace} --no-context --dry-run --syntax yaml --format #{format} #{options}"
  $stderr.puts cmd
  step "I run `bundle exec #{cmd}` interactively"
  last_command_started.write(text)
  last_command_started.stdin.close

  step "the exit status should be 0"

  $stderr.puts last_command_started.stderr unless last_command_started.stderr.blank?
end
