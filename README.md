# PostgreSQL + pgvector + Apache AGE Docker Images

Production-ready Docker images combining PostgreSQL with pgvector (vector search) and Apache AGE (graph database) extensions.

## Quick Start

```bash
# PostgreSQL 18 (recommended)
docker pull ghcr.io/pggraphrag/pggraphrag:18

# Run
docker run -d --name pggraphrag \
  -e POSTGRES_PASSWORD=mysecurepassword \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  ghcr.io/pggraphrag/pggraphrag:18

# Connect
docker exec -it pggraphrag psql -U postgres
```

## Available Versions

| Version | Tag | Extensions | Build Status | Image Info |
|---------|-----|-----------|--------------|-------------|
| **16** | `16` \| `16-v0.8.1-PG16/v1.6.0-rc0` | pgvector v0.8.1, AGE v1.6.0-rc0 | [![Build](https://github.com/pggraphrag/pggraphrag/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/pggraphrag/pggraphrag/actions/workflows/build-and-push.yml) | [![Size](https://img.shields.io/docker/image-size/ghcr.io/pggraphrag/pggraphrag/16)](https://ghcr.io/pggraphrag/pggraphrag:16) [![Pulls](https://img.shields.io/docker/pulls/ghcr.io/pggraphrag/pggraphrag/16)](https://ghcr.io/pggraphrag/pggraphrag:16) |
| **17** | `17` \| `17-v0.8.1-PG17/v1.6.0-rc0` | pgvector v0.8.1, AGE v1.6.0-rc0 | [![Build](https://github.com/pggraphrag/pggraphrag/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/pggraphrag/pggraphrag/actions/workflows/build-and-push.yml) | [![Size](https://img.shields.io/docker/image-size/ghcr.io/pggraphrag/pggraphrag/17)](https://ghcr.io/pggraphrag/pggraphrag:17) [![Pulls](https://img.shields.io/docker/pulls/ghcr.io/pggraphrag/pggraphrag/17)](https://ghcr.io/pggraphrag/pggraphrag:17) |
| **18** | `18`, `latest` \| `18-v0.8.1-PG18/v1.7.0-rc0` | pgvector v0.8.1, AGE v1.7.0-rc0 | [![Build](https://github.com/pggraphrag/pggraphrag/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/pggraphrag/pggraphrag/actions/workflows/build-and-push.yml) | [![Size](https://img.shields.io/docker/image-size/ghcr.io/pggraphrag/pggraphrag/18)](https://ghcr.io/pggraphrag/pggraphrag:18) [![Pulls](https://img.shields.io/docker/pulls/ghcr.io/pggraphrag/pggraphrag/18)](https://ghcr.io/pggraphrag/pggraphrag:18) |

## Features

- PostgreSQL (16, 17, 18) with pgvector and Apache AGE
- Multi-platform (linux/amd64, linux/arm64)
- Automated CI/CD with security scanning
- Production-ready (health checks, non-root user, auto-init extensions)

## Environment Variables

| Variable | Default |
|----------|---------|
| `POSTGRES_DB` | `postgres` |
| `POSTGRES_USER` | `postgres` |
| `POSTGRES_PASSWORD` | `postgres` |

## Manual Extension Setup

Extensions are initialized automatically on first container startup. For additional databases or manual control, run these commands in `psql`:

```sql
-- Enable pgvector (semantic vector search)
CREATE EXTENSION IF NOT EXISTS vector;

-- Enable Apache AGE (graph database with Cypher queries)
LOAD 'age';
CREATE EXTENSION IF NOT EXISTS age;

-- Configure search path for Cypher functions (run once per database)
ALTER DATABASE your_database_name SET search_path = ag_catalog, "$user", public;
```

**Important**: Run the `ALTER DATABASE` command for each new database you create to enable AGE graph functions.

## Extension Initialization Behavior

Extensions are loaded automatically on container startup:
- **`postgres` database**: Extensions (`vector`, `age`) are initialized automatically
- **Additional databases**: Manual setup required (see above)

**Note on startup behavior**: The container will start even if extension initialization encounters issues. Check container logs for warnings - you may need to configure extensions manually in case of startup failures. This approach ensures your database remains accessible even during extension-related issues.

## Versioning Policy

Extension versions are **explicitly pinned** in the Dockerfile and CI workflow for reproducibility and stability. The tag format `{PG_VERSION}-{PGVECTOR_VERSION}-{AGE_VERSION}` (e.g., `18-v0.8.1-1.7.0`) encodes the exact extension versions used.

To update extension versions, modify the version args in the Dockerfile and the CI workflow matrix. This approach ensures consistent builds and allows you to control when to adopt new extension releases.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Resources

- [PostgreSQL](https://www.postgresql.org/docs/)
- [pgvector](https://github.com/pgvector/pgvector)
- [Apache AGE](https://github.com/apache/age)
