
package main

import (
	"github.com/hyperledger/fabric/core/chaincode/shim"
	pb "github.com/hyperledger/fabric/protos/peer"
	"fmt"
	"github.com/golang/protobuf/proto"
)

var logger = shim.NewLogger("TestChaincode")


type TestChaincode struct {
	entities CouchChaincodeMap
}


func (t *TestChaincode) Init(stub shim.ChaincodeStubInterface) pb.Response {

	logger.Info("Init")

	t.entities = CouchChaincodeMap{prefix:"entities"/*, calculateSize:true */}

	return shim.Success(nil)
}


// Old school invoke
func (t *TestChaincode) OldSChool_Invoke(stub shim.ChaincodeStubInterface) pb.Response {


	function, args := stub.GetFunctionAndParameters()

	logger.Info("Invoke: " + function)

	switch function {

	case "PutEntity":

		if len(args) < 1 {
			return loggedShimError(fmt.Sprintf("Insufficient arguments number\n"))
		}

		entity := new(Entity)
		if err := proto.Unmarshal([]byte(args[0]), entity); err != nil {
			return loggedShimError(fmt.Sprintf("Failed to unmarshal protobuf: %s\n", err.Error()))
		}

		ref, err := t.PutEntity(stub, entity)

		if err != nil {
			return loggedShimError(fmt.Sprintf("Error putting object to db: %s\n", err.Error()))
		}

		pbmessage, err := proto.Marshal(ref)
		if err != nil {
			return loggedShimError(fmt.Sprintf("Failed to marshal protobuf (%s)", err.Error()))
		}

		return shim.Success(pbmessage)

	case "GetEntity":

		if len(args) < 1 {
			return loggedShimError(fmt.Sprintf("Insufficient arguments number\n"))
		}

		entityRequest := new(GetEntity)
		if err := proto.Unmarshal([]byte(args[0]), entityRequest); err != nil {
			return loggedShimError(fmt.Sprintf("Failed to unmarshal protobuf: %s\n", err.Error()))
		}

		entity, err := t.GetEntity(stub, entityRequest)

		if err != nil {
			return loggedShimError(fmt.Sprintf("Error getting object from db: %s\n", err.Error()))
		}

		pbmessage, err := proto.Marshal(entity)
		if err != nil {
			return loggedShimError(fmt.Sprintf("Failed to marshal protobuf (%s)", err.Error()))
		}

		return shim.Success(pbmessage)
	}

	return loggedShimError("Invalid invoke function name")
}


// Reflection-based invoke
func (t *TestChaincode) Invoke(stub shim.ChaincodeStubInterface) pb.Response {

	function, args := stub.GetFunctionAndParameters()
	logger.Info("Invoke: " + function + ".   TXID = " + stub.GetTxID())

	var response []byte
	var err error

	// Here we use reflection to hide boilerplate code required for parsing protobuf back and forth
	// TODO use functional approach instead of reflection (if its even possible in Go)
	switch function {

		case "GetEntity": 	response, err = call(stub, []byte(args[0]), new(GetEntity), function, t)
		case "PutEntity": 	response, err = call(stub, []byte(args[0]), new(Entity), function, t)
		default: return loggedShimError("Method not found: " + function)
	}

	if err != nil { return loggedShimError(err.Error()) }

	logger.Info("Transaction processed successfully")
	return shim.Success(response)
}



// getEntity callback representing the getEntity of a chaincode
func (t *TestChaincode) GetEntity(stub shim.ChaincodeStubInterface, ref *GetEntity) (*Entity, error) {

	if err := t.checkPermissions(stub); err != nil {
		return nil, err
	}

	entity, err := t.entities.GetProtoState(stub, []string{ref.Name}, new(Entity))

	if err != nil {
		return nil, fmt.Errorf("Error getting object from db: " + err.Error())
	}

	return entity.(*Entity), nil
}

// getEntity callback representing the getEntity of a chaincode
func (t *TestChaincode) PutEntity(stub shim.ChaincodeStubInterface, ref *Entity) (*GetEntity, error) {

	if err := t.checkPermissions(stub); err != nil {
		return nil, err
	}

	err := t.entities.PutProtoState(stub, []string{ref.Name}, ref)

	if err != nil {
		return nil, fmt.Errorf("Error getting object from db: " + err.Error())
	}

	return &GetEntity{Name:ref.Name}, nil
}

// Sample code to call separate Auth chaincode for permissions check
func (t *TestChaincode) checkPermissions(stub shim.ChaincodeStubInterface) error {
	//args := [][]byte{[]byte(permissions)}
	//
	//if subject != nil {
	//	args = append(args, subject)
	//}
	//
	//resp := stub.InvokeChaincode(authServiceChaincodeId, args, "")
	//
	//if resp.Status != 200 {
	//	logger.Info("Response status:", resp.Status)
	//	logger.Info("Response message:", resp.Message)
	//	logger.Info("Response payload:", resp.Payload)
	//
	//	return errors.New(fmt.Sprintf("Error invoking %s chaincode: (%s)", authServiceChaincodeId, resp.Message))
	//}
	//if resp.Payload == nil {
	//	return errors.New("AuthService return empty permissions")
	//}
	//
	//allowed := new(Allowed)
	//if err := proto.Unmarshal(resp.Payload, allowed); err != nil {
	//	return errors.New("Cannot parse permission protobuf")
	//}
	//
	//if !allowed.Allowed {
	//	return errors.New("Action not allowed")
	//} else {
	//	return nil
	//}
	return nil
}

func main() {
	err := shim.Start(new(TestChaincode))
	if err != nil {
		logger.Errorf("Error starting chaincode: %s", err)
	}
}
