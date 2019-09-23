#!/bin/bash

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Create cstore extension
echo "Loading cstore extensions into $POSTGRES_DB"
psql --dbname="$POSTGRES_DB" <<- 'EOSQL'
CREATE EXTENSION cstore_fdw;
CREATE SERVER cstore_server FOREIGN DATA WRAPPER cstore_fdw;
EOSQL