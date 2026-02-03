# PostgreSQL version (must come before FROM)
ARG PG_MAJOR=18

# --- Stage 1: The Builder ---
FROM postgres:"${PG_MAJOR}" AS builder

ARG PG_MAJOR

# Pinned extension versions (override via --build-arg)
ARG PGVECTOR_VERSION=v0.8.1
ARG AGE_VERSION=PG18/v1.7.0-rc0

# Install build-essential and dependencies for AGE & pgvector
# Included ca-certificates to fix SSL/Git errors
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    ca-certificates \
    bison \
    flex \
    libreadline-dev \
    zlib1g-dev \
    postgresql-server-dev-"${PG_MAJOR}" \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/build

# Apache AGE
WORKDIR /tmp/age
RUN git clone --branch "$AGE_VERSION" --depth 1 https://github.com/apache/age.git . && \
    make install DESTDIR=/tmp/build

# pgvector
WORKDIR /tmp/pgvector
RUN git clone --branch "$PGVECTOR_VERSION" --depth 1 https://github.com/pgvector/pgvector.git . && \
    make OPTFLAGS="" install DESTDIR=/tmp/build

# --- Stage 2: The Runtime ---
FROM postgres:"${PG_MAJOR}"

ARG PG_MAJOR

COPY --from=builder /tmp/build /

RUN echo "shared_preload_libraries = 'age,vector'" >> /usr/share/postgresql/postgresql.conf.sample

COPY init-scripts/ /docker-entrypoint-initdb.d/

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD pg_isready -U "${POSTGRES_USER:-postgres}" || exit 1

# Re-declare build args for labels
ARG PGVECTOR_VERSION
ARG AGE_VERSION

# OCI-compliant image labels
LABEL org.opencontainers.image.title="pggraphrag" \
    org.opencontainers.image.description="Production-ready PostgreSQL ${PG_MAJOR} with pgvector (vector search) and Apache AGE (graph database) extensions" \
    org.opencontainers.image.version="${PG_MAJOR}-${PGVECTOR_VERSION}-${AGE_VERSION}" \
    org.opencontainers.image.source="https://github.com/pggraphrag/pggraphrag" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.vendor="pggraphrag" \
    org.opencontainers.image.documentation="https://github.com/pggraphrag/pggraphrag#readme" \
    org.opencontainers.image.authors="pggraphrag" \
    # Extension version labels
    pggraphrag.pgvector.version="${PGVECTOR_VERSION}" \
    pggraphrag.age.version="${AGE_VERSION}" \
    # License compliance notices
    pggraphrag.licenses.pgvector="PostgreSQL License" \
    pggraphrag.licenses.age="Apache-2.0" \
    pggraphrag.licenses.postgresql="PostgreSQL License"

USER postgres
EXPOSE 5432

CMD ["postgres", "-c", "shared_preload_libraries=age,vector"]
