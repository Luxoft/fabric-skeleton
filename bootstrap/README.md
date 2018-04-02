# Bootstraping a fabric-skeleton Blockchain-Fabric controller

Instructions on how to create a *frabic-skeleton* 'Blockchain-controller' AWS instance, which can stop/start/test a Blockchain cluster using *frabic-skeleton*.

# Project structure:

- *bootStrap.sh* - Shell script used create a *frabic-skeleton* 'Blockchain-controller' AWS instance
- *instanceConfig.sh* - Script run by *bootStrap.sh* on remote instance
  to configure the fabric-skeleton development environment

# Dependencies:
* bash 4.X
* aws-cli 1.14.40


# How to run:
1. Clone *fabric-skeleton*
	```
	> git clone  https://github.com/Luxoft/fabric-skeleton
	```

2. Execute *bootStrap.sh* located in *fabric-skeleton/bootstrap*

**To use the bootstrapping tools, an user must have**

1. A valid AWS account access_key_id, secret_access_key, and region
	configured
2. Appropriate permissions:
	   + AmazonEC2FullAccess
	   + AmazonS3FullAccess
	   + IAMFullAccess
	
The *bootStrap.sh* script does the following
	
- Creates or verifies the existing of the **EC2 Security Group
		  Blockchain-Fabric** (the name is hard coded in the
		  ansible playbooks)
	
  Currently its permissions should be:
	
**Inbound:**
	
<table>
<tr><td>Type: </td><td>All traffic</td><td>SSH</td></tr>
<tr><td>Protocol</td><td>All</td><td>TCP</td></tr>
<tr><td>Port Range: </td><td> All</td><td> 22</td></tr>
<tr><td>Source: </td><td>    Blockchain</td><td>0.0.0.0/0</td></tr>
<tr><td> </td></td><td>Fabric Group</td><td></td></tr>
</table>

**Outbound:**
	
<table>
<tr><td>Type: </td><td>All traffic</td></tr>
<tr><td>Protocol</td><td>All</td></tr>
<tr><td>Port Range: </td><td> All</td></tr>
<tr><td>Source: </td><td>All</td></tr>
</table>
	
- Creates or verifies the existing of an **IAM Role** with the following
		permissions
	
		  + AmazonEC2FullAccess
		  + AmazonS3FullAccess
		  + AmazonElastiCacheReadOnlyAccess
		  + IAMReadOnlyAccess
		  + AmazonRDSReadOnlyAccess

- Generates an **SSH Keypair** to used to access the instance
- Copies a verified **Amazon Machine Image (AMI)** to the current
region if necessary
- Create an new **EC2 Instance**
- Clones the  *fabric-skeleton* repository from
  'https://github.com/Luxoft/fabric-skeleton.git' to the EC2 instance.
- Configures the software development environment on the instance,
  first by executing **fabric-skeleton/bootstrap/instanceConfig.sh**
  then by running **pip install -r fabric-skeleton/ops/requirements.txt**.

	```
	> cd fabric-skeleton/bootstrap
	> ./bootStrap.sh
	
	Preparing to launch instance name 'Blockchain-controller'
	Verifying AWS account
	Configuring EC2 security groups and IAM roles
	    Using existing 'Blockchain-Fabric' EC2 security group.
	    Using existing 'Blockchain-Fabic-Role' IAM role.
	    Using existing 'Blockchain-Fabic-Role' IAM Instance Profile
	Configuring EC2 instance key pair 'Blockchain-controller'
	    Saving private key to './Blockchain-controller.pem'
	Obtaining EC2 AMI
	Starting EC2 instance
	    Instance Arn:     i-0c14cd34af31792a8
	    Instance Address: ec2-18-144-18-69.us-west-1.compute.amazonaws.com
	    Instance Region:  us-west-1
	Configuring development environment
	
	The EC2 instance can now be accessed with:
	  ssh -i ./Blockchain-controller.pem ubuntu@ec2-18-144-18-69.us-west-1.compute.amazonaws.com
	  ```

	
3. Log into the controller instance:
	```
	ssh -i ./Blockchain-controller.pem ubuntu@ec2-18-144-18-69.us-west-1.compute.amazonaws.com
	```

4. Go to the directory *~/fabric-skeleton/ops* and execute either
   *Fabric-start.sh* or *ops-cli*, specifying the cluster configuration
   and the ssh key.

   Cluster configurations are specified by YAML files found under
   *~/fabric-skeleton/ops/cluster_configs*
   ```
   ls fabric-skeleton/ops/cluster_configs/
   Blockchain-controller1.yaml  Blockchain-controller2.yaml cluster-config.yaml.source  multi_sample.yaml  single_sample.yaml
	```
   Cluster specified by the configuration file name without the
   extension.

	Therefore to can be started with commands of the form

	```
	export AWS_DEFAULT_REGION="us-west-2"
	export FABRIC_CFG_PATH="/home/ubuntu/fabric-skeleton/ops/network_dist"
	./ops-cli -i ~/.ssh/Blockchain-controller.pem  -c single_sample_new
	```
	or
	```
	./Fabric-start.sh -i ~/.ssh/Blockchain-controller.pem  -c Blockchain-controller1
	```
*Farbric-start.sh is a proto-type which handles some environment
variables (AWS_DEFAULT_REGION and FABRIC_CFG_PATH) and file operations
automatically, as well as proto-typing future options.*


