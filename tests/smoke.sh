#!/usr/bin/env bash
# Smoke test for the image. Usage: tests/smoke.sh [image]   (builds ./ as the image when none is given)
# Build args: PG_MAJOR (default 16), POSTGIS (default 3.6).
set -euo pipefail

cd "$(dirname "$0")/.."
IMAGE="${1:-}"
NAME="pgtest-$$"

if [ -z "$IMAGE" ]; then
  IMAGE="postgres-postgis-pgvector:test"
  docker build -t "$IMAGE" \
    --build-arg "PG_MAJOR=${PG_MAJOR:-16}" --build-arg "POSTGIS=${POSTGIS:-3.6}" .
fi

cleanup() { docker rm -f "$NAME" >/dev/null 2>&1 || true; }
trap cleanup EXIT

docker run -d --name "$NAME" -e POSTGRES_PASSWORD=test -e POSTGRES_DB=testdb "$IMAGE" >/dev/null

psql_() { docker exec "$NAME" psql -U postgres -v ON_ERROR_STOP=1 -tA "$@"; }

# The entrypoint runs init scripts on a temporary server, so pg_isready is true too early.
# Wait for the final server: the log has two "ready to accept connections" lines.
for _ in $(seq 1 60); do
  [ "$(docker logs "$NAME" 2>&1 | grep -c 'ready to accept connections')" -ge 2 ] && break
  sleep 2
done

fail=0
check() { # check <description> <expected> <db> <sql>
  local got
  got=$(psql_ -d "$3" -c "$4" 2>&1) || true
  if [ "$got" = "$2" ]; then echo "PASS  $1"; else echo "FAIL  $1 (expected '$2', got '$got')"; fail=1; fi
}

for db in testdb template_postgis; do
  check "postgis installed in $db" 1 "$db" "select count(*) from pg_extension where extname='postgis'"
  check "vector installed in $db"  1 "$db" "select count(*) from pg_extension where extname='vector'"
done

psql_ -c "create database fromtpl template template_postgis" >/dev/null
check "fromtpl has postgis+vector" 2 fromtpl \
  "select count(*) from pg_extension where extname in ('postgis','vector')"

check "postgis distance NYC-LA ~3936 km" 3936 testdb \
  "select round(st_distancesphere(st_point(-74.006,40.7128), st_point(-118.2437,34.0522))/1000)"
check "pgvector L2 distance" 2.828427 testdb \
  "select round(('[1,2,3]'::vector <-> '[3,2,1]'::vector)::numeric, 6)"
check "pgvector cosine distance of identical vectors" 0.000000 testdb \
  "select round(('[1,2,3]'::vector <=> '[1,2,3]'::vector)::numeric, 6)"
check "geometry and vector tables work together" 1 testdb \
  "select count(*) from (select st_setsrid(st_point(1,2),4326)::geometry(point,4326) g, '[1,2,3]'::vector(3) e) t"

[ "$fail" -eq 0 ] && echo "All checks passed" || { echo "Some checks failed"; exit 1; }
