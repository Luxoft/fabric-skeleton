package com.luxoft.skeleton;

import com.luxoft.fabric.FabricConfig;
import com.luxoft.fabric.config.NetworkManager;
import com.luxoft.skeleton.fabric.SkeletonBlockchainConnector;
import com.luxoft.skeleton.fabric.proto.TestChaincode;
import org.junit.BeforeClass;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;

import static org.junit.Assert.*;
import static org.junit.Assert.fail;

/**
 * Blockchain tests ancestor
 */
public abstract class AbstractBlockchainTest {

    private static final Logger LOG = LoggerFactory.getLogger(AbstractBlockchainTest.class);

    @BeforeClass
    public static void beforeClass() throws IOException {
        LOG.info("Starting network configuration");
        NetworkManager.configNetwork(FabricConfig.getConfigFromFile(Launcher.CONFIG));
        LOG.info("Finished network configuration");
    }

    protected void putEntity(String NAME, TestChaincode.Entity entity, SkeletonBlockchainConnector blockchain) throws InterruptedException, java.util.concurrent.ExecutionException {
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
