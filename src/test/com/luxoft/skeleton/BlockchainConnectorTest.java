package com.luxoft.skeleton;


import com.luxoft.skeleton.fabric.SkeletonBlockchainConnector;
import com.luxoft.skeleton.fabric.SkeletonBlockchainConnectorFactory;
import com.luxoft.skeleton.fabric.proto.TestChaincode;
import org.junit.Test;


import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * Fabric integration test.
 * <p>
 * Network runs with help of gradle docker-compose plugin.
 */

public class BlockchainConnectorTest extends AbstractBlockchainTest {

    private static final Logger LOG = LoggerFactory.getLogger(BlockchainConnectorTest.class);



    @Test
    public void testGetPutEntity() throws Exception {


        LOG.info("Starting test");

        String name = "name:" + System.currentTimeMillis();


        TestChaincode.Entity entity = TestChaincode.Entity.newBuilder()
                .setName(name)
                .setDescription("description1")
                .setType(TestChaincode.Type.COMPANY)
                .build();

        SkeletonBlockchainConnector blockchain = SkeletonBlockchainConnectorFactory.create("testchannel", Launcher.CONFIG);

        putEntity(name, entity, blockchain);

    }

}
