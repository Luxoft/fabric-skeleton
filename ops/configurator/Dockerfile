#steps to get OpenJDK8
FROM openjdk:8-alpine
#Workaround to avoid exeptions formn netty
RUN ln -s  /lib/libcrypto.so.1.1 /lib/libcrypt.so.1
#fabric-skeleton specific configuration

COPY fabric-configurator-fat-1.4.0.jar fabric-configurator-fat-1.4.0.jar
COPY network network
COPY chaincodes chaincodes
COPY fabric.yaml fabric.yaml
CMD java -cp fabric-configurator-fat-1.4.0.jar com.luxoft.fabric.config.Configurator --type config
EXPOSE 8090