package main

import (
	"testing"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/google/uuid"
	"github.com/golang/protobuf/proto"
)

func TestPutGetEntity(t *testing.T) {

	//declaring and initializing variables for all tests
	chaincode := new(TestChaincode)
	stub := shim.NewMockStub("TestChaincode", chaincode)

	entity := Entity{}
	entity.Name = uuid.New().String() // just random string basically nothing related to UUID really
	entity.Description = "parla basso"
	entity.Type = Type_DEFAULT

	ref := test_putEntity(t, stub, entity)

	gottenEntity := test_getEntity(t, stub, ref)

	if entity != gottenEntity {
		t.Error("Entities are not equal")
		t.Fail()
	}
}

func test_getEntity(t *testing.T, stub *shim.MockStub, ref GetEntity) Entity {

	pbmessage, err := proto.Marshal(&ref)
	if err != nil {
		t.Error(err.Error())
		t.Fail()
	}

	resp := stub.MockInvoke(uuid.New().String(), [][]byte{[]byte("GetEntity"), pbmessage})
	if resp.Status != 200 {
		t.Error(resp.Message)
		t.Fail()
	}

	bytes := resp.Payload
	if bytes == nil {
		t.Error("Empty response payload")
		t.Fail()
	}

	entity := new(Entity)
	if err := proto.Unmarshal(bytes, entity); err != nil {
		t.Error(err.Error())
		t.Fail()
	}

	return *entity
}


func test_putEntity(t *testing.T, stub *shim.MockStub, entity Entity) GetEntity {

	pbmessage, err := proto.Marshal(&entity)
	if err != nil {
		t.Error(err.Error())
		t.Fail()
	}

	resp := stub.MockInvoke(uuid.New().String(), [][]byte{[]byte("PutEntity"), pbmessage})
	if resp.Status != 200 {
		t.Error(resp.Message)
		t.Fail()
	}

	bytes := resp.Payload
	if bytes == nil {
		t.Error("Empty response payload")
		t.Fail()
	}

	ref := new(GetEntity)
	if err := proto.Unmarshal(bytes, ref); err != nil {
		t.Error(err.Error())
		t.Fail()
	}

	return *ref
}