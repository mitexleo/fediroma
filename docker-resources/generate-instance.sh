#!/bin/bash

set -euo pipefail

mkdir -p pgdata

# This is sorta special in that we need the generated_config.exs to make it onto the host
docker compose run \
    --rm \
    -e "PLEROMA_CTL_RPC_DISABLED=true" \
    akkoma ./bin/pleroma_ctl instance gen --no-sql-user --no-db-creation --dbhost db --dbname akkoma --dbuser akkoma --dbpass akkoma --listen-ip 0.0.0.0 --listen-port 4000 --static-dir /opt/akkoma/instance/ --uploads-dir /opt/akkoma/uploads/ --db-configurable y --output /opt/akkoma/config/generated_config.exs --output-psql /opt/akkoma/config/setup_db.psql

# setup database from generated config
# we run from the akkoma container to ensure we have the right environment! can't connect to a DB that doesn't exist yet...
docker compose run \
    --rm \
    -e "PLEROMA_CTL_RPC_DISABLED=true" \
    -e "PGPASSWORD=akkoma" \
    akkoma psql -h db -U akkoma -d akkoma -f /opt/akkoma/config/setup_db.psql

# stop tzdata trying to write to places it shouldn't
echo "config :tzdata, :data_dir, "/var/tmp/elixir_tzdata_storage" >> /opt/akkoma/config/generated_config.exs

echo "Instance generated!"

echo "Make sure you check your config and copy it to config/prod.secret.exs before starting the instance!"