# Utiliser une image Ruby compatible (2.7)
FROM ruby:2.7

# Installer les packages requis pour la construction et l'exécution
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev libxml2-dev zlib1g-dev libmagic-dev libmagickwand-dev \
    libproj-dev libgeos-dev libcurl4-openssl-dev \
    libpq5 libxml2 zlib1g libmagic1 imagemagick \
    libgeos-c1v5 libjemalloc2 libcurl4 \
    nodejs yarn

# Configurer le répertoire de travail
WORKDIR /app

# Copier le code source dans le conteneur
COPY . .

# Préparer l’environnement de production
RUN if [ ! -f config/environments/production.rb ]; then \
        cp config/environments/production.rb.sample config/environments/production.rb; \
    fi

# Installer Bundler 2.4.22 et les gems
RUN gem install bundler -v 2.4.22 && bundle install

# Précompiler les assets
RUN RUBYOPT="-W0" bundle exec rake ci:fix_webpacker assets:precompile i18n:js:export \
    RAILS_DB_ADAPTER=nulldb RAILS_DB_PASSWORD=none RAILS_ENV=production NODE_OPTIONS=--openssl-legacy-provider

# Exposer le port Rails
EXPOSE 3000

# Démarrer le serveur Rails
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]