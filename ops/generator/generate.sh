#!/bin/bash

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

  cryptogen generate --config=./crypto-config.yaml
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

  mkdir channel-artifacts

  # Note: For some unknown reason (at least for now) the block file can't be
  # named orderer.genesis.block or the orderer will fail to launch!
  configtxgen -profile OneOrgOrdererGenesis -outputBlock ./channel-artifacts/genesis.block -channelID ordererorgchannel
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi

{% for org_number in range(organisations_count) %}
  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  configtxgen -profile Org{{org_number}}Channel -outputCreateChannelTx ./channel-artifacts/org{{org_number}}channel.tx -channelID org{{org_number}}channel
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Org{{org_number}}MSP   ##########"
  echo "#################################################################"
  configtxgen -profile Org{{org_number}}Channel -outputAnchorPeersUpdate ./channel-artifacts/Org{{org_number}}MSPanchors.tx -asOrg Org{{org_number}}MSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Org{{org_number}}MSP..."
    exit 1
  fi
{% endfor %}

  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  configtxgen -profile JointChannel -outputCreateChannelTx ./channel-artifacts/jointchannel.tx -channelID jointchannel
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for Joint   ##########"
  echo "#################################################################"
  configtxgen -profile JointChannel -outputAnchorPeersUpdate ./channel-artifacts/OrgJointMSPanchors.tx -asOrg Org0MSP
  if [ "$?" -ne 0 ]; then
    echo "Failed to generate anchor peer update for Joint..."
    exit 1
  fi

  echo
}

CLI_TIMEOUT=10000



echo "Generating channel artifacts"

generateCerts
generateChannelArtifacts

