# Multi-stage build
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

# Copy pom.xml and source
COPY pom.xml .
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests -q

# Runtime stage
FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

# Copy the executable JAR from builder
COPY --from=builder /build/target/app.jar app.jar

# Verify the JAR has the manifest
RUN jar tf app.jar | grep -i manifest && echo "JAR is valid"

EXPOSE 8080

# Start the app
ENTRYPOINT ["java", "-jar", "app.jar"]
