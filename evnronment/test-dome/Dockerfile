# -------------------------
# Multi-stage build
# -------------------------
# Builder stage: build the JAR
FROM maven:3.9-eclipse-temurin-17 AS builder

WORKDIR /build

# Copy Maven project files
COPY pom.xml .
COPY src ./src

# Build the application (skip tests)
RUN mvn clean package -DskipTests -q

# -------------------------
# Runtime stage
# -------------------------
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copy the fat JAR from builder stage
COPY --from=builder /build/target/app.jar app.jar

# Expose the application port
EXPOSE 8080

# Start the application using exec form (correct quotes)
ENTRYPOINT ["java", "-jar", "app.jar"]
