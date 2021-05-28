FROM alpine:3.10

LABEL MAINTAINER="PsykoCat <psykocat@nomail.local>"

# Set timezone
RUN apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/Europe/Paris /etc/localtime \
    && echo "Europe/Paris" > /etc/timezone \
    && date \
    && apk del tzdata

# Install tools and DB related clients
RUN apk add --no-cache \
      apache2-utils \
      bash \
      curl \
      grep \
      jq \
      sudo \
      tar \
      \
      mariadb-client \
      postgresql-client

RUN addgroup dbhandler && \
    adduser -D -g '' -s /bin/bash -G dbhandler dbhandler
RUN echo "dbhandler ALL=(ALL) NOPASSWD:/bin/chown,/bin/chmod" > /etc/sudoers.d/dbhandler


COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENV DBHANDLER_SCRIPTS_DIR="/opt/db-handler/scripts"
ENV DBHANDLER_BACKUP_DIR="/backup"
RUN mkdir -p ${DBHANDLER_SCRIPTS_DIR} ${DBHANDLER_BACKUP_DIR}
COPY scripts/ ${DBHANDLER_SCRIPTS_DIR}/

RUN chmod +x ${DBHANDLER_SCRIPTS_DIR}/*.sh /usr/local/bin/docker-entrypoint.sh

USER dbhandler

ENTRYPOINT [ "docker-entrypoint.sh" ]
