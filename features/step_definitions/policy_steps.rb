When(/^I load the policy "([^"]*)(?: with options "(.*?)")?"$/) do |text, options|
  load_policy text, options
end

When(/^I load the policy(?: with options "(.*?)")?(?: with "(.*)" privilege)?:$/) do |options, privilege, text|
  load_policy text, options, privilege
end

When(/^I( try to)? plan the policy as (text|yaml)(?: with options "(.*?)")?:$/) do |try, format, options, text|
  options = inject_namespace(options) if options

  command_options = if options
    inject_namespace(options)
  else
    "--namespace #{namespace}"
  end

  cmd = "conjur policy load --no-context --dry-run --format #{format} #{command_options}"
  if ENV['DEBUG']
    step %Q(I set the environment variable "DEBUG" to "true")
  end
  step "I run `bundle exec #{cmd}` interactively"
  last_command_started.write(inject_namespace(text))
  last_command_started.stdin.close

  expect(last_command_started).to have_exit_status(0) unless try

  $stderr.puts last_command_started.stderr unless last_command_started.stderr.blank?
end

Then(/^the plan should not succeed$/) do
  expect(last_command_started).to_not have_exit_status(0)
end
