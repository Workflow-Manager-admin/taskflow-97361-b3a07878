#!/bin/bash

# TaskVerse Database Test Script
echo "Testing TaskVerse database schema..."

# Database connection parameters
DB_HOST="localhost"
DB_PORT="5000"
DB_NAME="myapp"
DB_USER="appuser"
DB_PASSWORD="dbuser123"

# Test database connection
echo "1. Testing database connection..."
if ! PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "SELECT 1;" > /dev/null 2>&1; then
    echo "❌ Cannot connect to PostgreSQL database"
    exit 1
fi
echo "✅ Database connection successful"

# Test table creation
echo ""
echo "2. Verifying tables exist..."
TABLES=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';")
if [ "$TABLES" -eq 3 ]; then
    echo "✅ All 3 tables created successfully"
else
    echo "❌ Expected 3 tables, found $TABLES"
    exit 1
fi

# Test initial data
echo ""
echo "3. Verifying initial columns data..."
COLUMNS_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -t -c "SELECT COUNT(*) FROM columns;")
if [ "$COLUMNS_COUNT" -eq 3 ]; then
    echo "✅ Initial columns data inserted successfully"
else
    echo "❌ Expected 3 columns, found $COLUMNS_COUNT"
    exit 1
fi

# Test sample user insertion
echo ""
echo "4. Testing user insertion..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT << EOF > /dev/null 2>&1
INSERT INTO users (username, email, password_hash) 
VALUES ('test_user', 'test@example.com', '\$2b\$10\$sample.hash.for.testing');
EOF

if [ $? -eq 0 ]; then
    echo "✅ User insertion successful"
else
    echo "❌ User insertion failed"
    exit 1
fi

# Test sample task insertion
echo ""
echo "5. Testing task insertion..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT << EOF > /dev/null 2>&1
INSERT INTO tasks (title, description, status, user_id, position) 
VALUES ('Test Task', 'This is a test task for schema validation', 'To Do', 1, 1);
EOF

if [ $? -eq 0 ]; then
    echo "✅ Task insertion successful"
else
    echo "❌ Task insertion failed"
    exit 1
fi

# Test foreign key constraint
echo ""
echo "6. Testing foreign key constraints..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -c "INSERT INTO tasks (title, description, status, user_id, position) VALUES ('Invalid Task', 'This should fail due to invalid user_id', 'To Do', 999, 1);" > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "✅ Foreign key constraint working correctly"
else
    echo "❌ Foreign key constraint not working"
    exit 1
fi

# Test views
echo ""
echo "7. Testing views..."
TASK_STATS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -t -c "SELECT COUNT(*) FROM task_stats;" | tr -d ' ')
TASKS_WITH_USERS=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -t -c "SELECT COUNT(*) FROM tasks_with_users;" | tr -d ' ')

if [ "$TASK_STATS" -ge 1 ] && [ "$TASKS_WITH_USERS" -ge 1 ]; then
    echo "✅ Views working correctly (task_stats: $TASK_STATS, tasks_with_users: $TASKS_WITH_USERS)"
else
    echo "❌ Views not working correctly (task_stats: $TASK_STATS, tasks_with_users: $TASKS_WITH_USERS)"
    exit 1
fi

# Test trigger (updated_at)
echo ""
echo "8. Testing updated_at trigger..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT << EOF > /dev/null 2>&1
UPDATE tasks SET title = 'Updated Test Task' WHERE id = 1;
EOF

UPDATED_COUNT=$(PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT -t -c "SELECT COUNT(*) FROM tasks WHERE updated_at > created_at;")
if [ "$UPDATED_COUNT" -eq 1 ]; then
    echo "✅ updated_at trigger working correctly"
else
    echo "❌ updated_at trigger not working"
    exit 1
fi

# Clean up test data
echo ""
echo "9. Cleaning up test data..."
PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -p $DB_PORT << EOF > /dev/null 2>&1
DELETE FROM tasks WHERE user_id = 1;
DELETE FROM users WHERE username = 'test_user';
EOF

if [ $? -eq 0 ]; then
    echo "✅ Test data cleaned up successfully"
else
    echo "❌ Failed to clean up test data"
fi

echo ""
echo "🎉 All database schema tests passed successfully!"
echo "The TaskVerse PostgreSQL database is ready for use."
