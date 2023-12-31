##############################################
# BUILD CONTAINER
##############################################

FROM hexpm/elixir:1.16.0-erlang-26.2.1-alpine-3.18.4 as BUILD

ENV MIX_ENV=prod

RUN apk add git gcc g++ musl-dev make cmake file-dev exiftool ffmpeg imagemagick libmagic ncurses postgresql-client

WORKDIR /src
ADD mix.exs mix.lock /src/
ADD ./restarter /src/restarter/
ADD ./priv /src/priv/
ADD ./installation /src/installation/
ADD ./rel /src/rel/
ADD ./config /src/config/
ADD ./docs /src/docs/
ADD ./lib /src/lib/

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix deps.get --only=prod

RUN mix release --path /release

#################################################
# RUNTIME CONTAINER
#################################################
FROM alpine:3.18
ENV ERL_EPMD_ADDRESS=127.0.0.1
LABEL org.opencontainers.image.title="akkoma" \
    org.opencontainers.image.description="Akkoma for Docker" \
    org.opencontainers.image.vendor="akkoma.dev" \
    org.opencontainers.image.documentation="https://docs.akkoma.dev/stable/" \
    org.opencontainers.image.licenses="AGPL-3.0" \
    org.opencontainers.image.url="https://akkoma.dev" \
    org.opencontainers.image.revision=$VCS_REF \
    org.opencontainers.image.created=$BUILD_DATE

RUN apk add ffmpeg imagemagick exiftool ncurses postgresql-client file-dev libmagic

COPY --from=BUILD /release /opt/akkoma/
ADD ./docker-entrypoint.sh /opt/akkoma/
EXPOSE 4000

VOLUME /opt/akkoma/uploads/
VOLUME /opt/akkoma/instance/
VOLUME /opt/akkoma/config/docker-config.exs

WORKDIR /opt/akkoma

CMD [ "/opt/akkoma/docker-entrypoint.sh" ]