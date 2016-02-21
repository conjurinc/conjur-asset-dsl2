#!/bin/bash -ex

echo 127.0.0.1 conjur >> /etc/hosts

/opt/conjur/evoke/bin/wait_for_conjur

cd /src/conjur-asset-dsl2
bundle

bundle exec rake jenkins || true
