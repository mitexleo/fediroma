#!/bin/bash

set -euo pipefail

mkdir -p pgdata

# This is sorta special in that we need the generated_config.exs to make it onto the host
docker compose run \
    --rm \
    -e "PLEROMA_CTL_RPC_DISABLED=true" \
    akkoma ./bin/pleroma_ctl instance gen --no-sql-user --no-db-creation --dbhost db --dbname akkoma --dbuser akkoma --dbpass akkoma --listen-ip 0.0.0.0 --listen-port 4000 --static-dir /opt/akkoma/instance/ --uploads-dir /opt/akkoma/uploads/ --db-configurable true --output /opt/akkoma/config/generated_config.exs --output-psql /opt/akkoma/config/setup_db.psql

echo "Instance generated!"

# setup database from generated config
# we run from the akkoma container to ensure we have the right environment! can't connect to a DB that doesn't exist yet...
docker compose run \
    --rm \
    -e "PLEROMA_CTL_RPC_DISABLED=true" \
    -e "PGPASSWORD=akkoma" \
    akkoma psql -h db -U akkoma -d akkoma -f /opt/akkoma/config/setup_db.psql