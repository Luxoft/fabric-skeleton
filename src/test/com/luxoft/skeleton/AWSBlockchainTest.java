package com.luxoft.skeleton;

import com.luxoft.skeleton.fabric.SkeletonBlockchainConnector;
import com.luxoft.skeleton.fabric.SkeletonBlockchainConnectorFactory;
import com.luxoft.skeleton.fabric.proto.TestChaincode;
import org.junit.Ignore;
import org.junit.Test;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNotNull;

@Ignore("Run manually on working cluster")
public class AWSBlockchainTest {

    public static final String FABRIC_YAML_LOCATION = "ops/network_dist/fabric.yaml";

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

    @Test
    public void testAWS() throws Exception {
        sanityCheck(FABRIC_YAML_LOCATION, "org0channel");
    }
}
