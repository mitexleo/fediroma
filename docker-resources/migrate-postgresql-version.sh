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
new_data_directory=$data_directory.new

# we'll need the credentials to create the new container
echo "Please provide the credentials for your database"
echo "If you set a different password for the old container, you'll need to provide it here! Check your config file if you're not sure"
echo ""

echo "Database user (default 'akkoma'):"
read DB_USER
echo "Database password (default: 'akkoma'):"
read DB_PASS
echo "Database name (default: 'akkoma'):"
read DB_NAME

echo ""
echo "Ok! Using user:$DB_USER to migrate db:$DB_NAME from version $old_version to $new_version"

trap "docker stop pg$old_version pg$new_version" INT TERM

# Start a PostgreSQL 14 container
docker run --rm -d --name pg$old_version \
  -v $(pwd)/$data_directory:/var/lib/postgresql/data \
  -e "POSTGRES_PASSWORD=$DB_PASS" \
  -e "POSTGRES_USER=$DB_USER" \
  -e "POSTGRES_DB=$DB_NAME" \
  postgres:$old_version-alpine

# wait a bit for the container to start
sleep 10

# Dump the db from the old container
echo "Dumping your old database..."

docker exec pg$old_version pg_dumpall -U $DB_USER > dump.sql

# Stop the old container
echo "Stopping the old database..."
docker stop pg$old_version

# Start a PostgreSQL 16 container
echo "Creating a new database with version $new_version..."
docker run --rm -d --name pg$new_version \
    -v $(pwd)/$new_data_directory:/var/lib/postgresql/data \
    -e "POSTGRES_PASSWORD=password" \
    -e "POSTGRES_USER=$DB_USER" \
    -e "POSTGRES_DB=$DB_NAME" \
    postgres:$new_version-alpine

# wait for it
sleep 10

# Load the db into the new container
docker exec -i pg$new_version psql -U $DB_USER < dump.sql

# Stop the new container
docker stop pg$new_version

# Remove the dump file
# rm dump.sql

echo "Migration complete! Your new database folder is $data_directory.new - you can now move your old data and replace it"

echo "mv $data_directory $data_directory.old"
echo "mv $new_data_directory $data_directory"