# Multi-stage build
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

# Copy pom.xml and source
COPY pom.xml .
COPY src ./src

# Build the application - Maven will create the fat JAR with spring-boot-maven-plugin
RUN mvn clean package -DskipTests -q

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copy the executable JAR from builder
# The build uses a fixed finalName of app
COPY --from=builder /build/target/app.jar app.jar

# ⚠️ jar command does not exist in JRE, remove or switch to JDK if you want this check
# RUN jar tf app.jar | grep -i manifest && echo "JAR is valid"

EXPOSE 8080

# Use exec form to ensure proper signal handling
ENTRYPOINT ["java", "-jar", "app.jar"]
