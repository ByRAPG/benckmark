# Etapa 1: Compilación con Maven
FROM maven:3.9-eclipse-temurin-21-alpine AS builder

WORKDIR /app

# Cachea las dependencias de pom.xml
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copia el código y empaqueta el JAR
COPY src ./src
RUN mvn package -DskipTests -B

# Etapa 2: Runtime JRE ligero
FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]