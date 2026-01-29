ARG PG_MAJOR=18

# Stage 1: Builder
FROM postgres:${PG_MAJOR} AS builder

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update && apt-get install -y \
    build-essential \
    postgresql-client-${PG_MAJOR} \
    postgresql-server-dev-${PG_MAJOR} \
    libpq-dev \
    git bison flex libreadline-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
# Use the dedicated PG branch for stability
RUN git clone --branch PG${PG_MAJOR} --depth 1 https://github.com/apache/age.git

WORKDIR /tmp/age
RUN make PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config install

WORKDIR /tmp
RUN git clone --branch v0.8.1 --depth 1 https://github.com/pgvector/pgvector.git
WORKDIR /tmp/pgvector
RUN make PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config clean
RUN make PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR}/bin/pg_config OPTFLAGS="" install

# Stage 2: Runtime
FROM postgres:${PG_MAJOR}

COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/age.so /usr/lib/postgresql/${PG_MAJOR}/lib/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/age* /usr/share/postgresql/${PG_MAJOR}/extension/
COPY --from=builder /usr/lib/postgresql/${PG_MAJOR}/lib/vector.so /usr/lib/postgresql/${PG_MAJOR}/lib/
COPY --from=builder /usr/share/postgresql/${PG_MAJOR}/extension/vector* /usr/share/postgresql/${PG_MAJOR}/extension/

# Stage 3: Persistence-safe config
# This ensures AGE is loaded even if a volume is already present
RUN echo "shared_preload_libraries = 'age'" >> /usr/share/postgresql/postgresql.conf.sample

COPY init-scripts/ /docker-entrypoint-initdb.d/

# Metadata labels - tracks latest stable components, not a custom version
LABEL maintainer="pggraphrag contributors" \
      description="PostgreSQL ${PG_MAJOR} with latest stable pgvector and Apache AGE" \
      org.opencontainers.image.title="PostgreSQL ${PG_MAJOR} + pgvector + Apache AGE" \
      org.opencontainers.image.description="Production-ready Docker image with PostgreSQL ${PG_MAJOR}, pgvector, and Apache AGE for Graph RAG applications" \
      org.opencontainers.image.vendor="pggraphrag" \
      org.opencontainers.image.postgres.version="${PG_MAJOR}" \
      org.opencontainers.image.licenses="MIT"

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1

USER postgres
EXPOSE 5432

# Passing the config flag here is a "fail-safe" for cloud environments
CMD ["postgres", "-c", "shared_preload_libraries=age"]
