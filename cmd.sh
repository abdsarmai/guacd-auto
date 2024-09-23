#!/bin/bash

# Mettre à jour les paquets et installer les dépendances
apt-get update
apt-get install -y build-essential libcairo2-dev libjpeg62-turbo-dev libpng-dev libtool-bin uuid-dev libossp-uuid-dev \
libavcodec-dev libavformat-dev libavutil-dev libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev \
libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev libwebp-dev

# Téléchargement et compilation de la partie "Server" d'Apache Guacamole (version 1.5.5)
cd /tmp
wget https://downloads.apache.org/guacamole/1.5.5/source/guacamole-server-1.5.5.tar.gz
tar -xzf guacamole-server-1.5.5.tar.gz
cd guacamole-server-1.5.5/
./configure --with-init-dir=/etc/init.d
make
make install

# Mettre à jour les liens avec les librairies
ldconfig

# Démarrer et activer le service guacd
systemctl daemon-reload
systemctl start guacd
systemctl enable guacd

# Vérifier le statut du service guacd
systemctl status guacd

# Créer les répertoires de configuration pour Guacamole
mkdir -p /etc/guacamole/{extensions,lib}

# Installer Tomcat9 pour l'interface web
apt-get install -y tomcat9 tomcat9-admin tomcat9-common tomcat9-user

# Téléchargement de la Web App d'Apache Guacamole (version 1.5.5)
cd /tmp
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-1.5.5.war
mv guacamole-1.5.5.war /var/lib/tomcat9/webapps/guacamole.war

# Redémarrer Tomcat9 et guacd
systemctl restart tomcat9 guacd

# Installation de MariaDB
apt-get install -y mariadb-server

# Sécuriser l'installation de MariaDB (vous pouvez personnaliser cette partie si nécessaire)
mysql_secure_installation

# Créer la base de données et l'utilisateur pour Guacamole
mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE guacadb;
CREATE USER 'guaca_nachos'@'localhost' IDENTIFIED BY 'P@ssword!';
GRANT SELECT,INSERT,UPDATE,DELETE ON guacadb.* TO 'guaca_nachos'@'localhost';
FLUSH PRIVILEGES;
EXIT;
MYSQL_SCRIPT

# Téléchargement de l'extension MySQL pour Apache Guacamole
cd /tmp
wget https://downloads.apache.org/guacamole/1.5.5/binary/guacamole-auth-jdbc-1.5.5.tar.gz
tar -xzf guacamole-auth-jdbc-1.5.5.tar.gz
mv guacamole-auth-jdbc-1.5.5/mysql/guacamole-auth-jdbc-mysql-1.5.5.jar /etc/guacamole/extensions/

# Télécharger et installer le connecteur MySQL
cd /tmp
wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.0.33.tar.gz
tar -xzf mysql-connector-j-8.0.33.tar.gz
cp mysql-connector-j-8.0.33/mysql-connector-j-8.0.33.jar /etc/guacamole/lib/

# Importer la structure de la base de données Guacamole
cd guacamole-auth-jdbc-1.5.5/mysql/schema/
cat *.sql | mysql -u root -p guacadb

# Créer le fichier de configuration guacamole.properties
cat <<EOL > /etc/guacamole/guacamole.properties
mysql-hostname: 127.0.0.1
mysql-port: 3306
mysql-database: guacadb
mysql-username: guaca_nachos
mysql-password: P@ssword!
EOL

# Configurer le fichier guacd.conf
cat <<EOL > /etc/guacamole/guacd.conf
[server] 
bind_host = 0.0.0.0
bind_port = 4822
EOL

# Redémarrer les services Tomcat, Guacamole et MariaDB
systemctl restart tomcat9 guacd mariadb

echo "Installation d'Apache Guacamole 1.5.5 terminée avec succès !"
