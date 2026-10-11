#!/bin/sh
# Creates template_postgis and enables PostGIS and pgvector in it and in POSTGRES_DB.
set -e

export PGUSER="$POSTGRES_USER"

psql -v ON_ERROR_STOP=1 -d "$POSTGRES_DB" <<-SQL
	CREATE DATABASE template_postgis IS_TEMPLATE true;
SQL

for DB in template_postgis "$POSTGRES_DB"; do
  echo "Loading postgis and vector extensions into $DB"
  psql -v ON_ERROR_STOP=1 -d "$DB" <<-SQL
	CREATE EXTENSION IF NOT EXISTS postgis;
	CREATE EXTENSION IF NOT EXISTS vector;
SQL
done
