FROM alpine

LABEL \
  "name"="GitHub Cicle Release Action" \
  "homepage"="https://github.com/miquolone/actions/cicle-release" \
  "repository"="https://github.com/miquolone/cicle-release" \
  "maintainer"="miquolone <miquolone@noreply.github.com>"

RUN echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
  apk add --no-cache git hub bash

ADD *.sh /

ENTRYPOINT ["/pr.sh"]
