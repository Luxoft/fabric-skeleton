package com.luxoft.skeleton;


import com.luxoft.fabric.FabricConfig;
import com.luxoft.fabric.config.NetworkManager;
import com.luxoft.skeleton.fabric.SkeletonBlockchainConnector;
import com.luxoft.skeleton.fabric.SkeletonBlockchainConnectorFactory;
import com.luxoft.skeleton.fabric.proto.TestChaincode;
import org.junit.BeforeClass;
import org.junit.Test;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

/**
 * Fabric integration test.
 *
 * Network runs with help of gradle docker-compose plugin.
 */

public class BlockchainConnectorTest extends AbstractBlockchainTest {

    private static final Logger LOG = LoggerFactory.getLogger(BlockchainConnectorTest.class);

    @BeforeClass
    public static void beforeClass() throws IOException {
        LOG.info("Starting network configuration");
        NetworkManager.configNetwork(FabricConfig.getConfigFromFile(Launcher.CONFIG));
        LOG.info("Finished network configuration");
    }

    @Test
    public void testGetPutEntity() throws Exception {

        LOG.info("Starting test");

        String NAME = "name:" + System.currentTimeMillis();


        TestChaincode.Entity entity = TestChaincode.Entity.newBuilder()
                .setName(NAME)
                .setDescription("description1")
                .setType(TestChaincode.Type.COMPANY)
                .build();

        SkeletonBlockchainConnector blockchain = SkeletonBlockchainConnectorFactory.create("testchannel", Launcher.CONFIG);

        TestChaincode.GetEntity entityRef = blockchain.putEntity(entity).get();

        if (entityRef == null) {
            fail("Null response received");
        } else {
            assertEquals(NAME, entityRef.getName());
        }

        TestChaincode.Entity receivedEntity = blockchain.getEntity(entityRef).get();

        if (receivedEntity == null) {
            fail("Null response received");
        } else {
            assertEquals(entity.getName(), receivedEntity.getName());
            assertEquals(entity.getDescription(), receivedEntity.getDescription());
            assertEquals(entity.getType(), receivedEntity.getType());
        }
    }
}
