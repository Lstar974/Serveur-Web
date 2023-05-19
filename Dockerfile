FROM debian:11

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    git \
    openssl

# Configuration de MariaDB
COPY mariadb-config /etc/mysql/
RUN service mariadb start && mysql -e "CREATE DATABASE IF NOT EXISTS matomo;" && mysql -e "CREATE USER 'lucas'@'localhost' IDENTIFIED BY '1234';" && mysql -e "GRANT ALL PRIVILEGES ON matomo.* TO 'lucas'@'localhost';"

# Clonage du repo Github
RUN git clone https://github.com/Lstar974/site.git /var/www/montp2.obtusk.com

# Ajout de l'utilsateur au fichier .htpasswd
RUN  htpasswd -c /etc/apache2/.htpasswd lucas

# Création du dossier pour le certificat et la clé
RUN mkdir /etc/keys

# Génération d'une clé privée
RUN openssl genpkey -algorithm RSA -out /etc/keys/montp2.obtusk.com.key

# Génération d'une demande certificat avec sujet spécifié
RUN openssl req -new -key /etc/keys/montp2.obtusk.com.key -out /etc/keys/montp2.obtusk.com.csr -subj "/CN=montp2.obtusk.com"

# Auto-signature du certificat
RUN openssl x509 -req -days 365 -in /etc/keys/montp2.obtusk.com.csr -signkey /etc/keys/montp2.obtusk.com.key -out /etc/keys/montp2.obtusk.com.crt

# Création du fichier de configuration du virtualhost
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    ServerName montp2.obtusk.com' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    Redirect permanent / https://montp2.obtusk.com/' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '</VirtualHost>' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '<VirtualHost *:443>' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    ServerName montp2.obtusk.com' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    DocumentRoot /var/www/'Site futur'' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '  <DocumentRoot /var/www/'Site futur'>' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    AllowOverride All' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    AuthType Basic' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    AuthUserFile /etc/apache2/.htpasswd' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    Require valid-user' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    Require all granted' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    </Directory>' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    SSLEngine on' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    SSLCertificateFile /etc/keys/montp2.obtusk.com.crt' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    SSLCertificateKeyFile /etc/keys/montp2.obtusk.com.key' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    DocumentRoot /var/www/montp2.obtusk.com' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '</VirtualHost>' >> /etc/apache2/sites-available/montp2.obtusk.com.conf

# Désactiver les fichiers de configuration par défaut
RUN a2dissite 000-default.conf default-ssl.conf

# Activer le fichier montp2.obtusk.com.conf
RUN a2ensite montp2.obtusk.com.conf

# Activer le module SSL
RUN a2enmod ssl

# Exposition des ports
EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
