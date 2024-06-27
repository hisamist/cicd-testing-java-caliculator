# Utilisez une image OpenJDK officielle compatible ARM64
FROM openjdk:11-jre-slim

# Argument pour le fichier JAR
ARG JAR_FILE=target/calculator.jar

# Définir le répertoire de travail
WORKDIR /opt/app

# Copier le fichier JAR dans le conteneur
COPY ${JAR_FILE} calculator.jar

# Copier le script d'entrée dans le conteneur 
COPY entrypoint.sh entrypoint.sh

# Donner les permissions d'exécution au script d'entrée
RUN chmod +x entrypoint.sh

# Définir le script d'exécution
ENTRYPOINT ["./entrypoint.sh"]
