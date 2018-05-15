FROM node:9-alpine

ENV BETB_HOME         /opt/betb
ENV BETB_CONFIG_PATH  ${BETB_HOME}

MAINTAINER Ingo Richter <https:/github.com/ingorichter>

WORKDIR /app

# prepare to install deps
COPY package.json /app
RUN yarn

# copy app to their destination directory
COPY dist /app/dist
COPY bin /app/bin
COPY .env.example /app

# TODO(Ingo)
# - config location is momentan hard coded auf /opt/betb/.env an 2 verschiedenen Stellen
# - snapshot directory location erzeugen bzw durch Volume verfügbar machen
VOLUME "${BETB_HOME}" "/app/.env" "/app/registrySnapshots"

# setup Cron job

CMD ["sh"]