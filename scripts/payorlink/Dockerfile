FROM asia.gcr.io/silver-approach-172802/ip-build
MAINTAINER Noel del Castillo

ENV REPLACE_OS_VARS=true SHELL=/bin/bash
WORKDIR /app
COPY . .

RUN mix deps.get
RUN mix compile
RUN cd /app/apps/payor_link/assets && npm install && node_modules/brunch/bin/brunch build -p
RUN cd /app/apps/payor_link && MIX_ENV=prod mix phx.digest
RUN cd /app
RUN MIX_ENV=prod mix release --env=prod

EXPOSE 4001
# ENTRYPOINT ["./scripts/payorlink/server.sh"]
# ENTRYPOINT ["_build/prod/rel/innerpeace/bin/innerpeace"]
