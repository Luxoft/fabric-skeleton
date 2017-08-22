#!/bin/bash

function dkcl(){
    CONTAINER_IDS=$(docker ps -a --format "{{.ID}}" --filter "name=peer|peer[0-9]|orderer|orderer[0-9]|ca.luxoft.com")
    if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" = " " ]; then
        echo "========== No containers available for deletion =========="
    else
        docker rm -f $CONTAINER_IDS
    fi
}

function dkrm(){
    DOCKER_IMAGE_IDS=$(docker images --format "{{.ID}}" --filter=reference='dev-peer*')
    if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" = " " ]; then
        echo "========== No images available for deletion ==========="
    else
        docker rmi -f $DOCKER_IMAGE_IDS
    fi
}

function clean(){
    dkcl
    dkrm

    #rm -rf /tmp/hfc-test-kvs_peerOrg* $HOME/.hfc-key-store/ /tmp/fabric-client-kvs_peerOrg*
    #rm ../state.json 2> /dev/null

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
            up;;
        down)
            down;;
        clean)
            clean;;
        restart)
            clean
            up;;
        *)
            echo $"Usage: $0 {up|down|clean|restart}"
            exit 1

esac
done
