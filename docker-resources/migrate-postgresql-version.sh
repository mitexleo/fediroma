#!/bin/bash

set -euo pipefail

# USAGE:
# migrate-postgresql-version.sh <data_directory> <old_version> <new_version>

if [ "$#" -ne 3 ]; then
    echo "USAGE: migrate-postgresql-version.sh <data_directory> <old_version> <new_version>"
    echo "Example: migrate-postgresql-version.sh pgdata 14 16"
    exit 1
fi

data_directory=$1
old_version=$2
new_version=$3

# Start a PostgreSQL 14 container
docker run --rm -d --name pg14 -v $(pwd)/$data_directory:/var/lib/postgresql/data -e "POSTGRES_PASSWORD=password" postgres:$old_version-alpine

# wait a bit for the container to start
sleep 10

# Dump the db from the old container
docker exec pg14 pg_dumpall -U postgres > dump.sql

# Stop the old container
docker stop pg14

# Start a PostgreSQL 16 container
docker run --rm -d --name pg16 -v $(pwd)/$data_directory.new:/var/lib/postgresql/data -e "POSTGRES_PASSWORD=password"  postgres:$new_version-alpine

# Load the db into the new container
docker exec -i pg16 psql -U postgres < dump.sql

# Stop the new container
docker stop pg16

# Remove the dump file
rm dump.sql

echo "Migration complete! Your new database folder is $data_directory.new - you can now move your old data and replace it"

echo "mv $data_directory $data_directory.old"
echo "mv $data_directory.new $data_directory"