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

# Configuration de Traefik
RUN wget -O /usr/local/bin/traefik https://github.com/traefik/traefik/releases/tag/v2.10.1/traefik_v2.10.1_linux_amd64
RUN chmod +x /usr/local/bin/traefik

# Création du dossier traefik
RUN mkdir /etc/traefik

# Création du dossier conf
RUN mkdir /etc/traefik/conf

# Configuration du fichier de configuration Traefik
RUN echo 'logLevel = "INFO"\n\
[entryPoints]\n\
  [entryPoints.web]\n\
    address = ":80"\n\
  [entryPoints.web-secure]\n\
    address = ":443"\n\
\n\
# Certificats\n\
[certificatesResolvers.myresolver.acme]\n\
  email = "lucas.buchle@gmail.com"\n\
  storage = "acme.json"\n\
  [certificatesResolvers.myresolver.acme.httpChallenge]\n\
    entryPoint = "web"\n\
\n\
# Routage\n\
[http.middlewares]\n\
  [http.middlewares.redirect-to-https.redirectScheme]\n\
    scheme = "https"\n\
\n\
[http.routers]\n\
  [http.routers.http-to-https]\n\
    rule = "HostRegexp(`{host:.+}`)"\n\
    entryPoints = ["web"]\n\
    middlewares = ["redirect-to-https.redirectScheme"]\n\
\n\
  [http.routers.app]\n\
    rule = "HostRegexp(`{host:.+}`)"\n\
    entryPoints = ["web-secure"]\n\
    service = "app@internal"\n\
    middlewares = ["auth"]\n\
    [http.routers.app.tls]\n\
      certResolver = "myresolver"\n\
\n\
[http.services]\n\
  [http.services.app.loadBalancer]\n\
    [[http.services.app.loadBalancer.servers]]\n\
      url = "http://localhost"\n\
\n\
[http.middlewares]\n\
  [http.middlewares.auth.basicAuth]\n\
    usersFile = "/etc/traefik/.htpasswd"' > /etc/traefik/conf/traefik.toml

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
\n\
    SSLEngine on\n\
\n\
    <FilesMatch "\.(cgi|shtml|phtml|php)$">\n\
        SSLOptions +StdEnvVars\n\
    </FilesMatch>\n\
\n\
    BrowserMatch "MSIE [2-6]" \\\n\
        nokeepalive ssl-unclean-shutdown \\\n\
        downgrade-1.0 force-response-1.0\n\
    BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown\n\
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
