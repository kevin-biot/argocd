# ===== Stage 1: Build the WAR with Maven =====
FROM docker.io/library/maven:3.9.6-eclipse-temurin-17 AS builder

RUN mkdir -p /usr/share/maven/ref/ && \
    echo '<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 https://maven.apache.org/xsd/settings-1.0.0.xsd">\
    <mirrors>\
        <mirror>\
            <id>central</id>\
            <name>Maven Central</name>\
            <url>https://repo.maven.apache.org/maven2</url>\
            <mirrorOf>central</mirrorOf>\
        </mirror>\
    </mirrors>\
    </settings>' > /usr/share/maven/ref/settings.xml

WORKDIR /build
COPY pom.xml .
RUN mvn -B -s /usr/share/maven/ref/settings.xml dependency:go-offline

COPY src ./src
RUN mvn -B -s /usr/share/maven/ref/settings.xml clean package -DskipTests

# ===== Stage 2: Runtime with Tomcat =====
FROM docker.io/library/tomcat:9.0.85-jdk17

# Install unzip for WAR extraction
USER root
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/*

# Clean Tomcat default apps and unpack WAR
RUN rm -rf /usr/local/tomcat/webapps/*
COPY --from=builder /build/target/java-webapp.war /tmp/
RUN unzip -q /tmp/java-webapp.war -d /usr/local/tomcat/webapps/ROOT && \
    rm -f /tmp/java-webapp.war && \
    chown -R 1001:0 /usr/local/tomcat/webapps && \
    chmod -R g+rwX /usr/local/tomcat/webapps

# ✅ Now drop to unprivileged user
USER 1001

EXPOSE 8080
