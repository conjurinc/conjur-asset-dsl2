#!/bin/bash -ex

/opt/conjur/evoke/bin/wait_for_conjur

cd /src/conjur-asset-policy
bundle

export CONJUR_AUTHN_LOGIN=admin

ruby -ryaml -e "conf = YAML.load(File.read('/etc/conjur.conf')); conf['plugins'] = [ 'policy', 'authn-local' ]; File.write('/etc/conjur.conf', YAML.dump(conf))"

bundle exec rake jenkins || true
