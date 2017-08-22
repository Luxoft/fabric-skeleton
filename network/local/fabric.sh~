#!/bin/bash

function dkcl(){
        CONTAINER_IDS=$(docker ps -aq)
	echo
        if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
                echo "========== No containers available for deletion =========="
        else
                docker rm -f $CONTAINER_IDS
        fi
	echo
}

function dkrm(){
        DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
	echo
        if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
		echo "========== No images available for deletion ==========="
        else
                docker rmi -f $DOCKER_IMAGE_IDS
        fi
	echo
}

function clean(){
	echo

        #teardown the network and clean the containers and intermediate images
	dkcl
	dkrm

	#Cleanup the material
	rm -rf /tmp/hfc-test-kvs_peerOrg* $HOME/.hfc-key-store/ /tmp/fabric-client-kvs_peerOrg*
	
	rm ../state.json 2> /dev/null
}

function up(){
  docker-compose up -d
}

function down(){
  docker-compose down;
}


for opt in "$@"
do

    case "$opt" in
        up)
            up
            ;;
        down)
            down
            ;;
        clean)
            clean
            ;;
        restart)
            clean
            up
            ;;

        *)
            echo $"Usage: $0 {up|down|clean|restart}"
            exit 1

esac
done
