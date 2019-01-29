package com.luxoft.skeleton;


import com.luxoft.skeleton.fabric.SkeletonBlockchainConnector;
import com.luxoft.skeleton.fabric.SkeletonBlockchainConnectorFactory;
import com.luxoft.skeleton.fabric.proto.TestChaincode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Entry point of app
 */
public class Launcher {

    public static String CONFIG = "fabric-devnet.yaml";

    private static final Logger logger = LoggerFactory.getLogger(Launcher.class);

    public static void main(String[] args) throws Exception {

        logger.info("Application started");

        SkeletonBlockchainConnector blockchain = SkeletonBlockchainConnectorFactory.create("testchannel", CONFIG);

        TestChaincode.Entity entity = TestChaincode.Entity.newBuilder()
                .setName("name")
                .setDescription("description1")
                .setType(TestChaincode.Type.COMPANY)
                .build();

        TestChaincode.GetEntity entityRef = blockchain.putEntity(entity).get();
        logger.info("Put entity: " + entityRef);

        TestChaincode.Entity receivedEntity = blockchain.getEntity(entityRef).get();
        logger.info("Receive entity: " + receivedEntity);
    }
}
