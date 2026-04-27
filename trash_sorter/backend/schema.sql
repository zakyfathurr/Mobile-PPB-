-- Trash Sorter App — PostgreSQL Schema
-- Run against your database:
--   psql -U postgres -d trash_sorter -f schema.sql

CREATE TABLE IF NOT EXISTS scan_results (
    id             SERIAL       PRIMARY KEY,
    user_id        VARCHAR(255) NOT NULL,
    image_url      TEXT         NOT NULL,
    detected_label VARCHAR(255) NOT NULL,
    category       VARCHAR(100) NOT NULL,
    created_at     TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scan_results_user_id ON scan_results(user_id);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_updated_at ON scan_results;
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON scan_results
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
