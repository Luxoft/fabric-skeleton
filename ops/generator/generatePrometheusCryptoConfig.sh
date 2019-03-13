#!/usr/bin/env bash

function checkOpenssl (){
  which openssl
  if [ "$?" -ne 0 ]; then
    echo "openssl tool not found. exiting"
    exit 1
  fi
  echo
  echo "##########################################################"
  echo "##### openssl found. Moving further ######################"
  echo "##########################################################"
}

# Generates Prometheus Org certs using openssl tool
function generateCertsForOneOrgPeer (){

  org=$1
  tlsDir=../network_dist/crypto-config/prometheusOrganizations/organisation$org.luxoft.com/tls/

  echo
  echo "##########################################################"
  echo "##### Generating certs for organization $org ################"
  echo "##########################################################"



  echo "Copy corresponding CA key and cert "

  cp  ../network_dist/crypto-config/peerOrganizations/organisation$org.luxoft.com/tlsca/*sk $tlsDir/ca.key
  cp  ../network_dist/crypto-config/peerOrganizations/organisation$org.luxoft.com/tlsca/*pem $tlsDir/ca.pem


  echo "Create prometheus private key and cert "
  openssl genrsa -out $tlsDir/server.key 2048
  openssl req -new -key $tlsDir/server.key -out $tlsDir/server.csr -subj "/C=RU/ST=Example/L=Example/O=Example/CN=orgN.luxoft.com"
  openssl x509 -req -in $tlsDir/server.csr -CA $tlsDir/ca.pem -CAkey $tlsDir/ca.key -CAcreateserial -out $tlsDir/server.crt -days 5000

  if [ "$?" -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi

  echo "Removing temporal files "

  rm $tlsDir/ca.key
  rm $tlsDir/server.csr

  echo
}

# Generates Prometheus Org certs using openssl tool
function generateCertsForOneOrgOrderer (){

  org=$1
  tlsDir=../network_dist/crypto-config/prometheusOrganizations/organisation$org.luxoft.com/tls/

  echo
  echo "##########################################################"
  echo "##### Generating certs for organization $org ################"
  echo "##########################################################"



  echo "Copy corresponding CA key and cert "

  cp  ../network_dist/crypto-config/ordererOrganizations/luxoft.com/tlsca/*sk $tlsDir/orderer_ca.key
  cp  ../network_dist/crypto-config/ordererOrganizations/luxoft.com/tlsca/*pem $tlsDir/orderer_ca.pem


  echo "Create prometheus  cert for orderer"
  openssl req -new -key $tlsDir/server.key -out $tlsDir/orderer_server.csr -subj "/C=RU/ST=Example/L=Example/O=Example/CN=orgN.luxoft.com"
  openssl x509 -req -in $tlsDir/orderer_server.csr -CA $tlsDir/orderer_ca.pem -CAkey $tlsDir/orderer_ca.key -CAcreateserial -out $tlsDir/orderer_server.crt -days 5000

  if [ "$?" -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi

  echo "Removing temporal files "


  rm $tlsDir/orderer_ca.key
  rm $tlsDir/orderer_server.csr

  echo
}


#Entrance point

checkOpenssl

numberOfOrganizations=$1

echo "#######################################################################"
echo "##### Generating certs for $numberOfOrganizations orgs ################"
echo "#######################################################################"



for (( org=0; org<$numberOfOrganizations; org++ ))
do
        tlsDir=../network_dist/crypto-config/prometheusOrganizations/organisation$org.luxoft.com/tls/
        mkdir -p $tlsDir
        generateCertsForOneOrgPeer $org
        generateCertsForOneOrgOrderer $org
done