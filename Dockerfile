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

# Génération du certificat auto-signé
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=US/ST=State/L=City/O=Organization/CN=montp2.obtusk.com" -keyout apache-selfsigned.key -out apache-selfsigned.crt

# Création du fichier de configuration du virtualhost
RUN echo '<VirtualHost *:80>' > montp2.obtusk.com.conf \
    && echo '    ServerName montp2.obtusk.com' >> montp2.obtusk.com.conf \
    && echo '    Redirect permanent / https://montp2.obtusk.com/' >> montp2.obtusk.com.conf \
    && echo '</VirtualHost>' >> montp2.obtusk.com.conf \
    && echo '<VirtualHost *:443>' >> montp2.obtusk.com.conf \
    && echo '    ServerName montp2.obtusk.com' >> montp2.obtusk.com.conf \
    && echo '    SSLEngine on' >> montp2.obtusk.com.conf \
    && echo '    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt' >> montp2.obtusk.com.conf \
    && echo '    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key' >> montp2.obtusk.com.conf \
    && echo '    DocumentRoot /var/www/montp2.obtusk.com' >> montp2.obtusk.com.conf \
    && echo '</VirtualHost>' >> montp2.obtusk.com.conf

# Activer les modules Apache
RUN a2enmod ssl

# Désactiver les fichiers de configuration par défaut
RUN a2dissite 000-default.conf default-ssl.conf

# Activer le fichier montp2.obtusk.com.conf
RUN a2ensite montp2.obtusk.com.conf

# Exposition des ports
EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
