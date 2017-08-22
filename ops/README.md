### Ops blueprint

Basic boilerplate of devops for Hyperledger Fabric based projects.

#### How to use it  

To start devops automation of your Hyperledger Fabric project, follow next steps:
1. Install requirements and set up environment variables on the host machine of deploy process:

- Install python or virtualenv with python - virtualenv is recommended (```virtualenv venv```)
- ```pip install -r requirements.txt``` (with activated virtualenv - ```source venv/bin/activated```)
- set AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION env variables
 ([docs from AWS](https://docs.aws.amazon.com/general/latest/gr/managing-aws-access-keys.html)).
- Install cryptogen and configtx tools from Hyperledger Fabric

2. Prepare cluster config - copy cluster_configs/cluster-config.yaml.source to <cluster_id>.yaml and
set numbers as you want
3. Read and follow *aws-project-starter.yaml* to continue customization for your project business layer
4. Use *ops-cli* script to manage deployment (documented below)

**This ops stuff is just boilerplate, feel free to edit and customize every single part of it in your project.** 

#### ops-cli

ops-cli is simple bash script to run whole ansible 

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




