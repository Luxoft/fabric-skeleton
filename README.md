# Fabric Skeleton

Basic stuff to bootstrap your Hyperledger Fabric project.

# Project structure:

- */src* - Basic Java project stub and Fabric integration tests
- */bootstrap* - Contains script (blockchain.sh) to create Blockchain
control node. See bootstrap/Readme.md
- */ops* - boilerplate of devops
- */network* contains artifacts and scripts to help run Fabric as well as **fabric-devnet.yaml** - network topology descriptor
- */chaincodes* - Hyperledger Fabric chaincodes
- *fabric-devnet.gradle* - list of gradle tasks to run and deploy Fabric

# Dependencies:
* Gradle 3.5+
* protoc-gen-go - for building chaincode go protobuf files (Ubuntu package: _golang-goprotobuf-dev_)

# Build:
```
gradle clean build
```
# How to run:
```
gradle networkUp            // Run Hyperledger Fabric
gradle networkConfigure     // Configure Fabric using yaml descriptor (default: network/fabric-devnet.yaml)
gradle runShadow            // Run application jar
```

# Shutdown:
```
gradle networkDown
```


