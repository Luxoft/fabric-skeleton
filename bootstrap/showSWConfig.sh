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
echo
echo "Software (apt) packages"
echo
declare -a swList
swList=("git" "build-essential" "make" "cmake" "scons" "curl" "git" \
		 "ruby" "autoconf" "automake" "autoconf-archive" "gettext"\
		 "libtool" "flex" "bison" "libbz2-dev" "libcurl4-openssl-dev" \
		 "libexpat-dev" "libncurses-devagt-get" \
		 "software-properties-common" "python-pip" "docker" \
		 "docker.io" "awscli" "maven" "gradle")
for sw in ${swList[@]};do
	echo -n "$sw: "
	ver=$(apt show "$sw" 2>/dev/null |grep -e State: -e Version)
	if [ "$ver" = "" ];then
		ver="unknown"
	fi
	echo $ver
done
echo
echo "Python modules"
echo
echo "python: $(python --version 2>&1)"
echo "pip: $(pip --version)"
for sw in $(cat $(dirname $0)/../ops/requirements.txt|sed 's+=.*++');do
	echo -n "$sw: "
	ver=$(pip show $sw |grep ^Version)
		if [ "$ver" = "" ];then
		ver="unknown"
	fi
	echo $ver

done

echo
echo "Hyperledger tools"
echo
for sw in "configtxgen" "configtxlator"  "cryptogen" ;do
	echo -n "$sw: "
	ver=$($sw --version 2>&1 |grep ' Version:')
		if [ "$ver" = "" ];then
		ver="unknown"
	fi
		echo $ver
done
echo
echo "Hyperledger docker modules"
echo

sudo docker images | grep hyperledger
		
#curl -sSL https://goo.gl/kFFqh5 | (cd /usr/local; bash -   )
