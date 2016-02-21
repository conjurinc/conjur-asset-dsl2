#!/bin/bash -ex

CONJUR_VERSION=${CONJUR_VERSION:-"4.6"}
DOCKER_IMAGE=${DOCKER_IMAGE:-"registry.tld/conjur-appliance-cuke-master:$CONJUR_VERSION-stable"}
NOKILL=${NOKILL:-"0"}
PULL=${PULL:-"1"}

if [ -z "$CONJUR_CONTAINER" ]; then
	if [ "$PULL" == "1" ]; then
	    docker pull $DOCKER_IMAGE
	fi
	
	cid=$(docker run -d -e CONJUR_AUTHN_LOGIN=admin -e CONJUR_AUTHN_API_KEY=secret -v ${PWD}:/src/conjur-asset-dsl2 $DOCKER_IMAGE)
	function finish {
    	if [ "$NOKILL" != "1" ]; then
			docker rm -f ${cid}
		fi
	}
	trap finish EXIT
	
	>&2 echo "Container id:"
	>&2 echo $cid
else
	cid=${CONJUR_CONTAINER}
fi

docker exec -i ${cid} /src/conjur-asset-dsl2/ci/test.sh
