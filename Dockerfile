# Defaulting to the latest stable Postgres 18
ARG PG_MAJOR=18

# Extension versions (must be provided as build args)
ARG PGVECTOR_VERSION=0.8.1
ARG AGE_VERSION

# --- Stage 1: The Builder ---
FROM postgres:"${PG_MAJOR}" AS builder

# Re-declare build args (FROM resets them)
ARG PG_MAJOR
ARG PGVECTOR_VERSION
ARG AGE_VERSION

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

# Create a staging area for all compiled binaries
WORKDIR /tmp/build

# 1. Build Apache AGE
# Use version from build arg (provided by workflow)
WORKDIR /tmp/age
RUN git clone --branch "$AGE_VERSION" --depth 1 https://github.com/apache/age.git . && \
    make install DESTDIR=/tmp/build

# 2. Build pgvector (pinned version for effective caching)
WORKDIR /tmp/pgvector
RUN git clone --branch "$PGVECTOR_VERSION" --depth 1 https://github.com/pgvector/pgvector.git . && \
    make OPTFLAGS="" install DESTDIR=/tmp/build

# --- Stage 2: The Runtime ---
FROM postgres:"${PG_MAJOR}"

# Re-declare build args (FROM resets them)
ARG PG_MAJOR
ARG PGVECTOR_VERSION
ARG AGE_VERSION

# Copy everything from the staging area in one clean layer
COPY --from=builder /tmp/build /

# Update the sample config to ensure libraries load on startup
RUN echo "shared_preload_libraries = 'age,vector'" >> /usr/share/postgresql/postgresql.conf.sample

# Copy initialization scripts to enable extensions on first boot
COPY init-scripts/ /docker-entrypoint-initdb.d/

# Standard healthcheck to ensure Postgres is accepting connections
# Added double quotes to satisfy SC2086
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD pg_isready -U "${POSTGRES_USER:-postgres}" || exit 1

# Fixed quoting for the label
LABEL description="Production-ready PostgreSQL ${PG_MAJOR} with Apache AGE & pgvector"

USER postgres
EXPOSE 5432

# The fail-safe command to ensure AGE and Vector are preloaded
CMD ["postgres", "-c", "shared_preload_libraries=age,vector"]
