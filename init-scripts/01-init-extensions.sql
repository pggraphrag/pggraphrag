-- Default extension helper for pgvector and Apache AGE
-- Runs automatically on first container startup

DO $$
DECLARE
    vector_version text;
    age_version text;
BEGIN
    -- Configure search path for Apache AGE
    SET search_path = ag_catalog, "$user", public;

    -- Initialize pgvector
    IF NOT EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'vector'
    ) THEN
        CREATE EXTENSION vector;
        RAISE NOTICE 'pgvector extension created';
    ELSE
        RAISE NOTICE 'pgvector extension already exists';
    END IF;

    -- Initialize Apache AGE
    -- Removed redundant duplicate block found in original version
    IF NOT EXISTS (
        SELECT 1 FROM pg_extension WHERE extname = 'age'
    ) THEN
        LOAD 'age';
        CREATE EXTENSION age;
        RAISE NOTICE 'Apache AGE extension created';
    ELSE
        RAISE NOTICE 'Apache AGE extension already exists';
    END IF;

    -- Retrieve and report versions for logs
    SELECT extversion INTO vector_version
    FROM pg_extension WHERE extname = 'vector';

    SELECT extversion INTO age_version
    FROM pg_extension WHERE extname = 'age';

    RAISE NOTICE 'Extensions: pgvector %, Apache AGE %',
        COALESCE(vector_version, 'N/A'),
        COALESCE(age_version, 'N/A');

EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Extension initialization warning: %', SQLERRM;
        RAISE NOTICE 'Extensions may need manual configuration - see README.md';
END $$;
