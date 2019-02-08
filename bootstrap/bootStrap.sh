#!/usr/bin/env bash
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

declare -a spin=( "-" "\\" "|" "/")

spinner()
{
	OPTS="$SHELLOPT"
	set +xv
	xSet=""
	vSet=""
	if [[ $OPTS == *xtrace* ]];then
		xSet=1
	fi
	if [[ $OPTS == *verbose* ]];then
		vSet=1
	fi
	set +xv
	pid=$1
	shift
	mode="FollowingReturn"
	if [ $# -ne 0 ];then
		mode=1
	fi
	while [ $(kill -0 $pid >/dev/null 2>&1 ;echo $?) -eq 0 ];do
		for i in "${spin[@]}";do
			echo -ne "\b$i"
			sleep 0.1
		done
	done
	if [ "$mode" = "FollowingReturn" ];then
		echo -e "\b "
	else
		index=$(( $(($RANDOM % 5)) - 1))
		echo -ne "\b${spin[index]}"
	fi
	if [[ "$xSet" == "1" ]];then
		set -x
	fi
	if [[ "$vSet" == "1" ]];then
		set -v
	fi
		
}

ERR=$(mktemp)

instanceUser="ubuntu"
instanceType="t2.micro"
instanceDiskSize='30'  #largest free size

#Git setting used when the fabric-skeleton is
#clone _on the newly created instance_
repoLocation='https://github.com/Luxoft/fabric-skeleton.git'

repoBranch="master"  #Default, before we use the current branch we are in.
if hash git 2> /dev/null ;then
    customRepoLocation=$(git config --get remote.origin.url)
    if [ "customRepoLocation" != "" ];then
		repoLocation=$customRepoLocation
	fi
	currentBranch=$(git branch 2>/dev/null| sed -n -e 's/^\* \(.*\)/\1/p' )
	if [ "$currentBranch" != "" ];then
		repoBranch=$currentBranch
	fi
fi

scriptLocation=$(cd "$(dirname $0)";pwd)
userDataFile="$scriptLocation/bootstrapUserData.sh"

sgName="Blockchain-Fabric"
#sgName="$(date '+%s')Group"
sgId=""

roleName="Blockchain-Fabic-Role"
#roleName="$(date '+%s')Role"
instProfName="${roleName}"
roleArn=""
instProfArn=""

#AMI configuration
#source_ami_id="ami-79873901"
#source_ami_region="us-west-2"
source_ami_id="ami-925144f2"
source_ami_region="us-west-1"

#required by create-role, specifies role applies to EC2
roleRolePolicyDocument='{"Version": "2012-10-17", '\
'						"Statement": [ '\
'							{ '\
'								"Effect": "Allow", '\
'								"Principal": { '\
'									"Service": "ec2.amazonaws.com" '\
'								}, '\
'								"Action": "sts:AssumeRole" '\
'							} '\
'						] '\
'					   }'


#policies used by our cluster builder
iamPolicies=("AmazonEC2FullAccess" \
			 "AmazonS3FullAccess" \
			 "AmazonElastiCacheReadOnlyAccess" \
			 "IAMReadOnlyAccess" \
			 "AmazonRDSReadOnlyAccess")





#First get a unique name for instance
instanceName="Blockchain-controller"

testName="$instanceName"
alreadyThere=""
instanceCount=$(aws ec2 describe-key-pairs |grep -c 'KeyName.*'"${instanceName}")
if [ $instanceCount -ne 0 ];then
	instanceName="${instanceName}.$( printf '%03d\n' ${instanceCount})"
fi
echo   "Preparing to launch instance name '$instanceName'"

#Before anything else, verify we have AWS access

echo   "Verifying AWS account"
if [ $(aws iam get-user >/dev/null 2>> "${ERR}";echo $?) -ne 0 ];then
	echo "Aborting: Unable to locate AWS user account." 1>&2
	cat "${ERR}" 1>&2
	exit -1
else
	cat /dev/null > "${ERR}"
fi


echo "Configuring EC2 security groups and IAM roles"

#handle roles
roleArn="$(aws iam get-role --role-name "${roleName}" \
			   --query Role.Arn --output text 2>/dev/null |grep -v -w -e ^None )"

modifiedRole=""  #used to control how we handle the role instance
if [ "$roleArn" != ""  ];then
	echo "    Using existing '${roleName}' IAM role."
else
	echo -n "    Creating '${roleName}' IAM Role  "

	aws iam create-role --role-name ${roleName} \
				   --assume-role-policy-document "${roleRolePolicyDocument}"\
				   --query Role.Arn --output text >/dev/null 2>> "${ERR}" &
	spinner $! 1

	roleArn="$(aws iam get-role --role-name "${roleName}" \
			   --query Role.Arn --output text 2>> "${ERR}" |grep -v -w -e ^None )"	
	if [ "$roleArn" == "" ];then
		echo "Aborting: Could not configure role." 1>&2
		cat "${ERR}" 1>&2
		exit -1
	else
		cat /dev/null > "${ERR}"
	fi

	modifiedRole=1
	#


	attachedPolicies="$(aws iam list-attached-role-policies \
							--role-name ${roleName} --output text|sed 's+\\n++')"

	for pol in "${iamPolicies[@]}";do
		if [[ "${attachedPolicies}" != *"${pol}"* ]];then
			modifiedRole=1
			#   echo "       Attaching '$pol' to role '$roleName'"

			aws iam attach-role-policy --policy-arn "arn:aws:iam::aws:policy/${pol}" \
				--role-name "${roleName}" >/dev/null 2>> "${ERR}" &
			spinner $! 1
			if [ $(cat "${ERR}" | wc -l) -ne 0 ];then
				echo "Aborting: Could not attach security profile." 1>&2
				cat "${ERR}" 1>&2
				exit -1
			else
				cat /dev/null > "${ERR}"
			fi
		fi
	done
	echo -e "\b  "
fi

#now check if we have a role instance,
#if the instance is not there we create and attach the role
#if the role was modified, we will update the role instance

instProfArn="$(aws iam get-instance-profile \
							   --instance-profile-name ${instProfName} \
							   --query InstanceProfile.Arn \
							   --output text 2> /dev/null |grep -v -w -e ^None )"

if [ "$instProfArn" != "" ];then
	echo "    Using existing '${instProfName}' IAM Instance Profile "
	#Note, as the instance profile refs to ARN of role, mods to role should propagate
else
	echo -n "    Creating '${instProfName}' IAM Instance Profile  "

	aws iam create-instance-profile \
		--instance-profile-name ${instProfName} \
		--query InstanceProfile.Arn --output text >/dev/null 2>> "${ERR}" &
	spinner $! 1

	instProfArn="$(aws iam get-instance-profile \
							   --instance-profile-name ${instProfName} \
							   --query InstanceProfile.Arn \
							   --output text 2> /dev/null |grep -v -w -e ^None )"

	if [ "$instProfArn" == "" ];then
		echo "Aborting: Could not configure role instance." 1>&2
		cat "${ERR}" 1>&2
		exit -1
	else
		cat /dev/null > "${ERR}"
	fi
	

	aws iam add-role-to-instance-profile \
		--instance-profile-name ${instProfName} \
		--role-name ${roleName} >/dev/null 2>> "${ERR}" &
	spinner $! 1
	if [ $(cat "${ERR}" | wc -l) -ne 0 ];then
		echo "Aborting: Could not add roll to instance profile." 1>&2
		cat "${ERR}" 1>&2
		exit -1
	else
		cat /dev/null > "${ERR}"
	fi
	#Do wait to make sure instance profile propagated.
	ready=-100
	while [ $ready -ne 0 ];do
		sleep 5 &
		spinner $! 
		ready=$(aws iam get-instance-profile \
			 --instance-profile-name "$instProfName" >&/dev/null ;echo $?)
	done


fi


#Check if security group exists
sgId="$(aws ec2 describe-security-groups \
			--filter "Name=group-name,Values=${sgName}" \
			--query SecurityGroups[0].GroupId --output text|grep -v -w -e ^None)"
if [ "$sgId" != ""  ];then
	echo "    Using existing '${sgName}' EC2 security group."
else
	echo  -n "    Creating '${sgName}' EC2 security group  "

	aws ec2 create-security-group --group-name "${sgName}"\
		--description "Blockchain fabric Security Group" \
		--output text >/dev/null 2>> "${ERR}" &
	spinner $! 1

	sgId="$(aws ec2 describe-security-groups \
			--filter "Name=group-name,Values=${sgName}" \
			--query SecurityGroups[0].GroupId --output text|grep -v -w -e ^None)"

	if [ "$sgId" == "" ];then
		echo "Aborting: Could not create security group." 1>&2
		cat "${ERR}" 1>&2
		exit -1
	else
		cat /dev/null > "${ERR}"
	fi


	aws ec2 authorize-security-group-egress --group-id ${sgId} \
		--protocol "tcp" --port 22 --cidr "0.0.0.0/0" >/dev/null 2>> "${ERR}" &
	spinner $! 1

	aws ec2 authorize-security-group-ingress --group-id ${sgId} \
		--protocol "tcp" --port 22 --cidr "0.0.0.0/0" >/dev/null 2>> "${ERR}" &
	spinner $! 1
	
	aws ec2 authorize-security-group-ingress --group-id ${sgId} \
		--protocol "-1"  --cidr "0.0.0.0/0" >/dev/null 2>> "${ERR}" &
	spinner $!

	if [ $(cat "${ERR}" | wc -l) -ne 0 ];then
		echo "Aborting: Could not configure security group." 1>&2
		cat "${ERR}" 1>&2
		exit -1
	else
		cat /dev/null > "${ERR}"
	fi

fi




#Create key pair to use and save file
#Key names need to be unique
keyName="${instanceName}"
keyFile="./${instanceName}.pem"
echo "Configuring EC2 instance key pair '${keyName}' "

pemData="$(aws ec2 create-key-pair --key-name $keyName \
			  --query 'KeyMaterial' --output text  2> ${ERR} )"


if [ "$pemData" = "" -o $? -ne 0 ];then
	echo "Aborting: Could not configure EC2 instance key pair." 1>&2
	cat "${ERR}" 1>&2
	exit -1
else
	cat /dev/null > "${ERR}"
fi

echo "$pemData" > "${keyFile}"
echo "    Saving private key to '$keyFile'"
chmod u=rw,o=,g= "$keyFile"

#check to see if ami is in the region otherwise copy
haveLocalAMI="$(aws ec2 describe-images \
							--filter "Name=image-id,Values=${source_ami_id}" \
				 			--query 'Images[0].State' --output text)"
copiedAMI=0
if [ "$haveLocalAMI" = "available" ];then
	echo "Using EC2 AMI ${source_ami_id} in current region"
	instance_ami=${source_ami_id}
	copiedAMI=0
else
	
	echo -n "Copying EC2 AMI ${source_ami_id} from ${source_ami_region} ${spin[3]}"
	#Copy default ami and wait for it to be ready
	instance_ami="$(aws ec2 copy-image --name "${instanceName}" \
										--source-image-id "${source_ami_id}" \
										--source-region "${source_ami_region}" \
										--query "ImageId" --output text) 2> ${ERR}"

	if [ "$instance_ami" = "" ];then
		echo "Aborting: Could not copy "\
			 "default AMI '$source_ami_image' from '$source_ami_region'." 1>&2
		cat "${ERR}" 1>&2
		exit -1
	else
		cat /dev/null > "${ERR}"
	fi
	
	ready=1
#	instance_ami=ami-50889e30
	while [ "$ready" -ne 0 ];do
		sleep 5 &
		spinner $! 1

		state="$(aws ec2 describe-images --filter "Name=image-id,Values=${instance_ami}" \
					--query 'Images[0].State' --output text)"
		#state="available"  #-- for debugging
		if [ "$state" = "available"   ];then
			echo -e "\b "
			ready=0
		fi
	done
	copiedAMI=1
fi
echo -n "Starting EC2 instance ${spin[3]}"

instArn=$(aws ec2 run-instances --image-id "${instance_ami}"\
			  --key-name "${keyName}" \
		      --instance-type "${instanceType}" \
			  --tag-specifications \
			    'ResourceType=instance,Tags=[{Key=Name,Value='${instanceName}'}]'\
			  --security-group-ids "${sgId}" \
			  --iam-instance-profile '{"Name": "'${instProfName}'"}' \
			  --query 'Instances[0].InstanceId' \
			  --block-device-mapping \
			    'DeviceName=/dev/sda1,Ebs={VolumeSize='${instanceDiskSize}'}' \
			  --output text 2>> "${ERR}" )
if [ "$instArn" = "" -o "$instArn" = "None" ];then
	echo -e "\b "
	echo "Aborting: Could not start instance." 1>&2
	cat "${ERR}"
	exit -1
elif [ $copiedAMI -eq 1 ];then
	#clean up
	aws ec2 deregister-image   --image-id ${instance_ami} >/dev/null 2>> "${ERR}"
	if [ $? -ne 0 ];then
		echo "Warning: Could not deregister locall AMI ${instance_ami} after use." 1>&2
		cat "${ERR}"
	fi	
fi
cat /dev/null > "${ERR}"

PublicDnsName=""
while [ "$PublicDnsName" = "" ];do
	sleep 5 &
	#	pid=$!
	spinner $! 1

	PublicDnsName="$(aws ec2 describe-instances --instance-ids $instArn --query 'Reservations[0].Instances[0].PublicDnsName' --output text)"
done

accessible=1
while [ "$accessible" -ne 0 ];do
	sleep 5 &
	#	pid=$!
	spinner $! 1
	accessible=$(ping -i1 -n -c 1 $PublicDnsName >/dev/null 2>&1;echo $?)
	#Now make sure ssh is up
	if [ "$accessible" -eq 0 ];then
		accessible=$(ssh -q -i  "$keyFile" -o StrictHostKeyChecking=no "${instanceUser}@$PublicDnsName" \
						 ls>/dev/null 2>&1;echo $?)
	fi
done

#set up ssh keys
ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName" \
	"if [ ! -d ~/.ssh ];then mkdir ~/.ssh;fi >/dev/null " >> "${ERR}" 2>&1 &
spinner $! 1
ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName" \
	echo "'Host *' >> .ssh/config " >> "${ERR}" 2>&1 &
spinner $! 1
ssh  -q -i  "$keyFile" "${instanceUser}@$PublicDnsName"\
	  echo "'   StrictHostKeyChecking=no' >>.ssh/config"  >> "${ERR}" 2>&1 &
spinner $! 1

#upload key file and set its permissions
scp  -q -i "$keyFile"  "$keyFile" \
	"${instanceUser}@${PublicDnsName}:.ssh"  >/dev/null 2>> "${ERR}" &
spinner $! 1
ssh -q -i "$keyFile" "chmod -R u=rwX,o=,g= .ssh >/dev/null"  >> "${ERR}" 2>&1 &
spinner $!

if [ $(cat "${ERR}" | wc -l) -ne 0 ];then
	echo "Warning: Could not complete ssh configuration on $PublicDnsName." 1>&2
	cat "${ERR}" 1>&2
else
	cat /dev/null > "${ERR}"
fi


#Get Region
region=$(ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName"  curl -s http://169.254.169.254/latest/dynamic/instance-identity/document |grep region|awk -F\" '{print $4}')
#Get Subnet
mac=$(ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName" curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)
subnet=$(ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName" curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/${mac}subnet-id/)

echo "    Instance Arn:       $instArn  "
echo "    Instance Address:   $PublicDnsName"
echo "    Instance Disk Size: ${instanceDiskSize}G"
echo "    Instance Region:    $region"
echo "    Instance Subnet:    $subnet"


configLog="bootstrap_$(date '+%y%m%d_%H%M').log"
#copy repos
echo "Configuring Instance (output: $configLog)"
echo -n "    Cloning: ${repoLocation} branch: ${repoBranch}  "
#Clone this repo
ssh -q -i "${keyFile}" "${instanceUser}@$PublicDnsName" \
	"(sleep 5;set -x;git clone ${repoLocation}\
	 --branch ${repoBranch} ~/fabric-skeleton) ">> $configLog 2>&1 &
spinner $! 1


#Do fetch and pull
ssh -q -i "${keyFile}" "${instanceUser}@$PublicDnsName" \
	"(set -x;cd ~/fabric-skeleton;ls;git fetch --all;git pull)" >> $configLog 2>&1 &
spinner $!

ssh -q -i  "$keyFile" "${instanceUser}@${PublicDnsName}" \
	"sudo  bash -c ' echo LC_ALL="en_US.UTF-8" >> /etc/default/locale'" >> $configLog 2>&1 &

echo -n "    Installing development software  "
#install dev software
ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName" \
	"sudo -u root -H ~/fabric-skeleton/bootstrap/instanceConfig.sh" >> $configLog 2>&1 &
spinner $! 1

#workaround for upgrading PyYaml
ssh -q -i  "$keyFile" "${instanceUser}@${PublicDnsName}" \
	"sudo  bash -c 'rm -rf /usr/lib/python2.7/dist-packages/yaml && rm -rf /usr/lib/python2.7/dist-packages/PyYAML-3.11.egg-info'" >> $configLog 2>&1 &

#run pip install for the package
ssh -q -i  "$keyFile" "${instanceUser}@${PublicDnsName}" \
	". .bashrc && sudo -u root -H pip install -r \
	~/fabric-skeleton/ops/requirements.txt" >> $configLog 2>&1 &
spinner $! 1

#automate definition of AWS_REGION
ssh -q -i  "$keyFile" "${instanceUser}@${PublicDnsName}" \
	"echo export AWS_REGION=$region >> ~/.bashrc" >> $configLog 2>&1 &
spinner $! 1
ssh -q -i  "$keyFile" "${instanceUser}@${PublicDnsName}" \
	"echo export AWS_DEFAULT_REGION=$region >> ~/.bashrc" >> $configLog 2>&1 &
spinner $! 1

#automate subnetid settings
ssh -q -i  "$keyFile" "${instanceUser}@${PublicDnsName}" \
	"for i in ~/fabric-skeleton/ops/cluster_configs/*; do sed -i 's/subnet.*/subnet_id: $subnet/g' "\$i"; done" >> $configLog 2>&1 &
spinner $! 1

echo
echo "The EC2 instance can now be accessed with:"
echo "  ssh -i ${keyFile} ${instanceUser}@$PublicDnsName"
echo


