#!/bin/bash

# TaskVerse Database Reset Script
echo "Resetting TaskVerse database schema..."

# Database connection parameters
DB_HOST="localhost"
DB_PORT="5000"
DB_NAME="myapp"
DB_USER="appuser"
DB_PASSWORD="dbuser123"

# Warning message
echo "WARNING: This will delete all existing data in the database!"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Operation cancelled."
    exit 0
fi

# Check if PostgreSQL is running
if ! PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "SELECT 1;" > /dev/null 2>&1; then
    echo "Error: Cannot connect to PostgreSQL database."
    echo "Please ensure PostgreSQL is running and the connection parameters are correct."
    exit 1
fi

echo "Connected to PostgreSQL successfully!"

# Drop existing tables and views
echo "Dropping existing tables and views..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT << EOF
-- Drop views first (they depend on tables)
DROP VIEW IF EXISTS task_stats CASCADE;
DROP VIEW IF EXISTS tasks_with_users CASCADE;

-- Drop triggers and functions
DROP TRIGGER IF EXISTS update_tasks_updated_at ON tasks;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Drop tables in reverse dependency order
DROP TABLE IF EXISTS tasks CASCADE;
DROP TABLE IF EXISTS columns CASCADE;
DROP TABLE IF EXISTS users CASCADE;
EOF

if [ $? -eq 0 ]; then
    echo "✓ Existing schema dropped successfully!"
    
    # Execute the schema script to recreate everything
    echo "Recreating schema..."
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -f schema.sql
    
    if [ $? -eq 0 ]; then
        echo "✓ Schema reset completed successfully!"
        
        # Verify the setup
        echo ""
        echo "Recreated tables:"
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "\dt"
        
        echo ""
        echo "Initial columns data:"
        PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "SELECT * FROM columns ORDER BY position;"
        
        echo ""
        echo "Database schema has been reset and is ready!"
    else
        echo "✗ Error occurred during schema recreation."
        exit 1
    fi
else
    echo "✗ Error occurred during schema cleanup."
    exit 1
fi
EOF
