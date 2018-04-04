FROM frolvlad/alpine-oraclejdk8
MAINTAINER Nikita Volkov
COPY fabric-configurator-1.2.16.jar fabric-configurator-1.2.16.jar
COPY network network
COPY chaincodes chaincodes
COPY fabric.yaml fabric.yaml
CMD java -cp fabric-configurator-1.2.16.jar com.luxoft.fabric.config.Configurator --type config
EXPOSE 8090