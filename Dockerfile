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
RUN openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 -subj "/C=US/ST=State/L=City/O=Organization/CN=montp2.obtusk.com" -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt

# Copie du fichier de configuration du virtualhost
COPY 000-default.conf /etc/apache2/sites-available/montp2.obtusk.com.conf

# Remplacement du contenu du fichier montp2.obtusk.com.conf par de nouvelles configurations
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    ServerName montp2.obtusk.com' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    Redirect permanent / https://montp2.obtusk.com/' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '</VirtualHost>' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '<VirtualHost *:443>' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    ServerName montp2.obtusk.com' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    SSLEngine on' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '    DocumentRoot /var/www/montp2.obtusk.com' >> /etc/apache2/sites-available/montp2.obtusk.com.conf \
    && echo '</VirtualHost>' >> /etc/apache2/sites-available/montp2.obtusk.com.conf

# Activer les modules Apache
RUN a2enmod ssl && a2ensite default-ssl

# Exposition des ports
EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
