# postgres-postgis-pgvector

PostgreSQL with [PostGIS](https://postgis.net/) and [pgvector](https://github.com/pgvector/pgvector), built on the official `postgres:<major>-bookworm` image, with PostGIS and pgvector installed from the PGDG apt repository.

An init script creates a `template_postgis` template database and enables `postgis` and `vector` in it and in `POSTGRES_DB`. Configuration and environment variables are those of the official `postgres` image. PGDG's bookworm repository only carries PostGIS 3.6.x, so older PostGIS series are not available.

Maintained by [Process Metronome](https://github.com/process-metronome).

## Tags

| Tag | Example | PostgreSQL | PostGIS | pgvector | Moves when |
|---|---|---|---|---|---|
| `<pg>` | `16`, `17`, `18` | that major | latest built | latest | PostGIS or pgvector gets a new release, or on weekly rebuilds |
| `<pg>-<postgis>` | `16-3.6` | that major | that 3.x series | latest | pgvector, PostGIS patch or Debian updates |
| `<pg>-<postgis>-<pgvector>` | `16-3.6-0.8.7` | that major | that 3.x series (latest patch at build time) | exactly that version | Only on weekly rebuilds (base image, Debian and PostGIS patch updates) |

Available today:

| PostgreSQL | PostGIS | pgvector | Tags |
|---|---|---|---|
| 16 | 3.6 | 0.8.7 | `16`, `16-3.6`, `16-3.6-0.8.7` |
| 17 | 3.6 | 0.8.7 | `17`, `17-3.6`, `17-3.6-0.8.7` |
| 18 | 3.6 | 0.8.7 | `18`, `18-3.6`, `18-3.6-0.8.7` |

Use the full tag (or an image digest) in CI and production. Platform: `linux/amd64`.

Images are built with Docker Build Cloud from GitHub Actions on every push to `main` and rebuilt every Monday, so floating tags pick up base image and Debian security updates.

## Usage

```sh
docker run -d -e POSTGRES_PASSWORD=secret -p 5432:5432 \
  processmetronome/postgres-postgis-pgvector:16-3.6
```

```yaml
services:
  postgres:
    image: processmetronome/postgres-postgis-pgvector:16
    environment:
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data
```

On first start, `postgis` and `vector` are enabled in `POSTGRES_DB` and in `template_postgis` (create new databases `WITH TEMPLATE template_postgis` to get both). In other databases, run:

```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

### Testcontainers (.NET)

```csharp
var container = new PostgreSqlBuilder("processmetronome/postgres-postgis-pgvector:16-3.6-0.8.7")
    .Build();
```

## Building locally

```sh
docker build --build-arg PG_MAJOR=17 --build-arg POSTGIS=3.6 -t postgres-postgis-pgvector:17-3.6 .
```

## Licenses

The Dockerfile, scripts and workflows in this repository are MIT licensed. The image contains third-party software under its own licenses: PostgreSQL (PostgreSQL License), pgvector (PostgreSQL License), PostGIS (GPL-2.0-or-later) and Debian packages. Sources are available from the respective upstream projects and the [postgis/docker-postgis](https://github.com/postgis/docker-postgis) repository.

## Testing

`bash tests/smoke.sh` builds the image (honouring `PG_MAJOR` and `POSTGIS`) and checks extensions, `template_postgis` and basic queries. Pass an image name to test an existing image.
