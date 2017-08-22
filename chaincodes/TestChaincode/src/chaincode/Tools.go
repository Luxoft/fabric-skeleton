package main

import (
	"crypto/sha256"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"fmt"
	"github.com/hyperledger/fabric/protos/peer"
	"github.com/golang/protobuf/proto"
	"reflect"
	"encoding/hex"
)



/**
 * We suppose all our chaintool-style methods receives Stub and Message and return Message and Error
 */
func call(
	stub shim.ChaincodeStubInterface,
	bytes []byte,
	entity proto.Message,
	methodName string,
	t interface{}) ([]byte, error) {

	if err := proto.Unmarshal(bytes, entity); err != nil {
		return nil, fmt.Errorf("Failed to unmarshal protobuf: %s\n", err.Error())
	}

	in := []reflect.Value{reflect.ValueOf(stub), reflect.ValueOf(entity)}
	method := reflect.ValueOf(t).MethodByName(methodName)

	values := method.Call(in)

	if !values[1].IsNil() {
		err := values[1].Interface().(error)
		return nil, fmt.Errorf("Error in %s: %s\n", methodName, err.Error())
	}

	if !values[0].IsNil() {
		pbbytes, err := proto.Marshal(values[0].Interface().(proto.Message))
		if err != nil { return nil, fmt.Errorf("Failed to marshal protobuf (%s)", err.Error()) } else {
			return pbbytes, nil
		}
	}

	return nil, nil
}
// --------------- Various tools -------------------------------------

func hashHex(body []byte) string {
	hash := sha256.Sum256(body)
	return hex.EncodeToString(hash[:])
}



func loggedShimError(message string) peer.Response {
	logger.Error(message)
	return shim.Error(message)
}




