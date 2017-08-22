package com.luxoft.skeleton.fabric;

import com.luxoft.fabric.FabricConfig;
import org.hyperledger.fabric.sdk.User;


/**
 * Blockchain connector factory
 */
public class SkeletonBlockchainConnectorFactory {

    private SkeletonBlockchainConnectorFactory() {
        throw new IllegalStateException("Factory class");
    }

    /**
     * Create connector
     * @param user user
     * @param channelId channel id
     * @param configPath config path
     * @return the connector
     */
    public static SkeletonBlockchainConnector create(User user, String channelId, String configPath) {
        try {
            return new SkeletonBlockchainConnector(user, channelId, FabricConfig.getConfigFromFile(configPath));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    /**
     * Null user stands for Admin which will be taken automatically from FabricConfig
     * @return the connector
     */
    public static SkeletonBlockchainConnector create(String channelId, String configPath) {
        return create(null, channelId, configPath);
    }
}
