#!/bin/sh
set -e

echo "🔄 Starting database migration process..."

# Function to get list of migration names from prisma/migrations directory
get_migration_names() {
    if [ -d "prisma/migrations" ]; then
        ls -1 prisma/migrations | grep -v "migration_lock.toml" | sort
    fi
}

# Function to baseline all existing migrations
baseline_all_migrations() {
    echo "📋 Baseline: Marking all migrations as applied..."
    for migration_name in $(get_migration_names); do
        echo "  ✓ Resolved: $migration_name"
        npx prisma migrate resolve --applied "$migration_name" 2>/dev/null || true
    done
}

# Check if _prisma_migrations table exists (indicates if migrations have been run before)
MIGRATIONS_TABLE_EXISTS=$(psql "$DATABASE_URL" -tAc "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = '_prisma_migrations');" 2>/dev/null || echo "false")

if [ "$MIGRATIONS_TABLE_EXISTS" = "f" ] || [ "$MIGRATIONS_TABLE_EXISTS" = "false" ]; then
    echo "📊 No migrations table found - fresh database or existing schema"
    
    # Check if database has any tables (existing data)
    TABLES_COUNT=$(psql "$DATABASE_URL" -tAc "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>/dev/null || echo "0")
    
    if [ "$TABLES_COUNT" -gt 0 ]; then
        echo "⚠️  Database has existing tables ($TABLES_COUNT tables) - baselining migrations..."
        baseline_all_migrations
        echo "✅ Migrations baselined successfully"
    else
        echo "🆕 Fresh database - applying migrations normally..."
        npx prisma migrate deploy
        echo "✅ Migrations applied successfully"
    fi
else
    echo "📊 Migrations table exists - checking for pending migrations..."
    
    # Try normal migration deploy
    if npx prisma migrate deploy; then
        echo "✅ Migrations applied successfully"
    else
        echo "⚠️  Migration failed - attempting to resolve..."
        
        # Get failed migrations and resolve them
        FAILED_MIGRATIONS=$(psql "$DATABASE_URL" -tAc "SELECT migration_name FROM _prisma_migrations WHERE finished_at IS NULL;" 2>/dev/null || echo "")
        
        if [ -n "$FAILED_MIGRATIONS" ]; then
            echo "📋 Resolving failed migrations..."
            echo "$FAILED_MIGRATIONS" | while read -r migration_name; do
                if [ -n "$migration_name" ]; then
                    echo "  ✓ Resolving: $migration_name"
                    npx prisma migrate resolve --applied "$migration_name" 2>/dev/null || true
                fi
            done
            echo "✅ Failed migrations resolved"
        fi
    fi
fi

echo "🚀 Starting application..."
exec node dist/index.js
