# Stages
#
# debian:stable-slim
# -> base
#   -> assets-builder
#   -> final with COPY assets-builder/public/assets

# Create a production image for Chouette
#
# Usage (minimalist) :
# docker build -t chouette-core .
# docker run --add-host "db:172.17.0.1" -e RAILS_DB_PASSWORD=chouette -p 3000:3000 -it chouette-core

FROM ruby:2.7 AS base

WORKDIR /app

# Install bundler packages
COPY build.rc Gemfile Gemfile.lock ./
RUN build.sh docker::bundler::install

FROM base AS assets-builder

RUN build.sh apt::install::yarn

# Install yarn packages
COPY package.json yarn.lock ./
RUN build.sh yarn::install

# Install application file
COPY . ./

# Override database.yml and secrets.yml files
COPY config/database.yml.docker config/database.yml
COPY config/secrets.yml.docker config/secrets.yml
RUN build.sh docker::env::production

# Run assets:precompile
ARG SENTRY_AUTH_TOKEN
ARG VERSION
RUN build.sh docker::assets::precompile

FROM base AS final

# Install application file
COPY . ./

# Override database.yml and secrets.yml files
COPY config/database.yml.docker config/database.yml
COPY config/secrets.yml.docker config/secrets.yml
RUN build.sh docker::env::production

COPY --from=assets-builder /app/public/assets/ public/assets/
COPY --from=assets-builder /app/public/packs/ public/packs/

# Create version.json file if VERSION is available
ARG VERSION
RUN build.sh docker::version

RUN bundle exec bootsnap precompile --gemfile app/ lib/

VOLUME /app/public/uploads

EXPOSE 3000
ENV RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true RAILS_LOG_TO_STDOUT=true
ENV LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2

ENTRYPOINT ["./script/docker-entrypoint.sh"]
# Use front by default. async and sync 'modes' are available
CMD ["front"]
