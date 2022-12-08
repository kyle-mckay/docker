#!/bin/bash

#region config
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
b_install_docker=true #if true then docker and each compose will attempt to install on execution
b_compose_nextcloud=false
s_compose_nextcould="${SCRIPT_DIR}/nextcould/docker-compose.yml"
b_compose_portainer=true
s_compose_portainer="${SCRIPT_DIR}/portainer/docker-compose.yml"
b_compose_radarrsonarr=true
s_compose_radarrsonarr="${SCRIPT_DIR}/radarr-sonarr/docker-compose.yml"
b_compose_qbittorrent=true
s_compose_qbittorrent="${SCRIPT_DIR}/qbittorrent/docker-compose.yml"
b_compose_organizr=true
s_compose_organizr="${SCRIPT_DIR}/organizr/docker-compose.yml"
b_compose_nginx=true
s_compose_nginx="${SCRIPT_DIR}/proxy/docker-compose.yml"
b_compose_plex=true

#region functions
test-network() {
    if nc -zw1 google.com 443; then
        addtolog "INFO: Device is online"
    else
        addtolog "ERROR: Device is offline - aborting"
        exit 1
    fi
}
addtolog() {
    #adds the passed string to a log file with a timestamp prefix
    timestamp=$(date "+%Y/%m/%d %H:%M:%S.%3N") #add %3N as we want millisecond too
    echo "$timestamp | $1" >>log.txt           # add to log
    echo $1
}
docker_install() {
    #install docker
    #https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
    #set up repository
    sudo apt-get update
    yes | sudo apt-get install \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    #install docker engine
    sudo apt-get update
    yes | sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin #latest
}
docker_helloworld() {
    #attempts to run the offocial docker test image to verify it is installed before proceeding
    dockertest=$(sudo docker run hello-world)
    #check if docker test passes
    SUB='Hello from Docker!'
    if [[ "$dockertest" == *"$SUB"* ]]; then
        addtolog "INFO: Docker test has passed"
        b_testdocker=true
    else
        addtolog "WARNING: Docker test has failed"
        b_testdocker=false
    fi
}
docker_compose() {
    addtolog "INFO: compose is set to true - running docker compose for path $1"
    sudo docker compose -f $1 up -d #$1 referrs to path passed to each compose file in settings
}
#endregion
test-network
#region docker
if $b_install_docker -eq true; then
    addtolog "INFO: Installing Docker"
    #test docker
    #confirm if docker is installed already before proceeding
    #install docker
    docker_install
    docker_helloworld
    #region docker compose
    if $b_testdocker -eq true; then
        # begin compose setups
        addtolog "INFO: Creating shared frontend network"
        sudo docker network create -d bridge frontend #create shared frontend network to be used by all compose stacks
        addtolog "ERROR: NEED TO BUILD A NETWORK CREATION CONFIRMATION CHECK"
        # radarr-sonarr
        if $b_compose_radarrsonarr -eq true; then
            docker_compose $s_compose_radarrsonarr
        else
            addtolog "INFO: radarr-sonarr compose is set to false"
        fi 
    else
        addtolog "WARNING: Hello world failed to test, cannot proceed with docker compse"
    fi
    #endregion
else
    addtolog "INFO: Docker set to not install"
fi
#endregion
