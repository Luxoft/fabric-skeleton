#!/bin/bash
#Copyright (c) Luxoft 2018
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
