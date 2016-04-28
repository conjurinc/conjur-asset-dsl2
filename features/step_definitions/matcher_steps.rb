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

Then(/^the host factory layers should be exactly \[ 'test' \]$/) do
  hf = $conjur.host_factory([ @namespace, 'test' ].join('/'))
  expect(hf).to be
  expect(hf.attributes['layers']).to eq([ [ @namespace, 'test' ].join('/') ])
end

Then(/^the public keys for "([^"]*)" should be exactly:$/) do |user, pubkeys|
  expect($conjur.public_keys([ user, user_namespace ].join("@"))).to eq(pubkeys)
end
