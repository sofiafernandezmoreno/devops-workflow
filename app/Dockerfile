# ========= Build stage =========
FROM maven:3.9-eclipse-temurin-21 AS build

WORKDIR /app

COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Download dependencies to cache them
RUN ./mvnw dependency:go-offline -B

COPY src src

# Build the application
RUN ./mvnw package -DskipTests -B


# ========= Runtime stage =========
FROM eclipse-temurin:21-jre-alpine

RUN addgroup -S spring && adduser -S spring -G spring

WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

USER spring

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
