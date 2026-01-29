# PostgreSQL + pgvector + Apache AGE Docker Images

Production-ready Docker images combining PostgreSQL with pgvector (vector search) and Apache AGE (graph database) extensions.

## Quick Start

```bash
# PostgreSQL 18 (recommended)
docker pull ghcr.io/pggrahrag/pggraphrag:pg18

# Run
docker run -d --name pggraphrag \
  -e POSTGRES_PASSWORD=mysecurepassword \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  ghcr.io/pggrahrag/pggraphrag:pg18

# Connect
docker exec -it pggraphrag psql -U postgres
```

## Available Versions

| Version | Tag | Extensions | Build Status | Image Info |
|---------|-----|-----------|--------------|-------------|
| **16** | `pg16` | pgvector 0.8.1, AGE 1.5.0 | [![Build](https://github.com/pggrahrag/pggraphrag/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/pggrahrag/pggraphrag/actions/workflows/build-and-push.yml) | [![Size](https://img.shields.io/docker/image-size/ghcr.io/pggrahrag/pggraphrag/pg16)](https://ghcr.io/pggrahrag/pggraphrag:pg16) [![Pulls](https://img.shields.io/docker/pulls/ghcr.io/pggrahrag/pggraphrag/pg16)](https://ghcr.io/pggrahrag/pggraphrag:pg16) |
| **17** | `pg17` | pgvector 0.8.1, AGE 1.6.0 | [![Build](https://github.com/pggrahrag/pggraphrag/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/pggrahrag/pggraphrag/actions/workflows/build-and-push.yml) | [![Size](https://img.shields.io/docker/image-size/ghcr.io/pggrahrag/pggraphrag/pg17)](https://ghcr.io/pggrahrag/pggraphrag:pg17) [![Pulls](https://img.shields.io/docker/pulls/ghcr.io/pggrahrag/pggraphrag/pg17)](https://ghcr.io/pggrahrag/pggraphrag:pg17) |
| **18** | `pg18`, `latest` | pgvector 0.8.1, AGE 1.7.0 ⚠️ | [![Build](https://github.com/pggrahrag/pggraphrag/actions/workflows/build-and-push.yml/badge.svg)](https://github.com/pggrahrag/pggraphrag/actions/workflows/build-and-push.yml) | [![Size](https://img.shields.io/docker/image-size/ghcr.io/pggrahrag/pggraphrag/pg18)](https://ghcr.io/pggrahrag/pggraphrag:pg18) [![Pulls](https://img.shields.io/docker/pulls/ghcr.io/pggrahrag/pggraphrag/pg18)](https://ghcr.io/pggrahrag/pggraphrag:pg18) |

**Note**: Apache AGE v1.7.0 for PostgreSQL 18 is currently in pre-release status.

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

This image tracks the **latest stable versions** of PostgreSQL, pgvector, and Apache AGE rather than maintaining a custom project version number. When you pull this image, you always get the most recent stable releases of each component as supported by the PostgreSQL version you're using. This reduces maintenance overhead while ensuring security updates are included automatically through the underlying projects' release cycles.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Resources

- [PostgreSQL](https://www.postgresql.org/docs/)
- [pgvector](https://github.com/pgvector/pgvector)
- [Apache AGE](https://github.com/apache/age)
