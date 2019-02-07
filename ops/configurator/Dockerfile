#steps to get OpenJDK8
FROM alpine:3.9
ENV LANG C.UTF-8
RUN { \
                echo '#!/bin/sh'; \
                echo 'set -e'; \
                echo; \
                echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
        } > /usr/local/bin/docker-java-home \
        && chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin
ENV JAVA_VERSION 8u191
ENV JAVA_ALPINE_VERSION 8.191.12-r0
RUN set -x \
        && apk add --no-cache \
                openjdk8="$JAVA_ALPINE_VERSION" \
        && [ "$JAVA_HOME" = "$(docker-java-home)" ]

#fabric-skeleton specific configuration

COPY fabric-configurator-1.2.16.jar fabric-configurator-1.2.16.jar
COPY network network
COPY chaincodes chaincodes
COPY fabric.yaml fabric.yaml
CMD java -cp fabric-configurator-1.2.16.jar com.luxoft.fabric.config.Configurator --type config
EXPOSE 8090