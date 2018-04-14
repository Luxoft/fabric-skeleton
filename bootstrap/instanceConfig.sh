#!/bin/bash 
if [ "$EUID" != 0 ];then
	echo "Please run as root"
	exit
fi
set -x
apt-get -y update          
#apt-get  -y upgrade
apt-add-repository -y universe    
apt-get install -y git
apt-get install -y build-essential make cmake scons curl git \
                               ruby autoconf automake autoconf-archive \
                               gettext libtool flex bison \
                               libbz2-dev libcurl4-openssl-dev \
                               libexpat-dev libncurses-devagt-get
apt-get install -y software-properties-common 
apt-get install -y python-pip
hash pip # make sure we get the correct pip
pip install --upgrade pip
pip install --upgrade setuptools
apt-get install -y docker=1.5-1
apt-get install -y docker.io=1.13.1-0ubuntu1~16.04.2
apt-get install -y awscli
apt-get install -y maven  
apt-get install -y gradle  
#--apt-get install -y golang-go  
#--curl -sL https://deb.nodesource.com/setup_9.x | bash -  
#--apt-get install -y nodejs  
#--npm install npm@latest -g  
#--npm i -g n  
#--n stable  
#Changed to get latest version, and to only down load binaries
curl -sSL https://goo.gl/6wtTN5 | (cd /usr/local;bash -s - -s -d)
#curl -sSL https://goo.gl/kFFqh5 | (cd /usr/local; bash -   )
