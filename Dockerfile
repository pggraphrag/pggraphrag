# Defaulting to the latest stable Postgres 18
ARG PG_MAJOR=18

# --- Stage 1: The Builder ---
FROM postgres:${PG_MAJOR} AS builder

# Install build-essential and dependencies for AGE & pgvector
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    bison \
    flex \
    libreadline-dev \
    zlib1g-dev \
    postgresql-server-dev-${PG_MAJOR} \
    && rm -rf /var/lib/apt/lists/*

# Create a staging area for all compiled binaries
WORKDIR /tmp/build

# 1. Build Apache AGE (Using the dedicated PG18 branch)
WORKDIR /tmp/age
RUN git clone --branch PG${PG_MAJOR} --depth 1 https://github.com/apache/age.git . \
    && make install DESTDIR=/tmp/build

# 2. Build pgvector (Dynamically finding the latest release tag)
WORKDIR /tmp/pgvector
RUN git clone https://github.com/pgvector/pgvector.git . && \
    LATEST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`) && \
    git checkout $LATEST_TAG && \
    make OPTFLAGS="" install DESTDIR=/tmp/build

# --- Stage 2: The Runtime ---
FROM postgres:${PG_MAJOR}

# Copy everything from the staging area in one clean layer
COPY --from=builder /tmp/build /

# Update the sample config to ensure libraries load on startup
RUN echo "shared_preload_libraries = 'age,vector'" >> /usr/share/postgresql/postgresql.conf.sample

# Copy initialization scripts to enable extensions on first boot
COPY init-scripts/ /docker-entrypoint-initdb.d/

# Standard healthcheck to ensure Postgres is accepting connections
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1

LABEL description="Production-ready PostgreSQL ${PG_MAJOR} with Apache AGE & pgvector"

USER postgres
EXPOSE 5432

# The fail-safe command to ensure AGE and Vector are preloaded
CMD ["postgres", "-c", "shared_preload_libraries=age,vector"]
