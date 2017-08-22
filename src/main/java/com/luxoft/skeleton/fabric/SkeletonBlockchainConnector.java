package com.luxoft.skeleton.fabric;

import com.google.protobuf.InvalidProtocolBufferException;
import com.luxoft.fabric.FabricConfig;
import com.luxoft.fabric.FabricConnector;
import com.luxoft.skeleton.fabric.proto.TestChaincode;
import org.hyperledger.fabric.sdk.User;
import java.util.concurrent.CompletableFuture;



public class SkeletonBlockchainConnector extends FabricConnector {

    private static final String TEST_CHAINCODE_NAME = "testchaincode";



    public SkeletonBlockchainConnector(User user, String channelName, FabricConfig fabricConfig) throws Exception {
        super(user, channelName, fabricConfig);
    }


    public CompletableFuture<TestChaincode.GetEntity> putEntity(TestChaincode.Entity entity) {
        return buildTransactionFuture(buildProposalRequest("PutEntity", TEST_CHAINCODE_NAME, new byte[][]{entity.toByteArray()}))
                .thenApply(transactionEvent -> {

                    if (transactionEvent == null || !transactionEvent.isValid()) throw new RuntimeException("Transaction failure");

                    TestChaincode.GetEntity entityRef;

                    if (transactionEvent.getTransactionActionInfoCount() > 0) {
                        try {
                            byte[] responseBytes = transactionEvent.getTransactionActionInfo(0).getProposalResponsePayload();
                            entityRef = TestChaincode.GetEntity.parseFrom(responseBytes);
                        } catch (InvalidProtocolBufferException e) {
                            throw new RuntimeException(e);
                        }
                    } else throw new RuntimeException("Empty transaction info count");

                    return entityRef;
                });
    }

    public CompletableFuture<TestChaincode.Entity> getEntity(TestChaincode.GetEntity eventId) {
        return query("GetEntity", TEST_CHAINCODE_NAME, eventId.toByteArray()).thenApply((query) -> {
            try {
                return TestChaincode.Entity.parseFrom(query);
            } catch (InvalidProtocolBufferException e) {
                throw new RuntimeException(e);
            }
        });
    }

    public CompletableFuture<TestChaincode.History> getBalanceHistory(TestChaincode.GetEntity message) {
        return query("GetHistory", TEST_CHAINCODE_NAME, message.toByteArray()).thenApply((query) -> {
            try {
                return TestChaincode.History.parseFrom(query);
            } catch (InvalidProtocolBufferException e) {
                throw new RuntimeException(e);
            }
        });
    }
}
