FROM node:9-alpine

ENV BETB_SNAPSHOT_PATH /app/registrySnapshots

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
VOLUME "${BETB_SNAPSHOT_PATH}"

# setup Cron job
# CMD [0 * * * *	/home/ingo/dev/BracketsExtensionTweetBot/bin/btb.sh]
CMD ["sh"]