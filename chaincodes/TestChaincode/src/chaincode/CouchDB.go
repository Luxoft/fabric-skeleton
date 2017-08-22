package main

import "github.com/hyperledger/fabric/core/chaincode/shim"
import (
	"github.com/golang/protobuf/proto"
	"encoding/json"
	"errors"
)


func GetState(key string, toFill proto.Message, stub shim.ChaincodeStubInterface) (proto.Message, error) {

	jsonFile, err := stub.GetState(key)
	if err != nil {
		return nil, errors.New("Error getting data from db: " + err.Error())
	}

	if jsonFile == nil {
		return nil, nil
	}

	if err := json.Unmarshal(jsonFile, toFill); err != nil {
		return nil, errors.New("Error parsing json: " + err.Error())
	}

	return toFill, nil
}


func PutState(key string, message proto.Message, stub shim.ChaincodeStubInterface) error {

	upgradeJSONasBytes, err := json.Marshal(message)
	if err != nil {
		return errors.New("Failed to create json for key <" + key + "> with error: " +  err.Error())
	}

	if err := stub.PutState(key, upgradeJSONasBytes); err != nil {
		return errors.New("Error storing message: " + err.Error())
	}

	return nil
}



//func (soc *StubOnCouch) GetStateByRange(startKey, endKey string) (StateQueryIteratorInterface, error)


//func (soc *StubOnCouch) GetStateByPartialCompositeKey(objectType string, keys []string) (StateQueryIteratorInterface, error)
