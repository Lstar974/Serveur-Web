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

# Création du dossier traefik
RUN mkdir /etc/traefik

# Création du dossier conf
RUN mkdir /etc/traefik/conf

# Configuration du fichier de configuration Traefik
RUN echo '[accesslog]\n\
[api]\n\
  insecure=true\n\
  dashboard=true\n\
  debug=true\n\
[log]\n\
  level="INFO"\n\
[entryPoints]\n\
  [entryPoints.obtusk]\n\
    address=":80"\n\
    [entryPoints.obtusk.http.redirections]\n\
      [entryPoints.obtusk.http.redirections.entryPoint]\n\
        to = "obtusk_secure"\n\
        scheme = "https"\n\
\n\
  [entryPoints.obtusk_secure]\n\
    address=":443"\n\
\n\
[providers.file]\n\
  directory = "/root/"\n\
  watch = true\n\
\n\
[certificatesResolvers]\n\
  [certificatesResolvers.obtusk_certs]\n\
    [certificatesResolvers.obtusk_certs.acme]\n\
      email = "lucas.buchle@gmail.com"\n\
      caServer = "https://acme-v02.api.letsencrypt.org/directory"\n\
      storage = "acme.json"\n\
      keyType = "EC384"\n\
        [certificatesResolvers.obtusk_certs.acme.httpChallenge]\n\
          entryPoint = "obtusk"' > /etc/traefik/conf/traefik.toml
          


# Ajout du fichier de routage traefik
RUN echo '[http]\n\
  [http.routers]\n\
    [http.routers.obtusk_route]\n\
      entryPoints = ["obtusk_secure"]\n\
      service = "obtusk"\n\
      rule = "Host(`obtusk.com`) && Path(`/`)"\n\
      middlewares = ["obtusk_https"]\n\
      [http.routers.obtusk_route.tls]\n\
        certResolver = "obtusk_certs"\n\
  [http.middlewares]\n\
    [http.middlewares.obtusk_https.redirectScheme]\n\
       scheme = "https"\n\
       permanent = true\n\
\n\
  [http.services]\n\
    [http.services.obtusk]\n\
      [http.services.obtusk.loadBalancer]\n\
        [[http.services.obtusk.loadBalancer.servers]]\n\
          url = "http://montp2.obtusk.com"' > /etc/traefik/conf/traefik_dynamic.toml


# Ajout du fichier de configuration VirtualHost
RUN echo '<VirtualHost *:80>\n\
    ServerName montp2.obtusk.com\n\
    Redirect permanent / https://montp2.obtusk.com/\n\
</VirtualHost>\n\
\n\
<VirtualHost *:443>\n\
    ServerName montp2.obtusk.com\n\
    DocumentRoot /var/www/montp2.obtusk.com\n\
    <Directory /var/www/montp2.obtusk.com>\n\
        Options Indexes FollowSymLinks MultiViews\n\
        AllowOverride All\n\
        Order allow,deny\n\
        allow from all\n\
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
