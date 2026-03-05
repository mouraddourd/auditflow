-- Script d'initialisation pour PostgreSQL avec PowerSync
-- 
-- SECURITY WARNING: The powersync role password is hardcoded below.
-- For production, change this password and update your PowerSync configuration
-- to use a strong, environment-specific credential.

-- Créer la base de données pour le stockage PowerSync
CREATE DATABASE powersync_storage;

-- Créer un rôle pour PowerSync (lecture réplication)
-- NOTE: Change this password for production deployments
CREATE ROLE powersync WITH LOGIN PASSWORD 'powersync_password' REPLICATION;
GRANT CONNECT ON DATABASE auditflow TO powersync;
GRANT CONNECT ON DATABASE powersync_storage TO powersync;
GRANT USAGE ON SCHEMA public TO powersync;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO powersync;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO powersync;

-- Créer la publication pour la réplication logique (requise par PowerSync)
CREATE PUBLICATION powersync FOR ALL TABLES;
