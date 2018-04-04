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

instanceUser="ubuntu"
instanceType="t2.micro"

#Git setting used when the fabric-skeleton is
#clone _on the newly created instance_
repoLocation='https://github.com/Luxoft/fabric-skeleton.git'

repoBranch="master"  #Default, before we use the current branch we are in.
if hash git 2> /dev/null ;then
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

ec2TemplateArn="lt-0357fcc68a8e0b820"




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
if [ $(aws iam get-user >&/dev/null;echo $?) -ne 0 ];then
	echo "Aborting: Unable to locate AWS user account." 1>&2
	exit -1
fi

echo "Configuring EC2 security groups and IAM roles"
#Check if security group exists
sgId="$(aws ec2 describe-security-groups \
			--filter "Name=group-name,Values=${sgName}" \
			--query SecurityGroups[0].GroupId --output text|grep -v -w -e ^None)"
if [ "$sgId" != ""  ];then
	echo "    Using existing '${sgName}' EC2 security group."
else
	echo  -n "    Creating '${sgName}' EC2 security group  "
	aws ec2 create-security-group --group-name "${sgName}"\
		--description "Blockchain fabric Security Group" --output text >& /dev/null &

	spinner $! 1

	sgId="$(aws ec2 describe-security-groups \
			--filter "Name=group-name,Values=${sgName}" \
			--query SecurityGroups[0].GroupId --output text|grep -v -w -e ^None)"

	if [ "$sgId" == "" ];then
		echo "Aborting: Could not configure security group." 1>&2
		exit -1
	fi

	aws ec2 authorize-security-group-egress --group-id ${sgId} \
		--protocol "tcp" --port 22 --cidr "0.0.0.0/0" >& /dev/null &
	spinner $! 1

	aws ec2 authorize-security-group-ingress --group-id ${sgId} \
		--protocol "tcp" --port 22 --cidr "0.0.0.0/0" >& /dev/null &
	spinner $! 1
	spinner $! 1
	
	aws ec2 authorize-security-group-ingress --group-id ${sgId} \
		--protocol "-1"  --cidr "0.0.0.0/0" >& /dev/null &
	spinner $!


fi


#Now handle roles
roleArn="$(aws iam get-role --role-name "${roleName}" \
			   --query Role.Arn --output text 2>/dev/null |grep -v -w -e ^None )"

modifiedRole=""  #used to control how we handle the role instance
if [ "$roleArn" != ""  ];then
	echo "    Using existing '${roleName}' IAM role."
else
	echo -n "    Creating '${roleName}' IAM Role  "
	aws iam create-role --role-name ${roleName} \
				   --assume-role-policy-document "${roleRolePolicyDocument}"\
				   --query Role.Arn --output text >&/dev/null &
	spinner $! 1


	roleArn="$(aws iam get-role --role-name "${roleName}" \
			   --query Role.Arn --output text 2>/dev/null |grep -v -w -e ^None )"	
	modifiedRole=1
	#

	if [ "$roleArn" == "" ];then
		echo "Aborting: Could not configure role." 1>&2
		exit
	fi


	attachedPolicies="$(aws iam list-attached-role-policies \
							--role-name ${roleName} --output text|sed 's+\\n++')"

	for pol in "${iamPolicies[@]}";do
		if [[ "${attachedPolicies}" != *"${pol}"* ]];then
			modifiedRole=1
			#   echo "       Attaching '$pol' to role '$roleName'"
			aws iam attach-role-policy --policy-arn "arn:aws:iam::aws:policy/${pol}" \
				--role-name "${roleName}" >& /dev/null &
			spinner $! 1

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
		--query InstanceProfile.Arn --output text >& /dev/null &
	spinner $! 1

	instProfArn="$(aws iam get-instance-profile \
							   --instance-profile-name ${instProfName} \
							   --query InstanceProfile.Arn \
							   --output text 2> /dev/null |grep -v -w -e ^None )"

	aws iam add-role-to-instance-profile \
		--instance-profile-name ${instProfName} \
		--role-name ${roleName} >& /dev/null &
	spinner $!

fi

if [ "$instProfArn" == "" ];then
	echo "Aborting: Could not configure role instance." 1>&2
	exit
fi

#Do wait to make sure instance profile propagated.
ready=-100
while [ $ready -ne 0 ];do
	sleep 0.1
	ready=$(aws iam get-instance-profile \
			 --instance-profile-name "$instProfName" >& /dev/null;echo $?)
done

#Create key pair to use and save file
#Key names need to be unique
keyName="${instanceName}"
keyFile="./${instanceName}.pem"
echo "Configuring EC2 instance key pair '${keyName}' "

pemData="$(aws ec2 create-key-pair --key-name $keyName \
			  --query 'KeyMaterial' --output text)"

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
										--query "ImageId" --output text)"
	if [ "$instance_ami" = "" ];then
		echo "Aborting: Could not copy "\
			 "default AMI '$source_ami_image' from '$source_ami_region'." 1>&2
		exit
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
			  --query 'Instances[0].InstanceId'  --output text 2> /dev/null)

if [ "$instArn" = "" -o "$instArn" = "None" ];then
	echo "Aborting: Could not start instance." 1>&2
	exit -1
elif [ $copiedAMI -eq 1 ];then
	#clean up
	aws ec2 deregister-image   --image-id ${instance_ami} >&/dev/null
fi

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
	accessible=$(ping -t1 -i1 -n -c 1 $PublicDnsName >/dev/null 2>&1;echo $?)
	#Now make sure ssh is up
	if [ "$accessible" -eq 0 ];then
		accessible=$(ssh -q -i  \
						 "$keyFile" "${instanceUser}@$PublicDnsName" ls>/dev/null 2>&1;echo $?)
	fi
done
#set up ssh keys
ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName" "mkdir ~/.ssh >& /dev/null" &
spinner $! 1
ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName" \
	echo "'Host *' >> .ssh/config" &
spinner $! 1
ssh  -q -i  "$keyFile" "${instanceUser}@$PublicDnsName"\
	  echo "'   StrictHostKeyChecking=no' >>.ssh/config" &
spinner $! 1

#upload key file and set its permissions
scp -v -q -i "$keyFile"  "$keyFile" "${instanceUser}@${PublicDnsName}:.ssh"  >& /dev/null &
spinner $! 1
ssh -q -i "$keyFile" "chmod -R u=rwX,o=,g= .ssh" &
spinner $!

#Get Region
region=$(ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName"  curl -s http://169.254.169.254/latest/dynamic/instance-identity/document |grep region|sed -r 's+^.*: "(.*)"+\1+')

echo "    Instance Arn:     $instArn  "
echo "    Instance Address: $PublicDnsName"
echo "    Instance Region:  $region"

#copy repos
log="/var/tmp/configuration_$(date '+%y%m%d_%H%M').log"
echo -n "Cloning  ${repoLocation} branch ${repoBranch} "
#Clone this repo
ssh -q -i "${keyFile}" "${instanceUser}@$PublicDnsName" \
	"(set-x;git clone ${repoLocation} --branch ${repoBranch} ~/fabric-skeleton) >> $log 2>&1" &
spinner $! 1

#Do fetch and pull
ssh -q -i "${keyFile}" "${instanceUser}@$PublicDnsName" \
	"(set -x;cd ~/fabric-skeleton;ls;git fetch --all;git pull) >> $log 2>&1" &
spinner $! 

echo -n "Installing development software "
#install dev software
ssh -q -i  "$keyFile" "${instanceUser}@$PublicDnsName" \
	"sudo -u root -H ~/fabric-skeleton/bootstrap/instanceConfig.sh >> $log 2>&1" &
spinner $! 1

#run pip install for the package
ssh -q -i  "$keyFile" "${instanceUser}@${PublicDnsName}" \
	"sudo -u root -H pip install -r ~/fabric-skeleton/ops/requirements.txt >> $log 2>&1" &
spinner $!

echo
echo "The EC2 instance can now be accessed with:"
echo "  ssh -i ${keyFile} ${instanceUser}@$PublicDnsName"
echo


