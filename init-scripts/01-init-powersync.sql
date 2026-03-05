-- Script d'initialisation pour PostgreSQL avec PowerSync
-- Créé automatiquement lors du premier démarrage du container

-- Créer la base de données pour le stockage PowerSync
CREATE DATABASE powersync_storage;

-- Créer un rôle pour PowerSync (lecture réplication)
CREATE ROLE powersync WITH LOGIN PASSWORD 'powersync_password';
GRANT CONNECT ON DATABASE auditflow TO powersync;
GRANT CONNECT ON DATABASE powersync_storage TO powersync;
GRANT USAGE ON SCHEMA public TO powersync;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO powersync;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO powersync;

-- Accorder les privilèges de réplication
ALTER ROLE powersync WITH REPLICATION;

-- Créer la publication pour la réplication logique (requise par PowerSync)
CREATE PUBLICATION powersync FOR ALL TABLES;

-- Note: Les index supplémentaires seront créés après que Prisma ait créé le schéma
-- Vous pouvez les ajouter manuellement ou via une migration Prisma ultérieure
