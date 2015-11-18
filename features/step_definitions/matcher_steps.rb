Then(/^(.*)normalized stdout(.+):$/) do |prefix, postfix, text|
  normalize_stdout
  step [ prefix, "stdout", postfix, ':' ].join, text
end

Then(/^(.*)normalized stdout([^:]+)$/) do |prefix, postfix|
  normalize_stdout
  step [ prefix, "stdout", postfix ].join
end

Then(/^(.*)normalized JSON(.*)$/) do |prefix, postfix|
  normalize_stdout
  step [ prefix, "JSON", postfix ].join
end
