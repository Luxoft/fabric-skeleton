#!/usr/bin/env bash

function askProceed () {
  read -p "This command will destroy existing crypto and channel artifacts.
  Be sure you don't need them or check you saved them. Continue (y/n)? " ans
  case "$ans" in
    y|Y )
      echo "proceeding ..."
    ;;
    n|N )
      echo "exiting..."
      exit 1
    ;;
    * )
      echo "invalid response"
      askProceed
    ;;
  esac
}

# Generates Org certs using cryptogen tool
function generateCerts (){
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  #cryptogen generate --config=./crypto-config.yaml
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo
}

# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"
  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  configtxgen -profile OneOrgOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  configtxgen -profile OneOrgChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org1MSP   ##########"
  echo "#################################################################"
  configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org1MSP..."
    exit 1
  fi

#  echo
#  echo "#################################################################"
#  echo "#######    Generating anchor peer update for Org2MSP   ##########"
#  echo "#################################################################"
#  configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate \
#  ./channel-artifacts/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
#  if [ "$?" -ne 0 ]; then
#    echo "Failed to generate anchor peer update for Org2MSP..."
#    exit 1
#  fi
  echo
}

CLI_TIMEOUT=10000
CHANNEL_NAME="testchannel"

# Parse commandline args
while getopts "m:c:" opt; do
  case "$opt" in
    c)  CHANNEL_NAME=$OPTARG
    ;;
  esac
done


echo "Generating artifacts for channel '${CHANNEL_NAME}'"
askProceed

generateCerts
generateChannelArtifacts

