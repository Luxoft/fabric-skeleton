### How to launch  fabric-skeleton development cluster (Hyperledger
### Fabric based) on AWS test bed cluster

Basic boilerplate of devops for Hyperledger Fabric based projects.

# Project structure:

- *ops-cli* - Shell script used launch the test bed
- *cluster_confgs* - Directory containing YAML files used by *ops-cli*
to start a test bed cluster
- *https://github.com/Luxoft/fabric-skeleton* - Repository containing
  the test bed source 


## Installing fabric-skeleton

The test bed can only be initiated by logging on to a properly configured EC2 instance,
called a *Blockchain-controller*, and running the *ops-cli* script.

To instantiate a *Blockchain-controller* node:

1. Access a UNIX server with *bash 4.X*, *aws-cli 1.14.40*, and *git*
installed.


2. Clone the most recent version of the *fabric-skeleton* from the
Luxoft git repository.

	```
	> git clone  https://github.com/Luxoft/fabric-skeleton
	```
3. Go the the *farbric-skeleton/bootstrap* directory and run
*bootStrap.sh*

	**Before running *bootStraph.sh* properly configured an AWS CLI environment
	(see [Configuring the AWS CLI]( https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html)).**
	
	```
	> git clone  https://github.com/Luxoft/fabric-skeleton
	> cd fabric-skeleton/bootstrap
	> ./bootStrap.sh
	```
	The script will instantiate and configurate a *Blockchain-controller*
EC2 instance from which to create and work with a *fabric-skeleton* test
cluster.

	```
	Preparing to launch instance name 'Blockchain-controller'
	Verifying AWS account
	Configuring EC2 security groups and IAM roles
	    Using existing 'Blockchain-Fabic-Role' IAM role.
	    Using existing 'Blockchain-Fabic-Role' IAM Instance Profile
	    Using existing 'Blockchain-Fabric' EC2 security group.
	Configuring EC2 instance key pair 'Blockchain-controller'
	    Saving private key to './Blockchain-controller.pem'
	Using EC2 AMI ami-925144f2 in current region
	Starting EC2 instance
	    Instance Arn:       i-0e1b961ee63bbc3fe
	    Instance Address:   ec2-52-53-238-245.us-west-1.compute.amazonaws.com
	    Instance Region:    us-west-1
	    Instance Subnet:    subnet-33900568
	Configuring Instance (output: bootstrap_180404_1342.log)
	    Cloning: https://github.com/Luxoft/fabric-skeleton.git branch: Bootstrap
	    Installing development software
		
	The EC2 instance can now be accessed with:
		ssh -i ./Blockchain-controller.pem ubuntu@ec2-52-53-238-245.us-west-1.compute.amazonaws.com
	```

## Starting a *fabric-skeleton* workspace

To start a *fabric-skeleton* workspace,

1. Log into the *Blockchain-controller*:
   ```
   ssh -i ./Blockchain-controller.pem ubuntu@ec2-52-53-238-245.us-west-1.compute.amazonaws.com
   ```
   **Note: all necessary software to create and run *fabric-skeleton* will
   have been installed.**
   
2. Go to *fabric-skeleton/ops* in the home directory:

	```
	cd ~/fabric-skeleton/ops
	```
3. To launch a cluster, use the *ops-cli* script.

   Cluster configurations are specified by YAML files found under
   *fabric-skeleton/ops/cluster_configs*
   ```
   ls fabric-skeleton/ops/cluster_configs/
   Blockchain-controller1.yaml  Blockchain-controller2.yaml cluster-config.yaml.source  multi_sample.yaml  single_sample.yaml
	```
   Cluster specified by the configuration file name without the
   extension.

Therefore to can be started with commands of the form
	```
	./ops-cli -i ~/.ssh/Blockchain-controller.pem  -c single_sample_new
	```
	or
	```
	./ops-cli -i ~/.ssh/Blockchain-controller.pem  -c Blockchain-controller1
	```
	*Farbric-start.sh is a proto-type which handles some environment

#### Writing a configuration files
The first part of the configuration file specifies the AWS environment
in which the *fabric-skeleton* cluster is to be run.

The remainder specifies how nodes are to be configures.

##### AWS Environment Specification

```
region: us-west-1
instance_type: t2.micro
ami: ami-50b1a030  # Ubuntu 16.04 LTS
keypair: Blockchain-controller
pem_path: /home/ubuntu/.ssh/Blockchain-controller.pem
user_name: ubuntu
project_name: Cluster1
subnet_id: subnet-4b81f92c
group_id: Blockchain-Fabric
```

- At the current time, there is a field in the configuration YAML
file  *group-id* specifying the AWS EC2 security group.

	This value is ignored, but must be present.  The sercurity group
*Blockchain-Fabric* is always used.

- The *keypair* field refers to the name of the EC2 keypair on the AWS
  system
  [Amazon EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).

	The *pem_path* argument is a private SSH credential file which
corresponds to that keypair.  The file should have *600* permissions.

- The *subnet_id* field is required. The current subnet can be obtained
on an EC2 instance with
```
curl -s
http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s
http://169.254.169.254/latest/meta-data/network/interfaces/macs/)subnet-id/
```
It is also displayed by bootStraph.sh

##### Fabric-skeleton Node Configuration

```
Needs detailed explanation
```

##### ops-cli

ops-cli is simple bash script to start the fabric-skeleton based cluster

There are some flags you can set:
- *-c <cluster_id>* - cluster id, used to differ clusters between each other. If not set - will be asked on start.
- *-k* - (optional) to kill cluster 
- *-r* - (optional) to restart cluster
- *-i* - path to pem file for vms access 
- *-t* - (optional) to run cluster in test mode (run-test-kill) 
- *-u <user_name>* - (optional) remote user name ('ubuntu' by default) 
- *-h <hosts_path>* - (optional) hosts file path - for **static inventory support** 
(if you want to manage your vms by yourself), see hosts.source for more information. *Note: in that case,
 matching between cluster config (counts) and real machines count is your responsibility*   
- *-n <network_dir>* - (optional) to set path to hyperledger fabric artifacts (crypto etc) - *not recommended* (avoid strong connection of application with specific artifacts). 
    By default, new artifacts will be generated automatically - it's more recommended way.

Examples:

```
# start cluster with id cluster1
./ops-cli -c cluster1 -i ~/apitester.pem

# kill cluster with id cluster1
./ops-cli -c cluster1 -i ~/apitester.pem -k

# restart cluster with id cluster1
./ops-cli -c cluster1 -i ~/apitester.pem -r

# start cluster with id cluster1 and static inventory file hosts
./ops-cli -c cluster1 -i ~/apitester.pem -h hosts
```



## License and Copyright

Copyright &copy; Luxoft 2018

This README and documentation is licensed under the Creative Commons
Attribution-ShareAlike 4.0 International License. To view a copy of
this license, visit http://creativecommons.org/licenses/by-sa/4.0/ or
send a letter to Creative Commons, PO Box 1866, Mountain View, CA
94042, USA.

The software in this repo is copyright of the individual owners as
specified in each file and is licensed under the Apache 2.0 license
unless otherwise noted.
