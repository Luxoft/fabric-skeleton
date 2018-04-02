//Copyright (c) Luxoft 2018
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//     http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"fmt"
	"github.com/hyperledger/fabric/core/chaincode/shim"
	"github.com/golang/protobuf/proto"
	"errors"
	"reflect"
	"encoding/json"
	"strings"
	"encoding/binary"
	"bytes"
)


const (
	minUnicodeRuneValue   = 0            //U+0000
)


type CouchChaincodeMap struct {
	prefix string
	calculateSize bool
}

type MapEntry struct {
	key []string
	value interface{}
}



func (t *CouchChaincodeMap) Init(stub shim.ChaincodeStubInterface, prefix string, calculateSize bool) error {

	fmt.Printf("Creating chaincode map %s", prefix)

	prefix = fmt.Sprintf("map-%s-", prefix)

	value, err := stub.GetState(prefix)
	if err != nil {
		return err
	}

	if value != nil {
		logger.Warning("Root key \"%s\" already exists and contains \"%s\"", prefix, value)
		return nil
	}

	err = stub.PutState(prefix, []byte("isMap"))
	if err != nil {
		return err
	}
	t.prefix = prefix + "-"

	err = stub.PutState(prefix + ":size", []byte{0})
	if err != nil {
		return err
	}

	return nil
}


// ------------- Type-independent methods ---------------------


func (t *CouchChaincodeMap) DeleteState(stub shim.ChaincodeStubInterface, keys []string) error {
	key, err := stub.CreateCompositeKey(t.prefix, keys)
	if err != nil { return errors.New("Cannot create composite key: " + err.Error()) }

	err =  stub.DelState(key)

	if err == nil && t.calculateSize {
		err = t.DecrementSize(stub)
	}

	return err
}



// --------------- Methods for PROTO representation -------------

func (t *CouchChaincodeMap) PutProtoState(stub shim.ChaincodeStubInterface, keys []string, value proto.Message) error {
	key, err := stub.CreateCompositeKey(t.prefix, keys)
	if err != nil { return errors.New("Cannot create composite key: " + err.Error()) }

	err = PutState(key, value, stub)

	if err == nil && t.calculateSize {
		err = t.IncrementSize(stub)
	}

	return err
}


func (t *CouchChaincodeMap) GetProtoState(stub shim.ChaincodeStubInterface, keys []string, toFill proto.Message) (proto.Message, error) {
	key, err := stub.CreateCompositeKey(t.prefix, keys)
	if err != nil { return nil, errors.New("Cannot create composite key: " + err.Error()) }

	return GetState(key, toFill, stub)
}


func (t *CouchChaincodeMap) GetProtoStates(stub shim.ChaincodeStubInterface, keys []string, typezzz reflect.Type) ([]proto.Message, error) {

	var protoStates []proto.Message

	iterator, err := stub.GetStateByPartialCompositeKey(t.prefix, keys); if err != nil { return nil, errors.New("Cannot query states: " + err.Error()) }

	for iterator.HasNext() {
		result, err := iterator.Next();  if err != nil { return nil, errors.New("Cannot query states: " + err.Error()) }
		if result != nil && result.Value != nil {
			pbResult := reflect.New(typezzz).Interface()
			if err := json.Unmarshal(result.Value, pbResult); err != nil {
				return nil, errors.New("Error parsing json: " + err.Error())
			}
			protoStates =  append(protoStates, pbResult.(proto.Message))
		}
	}

	return protoStates, nil
}

func (t *CouchChaincodeMap) GetMapProtoEntries(stub shim.ChaincodeStubInterface, keys []string, typezzz reflect.Type) ([]MapEntry, error) {
	return t.GetMapProtoEntriesPage(stub, keys,typezzz, 0,0)
}


func (t *CouchChaincodeMap) GetMapProtoEntriesPage(stub shim.ChaincodeStubInterface, keys []string, typezzz reflect.Type, skip int32, limit int32) ([]MapEntry, error) {

	var entries []MapEntry
	var i int32 = 0

	iterator, err := stub.GetStateByPartialCompositeKey(t.prefix, keys); if err != nil { return nil, errors.New("Cannot query states: " + err.Error()) }

	for iterator.HasNext() {
		result, err := iterator.Next();  if err != nil { return nil, errors.New("Cannot query states: " + err.Error()) }
		if i >= skip {
			if result != nil && result.Value != nil {
				pbResult := reflect.New(typezzz).Interface()
				if err := json.Unmarshal(result.Value, pbResult); err != nil {
					return nil, errors.New("Error parsing json: " + err.Error())
				}
				entries = append(entries, MapEntry{key: strings.Split(
					strings.Trim(result.Key, string(minUnicodeRuneValue)),
					string(minUnicodeRuneValue)), value: pbResult})
			}
		}
		i++
		if limit > 0 && i >= skip + limit { break }
	}

	return entries, nil
}



// --------------- Methods for STRING representation -------------


func (t *CouchChaincodeMap) PutStringState(stub shim.ChaincodeStubInterface, keys []string, value string) error {
	key, err := stub.CreateCompositeKey(t.prefix, keys)
	if err != nil { return errors.New("Cannot create composite key: " + err.Error()) }

	err = stub.PutState(key, []byte(value))

	if err == nil && t.calculateSize {
		err = t.IncrementSize(stub)
	}

	return err
}


func (t *CouchChaincodeMap) GetStringState(stub shim.ChaincodeStubInterface, keys []string) (string, error) {
	key, err := stub.CreateCompositeKey(t.prefix, keys)
	if err != nil { return "", errors.New("Cannot create composite key: " + err.Error()) }

	state, err := stub.GetState(key)
	if err != nil { return "", errors.New("Cannot get state: " + err.Error()) }

	return string(state), nil
}



// --------------- Methods for BYTES representation -------------


func (t *CouchChaincodeMap) PutBytesState(stub shim.ChaincodeStubInterface, keys []string, value []byte) error {
	key, err := stub.CreateCompositeKey(t.prefix, keys)
	if err != nil { return errors.New("Cannot create composite key: " + err.Error()) }

	err = stub.PutState(key, value)

	if err == nil && t.calculateSize {
		err = t.IncrementSize(stub)
	}

	return err
}


func (t *CouchChaincodeMap) GetBytesState(stub shim.ChaincodeStubInterface, keys []string) ([]byte, error) {
	key, err := stub.CreateCompositeKey(t.prefix, keys)
	if err != nil { return nil, errors.New("Cannot create composite key: " + err.Error()) }

	state, err := stub.GetState(key)
	if err != nil { return nil, errors.New("Cannot get state: " + err.Error()) }

	return state, nil
}


func (t *CouchChaincodeMap) GetMapBytesEntries(stub shim.ChaincodeStubInterface, keys []string) ([]MapEntry, error) {
	return t.GetMapBytesEntriesPage(stub, keys, 0,0)
}

func (t *CouchChaincodeMap) GetMapBytesEntriesPage(stub shim.ChaincodeStubInterface, keys []string, skip int32, limit int32) ([]MapEntry, error) {

	var entries []MapEntry
	var i int32 = 0

	iterator, err := stub.GetStateByPartialCompositeKey(t.prefix, keys); if err != nil { return nil, errors.New("Cannot query states: " + err.Error()) }

	for iterator.HasNext() {
		result, err := iterator.Next();  if err != nil { return nil, errors.New("Cannot query states: " + err.Error()) }

		if i >= skip {
			if result != nil && result.Value != nil {
				entries = append(entries, MapEntry{key:strings.Split(result.Key, string(minUnicodeRuneValue)), value:result.Value})
			}
		}
		i++
		if limit > 0 && i >= skip + limit { break }
	}

	return entries, nil
}


// -------- Size methods ---------------------------


func (t *CouchChaincodeMap) DecrementSize(stub shim.ChaincodeStubInterface) error {
	return t.modifySize(stub, -1)
}


func (t *CouchChaincodeMap) IncrementSize(stub shim.ChaincodeStubInterface) error {
	return t.modifySize(stub, 1)
}


func (t *CouchChaincodeMap) modifySize(stub shim.ChaincodeStubInterface, valueToAdd int32) error {

	size, err := t.GetSize(stub)
	if err != nil {
		return err
	}

	return t.PutSize(stub, size + valueToAdd)
}

func (t *CouchChaincodeMap) GetSize(stub shim.ChaincodeStubInterface) (size int32, err error) {
	sizeBytes, err := stub.GetState(t.SizeKey()); if err != nil { return -1, err }
	buf := new(bytes.Buffer)
	buf.Read(sizeBytes)
	binary.Read(buf, binary.LittleEndian, &size)
	return
}

func (t *CouchChaincodeMap) PutSize(stub shim.ChaincodeStubInterface, size int32) error {
	buf := new(bytes.Buffer)
	err := binary.Write(buf, binary.LittleEndian, size); if err != nil { return err }

	return stub.PutState(t.SizeKey(), buf.Bytes())
}

func (t *CouchChaincodeMap) SizeKey() string {
	return t.prefix + ".size"
}