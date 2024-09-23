#!/bin/bash

# Variables
TOMCAT_VERSION=9.0.80
TOMCAT_DIR=/opt/tomcat9
USER_TOMCAT=tomcat
DOWNLOAD_URL="https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

# Fonction pour afficher un message et sortir en cas d'erreur
function exit_if_error() {
  if [ $? -ne 0 ]; then
    echo "Erreur lors de l'exécution : $1"
    exit 1
  fi
}

# 1. Télécharger Apache Tomcat9
echo "Téléchargement de Tomcat version ${TOMCAT_VERSION}..."
cd /tmp
wget ${DOWNLOAD_URL}
exit_if_error "Échec du téléchargement"

# 2. Extraire l'archive
echo "Extraction de Tomcat..."
tar -xvzf apache-tomcat-${TOMCAT_VERSION}.tar.gz
exit_if_error "Échec de l'extraction"

# 3. Déplacer Tomcat dans le répertoire approprié
echo "Déplacement de Tomcat vers ${TOMCAT_DIR}..."
sudo mv apache-tomcat-${TOMCAT_VERSION} ${TOMCAT_DIR}
exit_if_error "Échec du déplacement de Tomcat"

# 4. Créer un utilisateur Tomcat
echo "Création de l'utilisateur et groupe ${USER_TOMCAT}..."
sudo useradd -r -m -U -d ${TOMCAT_DIR} -s /bin/false ${USER_TOMCAT}
sudo chown -R ${USER_TOMCAT}:${USER_TOMCAT} ${TOMCAT_DIR}
sudo chmod -R 755 ${TOMCAT_DIR}
exit_if_error "Échec de la création de l'utilisateur Tomcat"

# 5. Créer le fichier de service systemd
echo "Création du fichier de service systemd pour Tomcat..."
sudo bash -c "cat > /etc/systemd/system/tomcat.service <<EOL
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=${USER_TOMCAT}
Group=${USER_TOMCAT}

Environment=\"JAVA_HOME=/usr/lib/jvm/default-java\"
Environment=\"CATALINA_PID=${TOMCAT_DIR}/temp/tomcat.pid\"
Environment=\"CATALINA_HOME=${TOMCAT_DIR}\"
Environment=\"CATALINA_BASE=${TOMCAT_DIR}\"
Environment=\"CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC\"
Environment=\"JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom\"

ExecStart=${TOMCAT_DIR}/bin/startup.sh
ExecStop=${TOMCAT_DIR}/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
EOL"
exit_if_error "Échec de la création du fichier systemd"

# 6. Recharger systemd et démarrer Tomcat
echo "Rechargement de systemd et démarrage de Tomcat..."
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat
exit_if_error "Échec du démarrage de Tomcat"

# 7. Vérification du statut de Tomcat
echo "Vérification du statut de Tomcat..."
sudo systemctl status tomcat --no-pager

echo "Installation de Tomcat9 terminée avec succès !"
