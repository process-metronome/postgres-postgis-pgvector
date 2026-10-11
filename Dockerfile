ARG PG_MAJOR=16

FROM postgres:${PG_MAJOR}-bookworm

ARG PG_MAJOR
# PostGIS minor series to install from the PGDG apt repository (already configured by the base image).
ARG POSTGIS=3.6

LABEL org.opencontainers.image.source="https://github.com/process-metronome/postgres-postgis-pgvector" \
      org.opencontainers.image.description="PostgreSQL with PostGIS and pgvector" \
      org.opencontainers.image.licenses="MIT"

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      "postgresql-${PG_MAJOR}-postgis-3=${POSTGIS}.*" \
      "postgresql-${PG_MAJOR}-postgis-3-scripts=${POSTGIS}.*" \
      postgresql-${PG_MAJOR}-pgvector \
 && rm -rf /var/lib/apt/lists/*

# Creates template_postgis and enables PostGIS + pgvector there and in POSTGRES_DB.
COPY initdb-extensions.sh /docker-entrypoint-initdb.d/10_extensions.sh
