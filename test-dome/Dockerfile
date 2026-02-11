# syntax=docker/dockerfile:1
FROM --platform=$BUILDPLATFORM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /workspace
COPY . .
RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /workspace/target/app.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
