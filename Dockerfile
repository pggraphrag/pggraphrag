ARG PG_VERSION=18

# Stage 1: Builder
FROM postgres:${PG_VERSION} AS builder

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y \
    build-essential \
    postgresql-server-dev-${PG_VERSION} \
    git bison flex libreadline-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
# Use the dedicated PG branch for stability
RUN git clone --branch PG${PG_VERSION} --depth 1 https://github.com/apache/age.git

WORKDIR /tmp/age
RUN make PG_CONFIG=/usr/lib/postgresql/${PG_VERSION}/bin/pg_config install

# Stage 2: Runtime
FROM postgres:${PG_VERSION}

# 1. Install pgvector from APT
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y \
    postgresql-${PG_VERSION}-pgvector \
    && rm -rf /var/lib/apt/lists/*

# 2. Copy AGE artifacts
COPY --from=builder /usr/lib/postgresql/${PG_VERSION}/lib/age.so /usr/lib/postgresql/${PG_VERSION}/lib/
COPY --from=builder /usr/share/postgresql/${PG_VERSION}/extension/age* /usr/share/postgresql/${PG_VERSION}/extension/

# 3. Persistence-safe config
# This ensures AGE is loaded even if a volume is already present
RUN echo "shared_preload_libraries = 'age'" >> /usr/share/postgresql/postgresql.conf.sample

COPY init-scripts/ /docker-entrypoint-initdb.d/

# Metadata labels - tracks latest stable components, not a custom version
LABEL maintainer="pggraphrag contributors" \
      description="PostgreSQL ${PG_VERSION} with latest stable pgvector and Apache AGE" \
      org.opencontainers.image.title="PostgreSQL ${PG_VERSION} + pgvector + Apache AGE" \
      org.opencontainers.image.description="Production-ready Docker image with PostgreSQL ${PG_VERSION}, pgvector, and Apache AGE for Graph RAG applications" \
      org.opencontainers.image.vendor="pggraphrag" \
      org.opencontainers.image.postgres.version="${PG_VERSION}" \
      org.opencontainers.image.licenses="MIT"

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1

USER postgres
EXPOSE 5432

# Passing the config flag here is a "fail-safe" for cloud environments
CMD ["postgres", "-c", "shared_preload_libraries=age"]
