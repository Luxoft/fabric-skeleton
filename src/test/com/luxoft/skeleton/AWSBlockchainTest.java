package com.luxoft.skeleton;

import org.junit.Ignore;
import org.junit.Test;

@Ignore("Run manually on working cluster")
public class AWSBlockchainTest extends AbstractBlockchainTest {

    public static final String FABRIC_YAML_LOCATION = "ops/network_dist/fabric.yaml";

    @Test
    public void testAWS() throws Exception {
        sanityCheck(FABRIC_YAML_LOCATION, "org0channel");
    }
}
