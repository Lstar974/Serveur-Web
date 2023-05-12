FROM debian:11

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    git

# Configuration de MariaDB
COPY mariadb-config /etc/mysql/
RUN service mysql start && mysql -e "CREATE DATABASE IF NOT EXISTS matomo;" && mysql -e "CREATE USER 'matomo'@'localhost' IDENTIFIED BY 'password';" && mysql -e "GRANT ALL PRIVILEGES ON matomo.* TO 'matomo'@'localhost';"

# Clonage du repo Github
RUN git clone https://github.com/Lstar974/site.git /var/www/montp2.obtusk.com

# Exposition des ports
EXPOSE 80
EXPOSE 443

CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
