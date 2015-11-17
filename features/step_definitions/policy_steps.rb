When(/^I plan the policy as (text|yaml):$/) do |format, text|
  step "I run `conjur policy load --dry-run --syntax ruby --format #{format}` interactively"
  last_command_started.write(text)
  @interactive.stdin.close()
  step "the exit status should be 0"
end
