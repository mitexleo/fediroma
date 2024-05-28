####################################
# BUILD CONTAINER
####################################

FROM hexpm/elixir:1.16.3-erlang-26.2.5-alpine-3.19.1 AS BUILD

ENV MIX_ENV=prod

RUN mkdir /src
WORKDIR /src
RUN apk add git gcc g++ musl-dev make cmake file-dev exiftool ffmpeg imagemagick libmagic ncurses postgresql-client
RUN mix local.hex --force &&\
    mix local.rebar --force

ADD mix.exs /src/mix.exs
ADD mix.lock /src/mix.lock
ADD lib/ /src/lib/
ADD priv/ /src/priv/
ADD config/ /src/config/
ADD rel/ /src/rel/
ADD restarter/ /src/restarter/
ADD docs/ /src/docs/
ADD installation/ /src/installation/

RUN mix deps.get --only=prod
RUN mix release --path docker-release

#################################
# RUNTIME CONTAINER
#################################

FROM alpine:3.19.1

RUN apk add file-dev exiftool ffmpeg imagemagick libmagic postgresql-client

LABEL org.opencontainers.image.title="akkoma" \
    org.opencontainers.image.description="Akkoma for Docker" \
    org.opencontainers.image.vendor="akkoma.dev" \
    org.opencontainers.image.documentation="https://docs.akkoma.dev/stable/" \
    org.opencontainers.image.licenses="AGPL-3.0" \
    org.opencontainers.image.url="https://akkoma.dev" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE

ARG HOME=/opt/akkoma
EXPOSE 4000

ARG UID=1000
ARG GID=1000
ARG UNAME=akkoma

RUN addgroup -g $GID $UNAME
RUN adduser -u $UID -G $UNAME -D -h $HOME $UNAME

WORKDIR /opt/akkoma

COPY --from=BUILD /src/docker-release/ $HOME
RUN ln -s $HOME/bin/pleroma /bin/pleroma
# it's nice you know
RUN ln -s $HOME/bin/pleroma /bin/akkoma
RUN ln -s $HOME/bin/pleroma_ctl /bin/pleroma_ctl
RUN ln -s $HOME/bin/pleroma_ctl /bin/akkoma_ctl

ADD docker-entrypoint.sh $HOME/docker-entrypoint.sh

USER $UNAME

CMD ["/opt/akkoma/docker-entrypoint.sh"]
