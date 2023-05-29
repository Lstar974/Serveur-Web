FROM debian:11

# Installation des dépendances
RUN apt-get update && apt-get install -y \
    apache2 \
    mariadb-server \
    php \
    php-mysql \
    git \
    openssl \
    wget

# Clonage du repo Github
RUN git clone https://github.com/Lstar974/site.git /var/www/montp2.obtusk.com

# Ajout du propriétaire du site
RUN chown -R www-data:www-data /var/www/montp2.obtusk.com/

# Création du dossier password
RUN mkdir /etc/apache2/password

# Ajout de l'utilisateur au fichier .htpasswd
RUN htpasswd -c /etc/apache2/password/.htpasswd lucas

# Création du dossier web
RUN mkdir /etc/web

# Création du dossier serveur
RUN mkdir /etc/web/serveur

# Création du dossier traefik
RUN mkdir /etc/web/serveur/traefik

# Création du fichier acme.json
RUN touch /etc/web/serveur/traefik/acme.json

# Attribution des droits sur le fichier acme.json
RUN chmod 600 /etc/web/serveur/traefik/acme.json

# Configuration du fichier de configuration Traefik
RUN echo 'global:\n\
  checkNewVersion: true\n\
  sendAnonymousUsage: false\n\
api:\n\
  dashboard: true\n\
  insecure: false\n\
\n\
entryPoints:\n\
  web:\n\
    address: :80\n\
    http:\n\
       redirections:\n\
         entryPoint:\n\
           to: websecure\n\
           scheme: https\n\
\n\
  websecure:\n\
    address: :443\n\
\n\
certificatesResolvers:\n\
   selfsigned:\n\
     acme:\n\
       email: lucas.buchle@gmail.com\n\
       storage: acme.json\n\
       caServer: "https://acme-staging-v02.api.letsencrypt.org/directory"\n\
       httpChallenge:\n\
         entryPoint: web\n\
\n\
providers:\n\
  docker:\n\
    exposedByDefault: false\n\
  file:\n\
    directory: /traefik\n\
    watch: true' > /etc/web/serveur/traefik/traefik.yml
          


# Ajout du fichier de routage traefik
RUN echo '---\n\
services:\n\
  traefik:\n\
    image: traefik:v2.5\n\
    container_name: traefik\n\
    ports:\n\
      - 80:80\n\
      - 443:443\n\
    \n\
    volumes:\n\
      - /traefik:/traefik\n\
      - /var/run/docker.sock:/var/run/docker.sock:ro\n\
    restart: unless-stopped\n\
    command:\n\
      - "--api.insecure=false"\n\
      - "--providers.docker=true"\n\
      - "--providers.docker.exposedbydefault=false"\n\
      - "--entrypoints.web.address=:80"\n\
      - "--entrypoints.websecure.address=:443"\n\
      - "--certificatesresolvers.myresolver.acme.email=lucas.buchle@gmail.com"\n\
      - "--certificatesresolvers.myresolver.acme.storage=/root/traefik/acme.json"\n\
      - "--certificatesresolvers.myresolver.acme.tlschallenge=true"\n\
  apache:\n\
    image: httpd:latest\n\
    container_name: apache\n\
    labels:\n\
      - "traefik.http.routers.apache.rule=Host(`montp2.obtusk.com`)"\n\
      - "traefik.enable=true"\n\
      - "traefik.http.routers.apache.entrypoints=websecure"\n\
      - "traefik.http.routers.apache.tls=true"\n\
      - "traefik.http.routers.apache.tls.certresolver=selfsigned"\n\
    volumes:\n\
      - /var/www/montp2.obtusk.com:/usr/local/apache2/htdocs\n\
    restart: unless-stopped' > /etc/web/serveur/traefik/docker-compose.yaml


# Ajout du fichier de configuration VirtualHost
RUN echo '<VirtualHost *:80>\n\
    ServerName montp2.obtusk.com\n\
    Redirect permanent / https://montp2.obtusk.com/\n\
</VirtualHost>\n\
\n\
<VirtualHost *:443>\n\
    ServerAdmin montp2.obtusk.com\n\
    ServerName montp2.obtusk.com\n\
    DocumentRoot /var/www/montp2.obtusk.com\n\
    <Directory /var/www/montp2.obtusk.com>\n\
        AllowOverride All\n\
        AuthType Basic\n\
        AuthName "Restricted Content"\n\
        AuthUserFile /etc/apache2/.htpasswd\n\
        Require valid-user\n\
        Require all granted\n\
    </Directory>\n\
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
EXPOSE 8080

# Démarrage d'Apache et de Traefik
CMD ["/bin/bash", "-c", "service apache2 start && /usr/local/bin/traefik --configfile /etc/traefik/conf/traefik.toml"]
