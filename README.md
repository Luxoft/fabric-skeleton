# Fabric Skeleton

Skeleton framework to bootstrap your Hyperledger Fabric project.

The Fabric Skeleton is a set of configuration files and scripts to quickly set up a Blockchain cluster. Designed for AWS
this tool allows you to stop, start, and test a Blockchain built with Hyperledger's Fabric tool

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

