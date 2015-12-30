#!/bin/bash -e

function wait_for_conjur {
	docker pull registry.tld/wait-for-conjur
	docker run -i --rm --link $cid:conjur registry.tld/wait-for-conjur
}

PROJECT=conjur-asset-dsl2
BASE_IMAGE=registry.tld/conjur-appliance-cuke-master:4.6-stable
docker pull $BASE_IMAGE

cid_file=tmp/$PROJECT-dev.cid

docker build -t $PROJECT-dev -f Dockerfile.dev . 

docker run \
	-d \
	--cidfile=$cid_file \
	$PROJECT-dev

cid=$(cat $cid_file)

function finish {
	rm -f $cid_file
	docker rm -f $cid
}
trap finish EXIT

docker exec $cid bash -c "bundle exec rake jenkins" || true
