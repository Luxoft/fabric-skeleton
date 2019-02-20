package com.luxoft.skeleton;


import com.luxoft.skeleton.fabric.SkeletonBlockchainConnector;
import com.luxoft.skeleton.fabric.SkeletonBlockchainConnectorFactory;
import com.luxoft.skeleton.fabric.proto.TestChaincode;
import org.junit.Ignore;
import org.junit.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;


/**
 * Fabric integration test.
 *
 * Network runs with help of gradle docker-compose plugin.
 */
@Ignore(value = "Run manually if required")
public class LoadTest extends AbstractBlockchainTest {

    private static final Logger LOG = LoggerFactory.getLogger(LoadTest.class);
    private static final int NUMBER_OF_TRANSACTIONS = 100;

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

        for (int i = 0; i < NUMBER_OF_TRANSACTIONS; i++) {
            putEntity(name, entity, blockchain);
        }
    }

}
