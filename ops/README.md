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

#### Specifying A Fabric Cluster
The YAML file defining a cluster's configuration (and stored in fabric-skeleton/ops/cluster_configs) consisted of two section:

- AWS Environment Specification
- Fabric Cluster Configuration

Below is an example YAML file:

```
# basic vars for deployment, taken from config.yaml.source
---
# VERIFY OR MODIFY the settings below for AWS REGION
region: us-west-1   
ami: ami-925144f2	    #AMI Supports Ubuntu 16.04 LTS
subnet_id: subnet-33900568
#
# OPTIONAL (defaults work with accounts created by bootStrap.sh
instance_type: t2.micro
project_name: cluster-config 
keypair: Blockchain-controller 
pem_path: /home/ubuntu/.ssh/Blockchain-controller.pem 
user_name: ubuntu 
#
# DO NOT MODIFY
group_id: Blockchain-Fabric 

#
#CLUSTER CONFIGURATION
when_exists: skip_starter # one of [crush, skip_starter, none], to stop whole deployment, skip aws starter or deploy as usual

monitoring_enabled: False # to start blockchain monitoring stack
elk_enabled: False # to start external logging stack on ELK

# fabric network configs
orderers_count: 2
peers_count_per_org: 2  # NOTE: peers_count_per_org for 1 organisation, total peers count is calculated as peers_count*organisations_count
organisations_count: 2
zookeeper_count: 3 # 3/5/7 - used when orderers_count > 1
kafka_count: 4 # > 3 - used when orderers_count > 1
business_nodes_count: 3

# NOTE: feel free to add your project-specific variables

```

##### AWS Environment Specification
This section of the YAML config specifies the AWS environment (region, security groups, subnet) on which to create and run a fabric cluster.

This information is typically at the top of the YAML file.

An example is shown below.

```
# basic vars for deployment, taken from config.yaml.source
---
# VERIFY OR MODIFY the settings below for AWS REGION
region: us-west-1   
ami: ami-925144f2	    #AMI Supports Ubuntu 16.04 LTS
subnet_id: subnet-33900568
#
# OPTIONAL (defaults work with accounts created by bootStrap.sh
instance_type: t2.micro
project_name: cluster-config 
keypair: Blockchain-controller 
pem_path: /home/ubuntu/.ssh/Blockchain-controller.pem 
user_name: ubuntu 
#
# DO NOT MODIFY
group_id: Blockchain-Fabric 

#
#CLUSTER CONFIGURATION
```
<br>

###### Argument Defintions and Usage
The following arguments <strong>MUST</strong>be either <strong>set</strong>or <strong>verified</strong>as
consitent with EC2 configuration of the host running *ops-cli* of the Blockchain

<dl>
  <dt><strong>region</strong></dt>
  <dd>The <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html">AWS region</a> of the EC2 instance on which <em>ops-cli</em> is run.</dd>

<dt><strong>ami</strong></dt>
  <dd>An <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html">Amazon
  Machine Image (AMI)</a> available in the region of the EC2 instance on which <em>ops-cli</em> is run.</dd>
  <dt><strong>subnet_id</strong></dt>
  <dd>The <a
  href="https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Subnets.html#SubnetSize">AWS
  Virtual Private Cluster subnet</a> of the EC2 instance on which
  <em>ops-cli</em> is run.<br><br>
The current subnet can be obtained on an EC2 instance with:<br>
<pre><code>
curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$(curl -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/)subnet-id/
</pre></code>
The subnet of the EC2 instance created by <em>bootStraph.sh</em> is displayed after completion of the instance's creation.
</dd>
</dl>
  <br>
The following arguments <strong>MAY</strong>modified, although the defaults work with
any EC2 instance created by <em>bootStrap.sh</em>.
<br><br>
<dt><strong>instance_type</strong></dt>
<dd>The <a href="https://aws.amazon.com/ec2/instance-types/">AWS EC2
Instance Type</a> to be used when creating members of the fabric cluster
</dd>
</dl>

<dt><strong>project_name</strong></dt>
<dd>A convenient name for fabric cluster project.</a> 
</dd>
</dl>

<dt><strong>keypair</strong></dt>
<dd>A valid <a href="https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html">AWS ssh Key Pair instance</a> available in the region of the EC2 instance on which <em>ops-cli</em> is run.</dd>
  
</dd>
</dl>

<dt><strong>pem_path</strong></dt>
<dd>The path to an SSH credential file containing a private key
corresponding to the <strong>keypair</strong> argument above.<br>
The file should have <em>600</em> permissions.
</dd>
</dl>

<dt><strong>user_name</strong></dt>
<dd>The use name under which the fabric is to be run, typically the
login used to access he EC2 instance on which <em>ops-cli</em> is run</a> 
</dd>
</dl>
<br>
The following arguments <strong>SHOULD NOT</strong> modified.
<dl>
<dt><strong>group_id</strong><dt>
<dd>This is the value of the <a href="">AWS EC2 Security Group</a> under
which the fabric cluster is to be run.<br>
At the present time, this value is ignored, but must be present in the YAML file.
<br>The sercurity group
<em>Blockchain-Fabric</em> is the default security group, and is created by <em>bootStraph.sh.</em>
</dd>
</dt>

<br>

##### Fabric-skeleton Node Configuration
##### AWS Environment Specification
This section of the YAML config specifies how the cluster configuration should be (how many and what type of nodes in the cluster, business rules, and project specific variables).

This information is typically at the bottom of the YAML file.

An example is shown below.

```
# basic vars for deployment, taken from config.yaml.source
---
# VERIFY OR MODIFY the settings below for AWS REGION
#
#CLUSTER CONFIGURATION
when_exists: skip_starter # one of [crush, skip_starter, none], to stop whole deployment, skip aws starter or deploy as usual

monitoring_enabled: False # to start blockchain monitoring stack
elk_enabled: False # to start external logging stack on ELK

# fabric network configs
orderers_count: 2
peers_count_per_org: 2  # NOTE: peers_count_per_org for 1 organisation, total peers count is calculated as peers_count*organisations_count
organisations_count: 2
zookeeper_count: 3 # 3/5/7 - used when orderers_count > 1
kafka_count: 4 # > 3 - used when orderers_count > 1
business_nodes_count: 3

# NOTE: feel free to add your project-specific variables

```


###### Argument Defintions and Usage

```
Needs detailed explanation, which the current author cannot provide
```

<br>

#### ops-cli

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
