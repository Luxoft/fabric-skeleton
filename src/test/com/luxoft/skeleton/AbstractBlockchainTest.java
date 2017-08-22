package com.luxoft.skeleton;

import com.luxoft.skeleton.fabric.SkeletonBlockchainConnector;
import com.luxoft.skeleton.fabric.SkeletonBlockchainConnectorFactory;
import com.luxoft.skeleton.fabric.proto.TestChaincode;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

/**
 * Blockchain tests ancestor
 */
public abstract class AbstractBlockchainTest {

    protected void sanityCheck(String configPath, String channelId) throws Exception {
        String NAME = "name:" + System.currentTimeMillis();


        TestChaincode.Entity entity = TestChaincode.Entity.newBuilder()
                .setName(NAME)
                .setDescription("description1")
                .setType(TestChaincode.Type.COMPANY)
                .build();

        SkeletonBlockchainConnector blockchain = SkeletonBlockchainConnectorFactory.create(channelId, configPath);

        TestChaincode.GetEntity entityRef = blockchain.putEntity(entity).get();

        assertNotNull("Null response received", entityRef);
        assertEquals(NAME, entityRef.getName());

        TestChaincode.Entity receivedEntity = blockchain.getEntity(entityRef).get();

        assertNotNull("Null response received", receivedEntity);
        assertEquals(entity.getName(), receivedEntity.getName());
        assertEquals(entity.getDescription(), receivedEntity.getDescription());
        assertEquals(entity.getType(), receivedEntity.getType());

        TestChaincode.History history = blockchain.getBalanceHistory(entityRef).get();

        assertNotNull("Null response received", history);
        assertEquals(entityRef.getName(), history.getKey());
        assertEquals(1, history.getHistoryCount());
    }
}
