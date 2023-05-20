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

# Ajout du propriétaire du site
RUN chown -R www-data:www-data /var/www/montp2.obtusk.com/Site\ futur

# Ajout de l'utilsateur au fichier .htpasswd
RUN  htpasswd -c /etc/apache2/.htpasswd lucas

# Création du dossier secure
RUN mkdir /etc/secure

# Création du dossier pour le certificat et la clé
RUN mkdir /etc/secure/keys

# Génération d'une clé privée
RUN openssl genpkey -algorithm RSA -out /etc/secure/keys/montp2.obtusk.com.key

# Création du fichier de configuration du virtualhost
RUN echo '<VirtualHost *:80>\n\
    ServerName montp2.obtusk.com\n\
    Redirect permanent / https://montp2.obtusk.com/\n\
</VirtualHost>\n\
\n\
<VirtualHost *:443>\n\
    ServerName montp2.obtusk.com\n\
    DocumentRoot /var/www/montp2.obtusk.com\n\
\n\
    <Directory /var/www/montp2.obtusk.com>\n\
        AllowOverride All\n\
        AuthType Basic\n\
        AuthUserFile /etc/apache2/.htpasswd\n\
        Require valid-user\n\
        Require all granted\n\
    </Directory>\n\
\n\
    SSLEngine on\n\
    SSLCertificateFile /etc/keys/montp2.obtusk.com.crt\n\
    SSLCertificateKeyFile /etc/keys/montp2.obtusk.com.key\n\
</VirtualHost>' > /etc/apache2/sites-available/montp2.obtusk.com.conf
    
# Ajout du propriétaire
RUN chown -R www-data:www-data /etc/apache2/sites-available/montp2.obtusk.com.conf

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
