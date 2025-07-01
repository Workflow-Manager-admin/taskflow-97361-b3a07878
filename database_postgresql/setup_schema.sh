#!/bin/bash

# TaskVerse Database Schema Setup Script
echo "Setting up TaskVerse database schema..."

# Database connection parameters
DB_HOST="localhost"
DB_PORT="5000"
DB_NAME="myapp"
DB_USER="appuser"
DB_PASSWORD="dbuser123"

# Check if PostgreSQL is running
if ! PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "SELECT 1;" > /dev/null 2>&1; then
    echo "Error: Cannot connect to PostgreSQL database."
    echo "Please ensure PostgreSQL is running and the connection parameters are correct."
    exit 1
fi

echo "Connected to PostgreSQL successfully!"

# Execute the schema script
echo "Creating tables and initial data..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -f schema.sql

if [ $? -eq 0 ]; then
    echo "✓ Schema setup completed successfully!"
    
    # Verify the setup by listing tables
    echo ""
    echo "Created tables:"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "\dt"
    
    echo ""
    echo "Initial columns data:"
    PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "SELECT * FROM columns ORDER BY position;"
    
    echo ""
    echo "Database schema is ready for the TaskVerse application!"
else
    echo "✗ Error occurred during schema setup."
    exit 1
fi
