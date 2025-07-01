# TaskVerse PostgreSQL Database Schema

This directory contains the PostgreSQL database schema and setup scripts for the TaskVerse Kanban application.

## Database Structure

### Tables

#### `users`
Stores user account information for authentication and task ownership.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PRIMARY KEY | Unique user identifier |
| username | VARCHAR(50) | UNIQUE, NOT NULL | User's chosen username |
| email | VARCHAR(255) | UNIQUE, NOT NULL | User's email address |
| password_hash | VARCHAR(255) | NOT NULL | Hashed password for authentication |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Account creation timestamp |

**Indexes:**
- `idx_users_username` on username
- `idx_users_email` on email

#### `tasks`
Stores individual tasks with their status and positioning information.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PRIMARY KEY | Unique task identifier |
| title | VARCHAR(255) | NOT NULL | Task title |
| description | TEXT | | Optional task description |
| status | VARCHAR(50) | NOT NULL, DEFAULT 'To Do' | Current task status |
| user_id | INTEGER | NOT NULL, FOREIGN KEY | Reference to task owner |
| position | INTEGER | NOT NULL, DEFAULT 0 | Task position within status column |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Task creation timestamp |
| updated_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Last modification timestamp |

**Foreign Keys:**
- `user_id` references `users(id)` ON DELETE CASCADE

**Indexes:**
- `idx_tasks_user_id` on user_id
- `idx_tasks_status` on status
- `idx_tasks_position` on position
- `idx_tasks_created_at` on created_at
- `idx_tasks_updated_at` on updated_at

**Triggers:**
- `update_tasks_updated_at` - Automatically updates `updated_at` on row modification

#### `columns`
Defines the Kanban board columns and their order.

| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | SERIAL | PRIMARY KEY | Unique column identifier |
| name | VARCHAR(100) | NOT NULL | Column display name |
| position | INTEGER | NOT NULL, UNIQUE | Column order position |

**Indexes:**
- `idx_columns_position` on position

**Initial Data:**
- To Do (position 1)
- In Progress (position 2)
- Done (position 3)

### Views

#### `task_stats`
Provides aggregated statistics of tasks per user.

```sql
SELECT 
    u.id as user_id,
    u.username,
    COUNT(t.id) as total_tasks,
    COUNT(CASE WHEN t.status = 'To Do' THEN 1 END) as todo_tasks,
    COUNT(CASE WHEN t.status = 'In Progress' THEN 1 END) as in_progress_tasks,
    COUNT(CASE WHEN t.status = 'Done' THEN 1 END) as done_tasks
FROM users u
LEFT JOIN tasks t ON u.id = t.user_id
GROUP BY u.id, u.username;
```

#### `tasks_with_users`
Combines task information with user details for easier querying.

```sql
SELECT 
    t.id,
    t.title,
    t.description,
    t.status,
    t.position,
    t.created_at,
    t.updated_at,
    u.username,
    u.email
FROM tasks t
JOIN users u ON t.user_id = u.id;
```

## Setup Scripts

### `setup_schema.sh`
Initializes the database schema from scratch. Run this script to create all tables, indexes, views, and initial data.

```bash
./setup_schema.sh
```

### `reset_schema.sh`
Drops all existing tables and recreates the schema. **WARNING: This will delete all data!**

```bash
./reset_schema.sh
```

### `schema.sql`
Contains the raw SQL commands for creating the complete database schema.

## Connection Information

The database runs on:
- **Host:** localhost
- **Port:** 5000
- **Database:** myapp
- **User:** appuser
- **Password:** dbuser123

Connection string: `postgresql://appuser:dbuser123@localhost:5000/myapp`

## Environment Variables

For application integration, use these environment variables:
- `POSTGRES_URL`: postgresql://localhost:5000/myapp
- `POSTGRES_USER`: appuser
- `POSTGRES_PASSWORD`: dbuser123
- `POSTGRES_DB`: myapp
- `POSTGRES_PORT`: 5000

## Usage Examples

### Creating a new user
```sql
INSERT INTO users (username, email, password_hash) 
VALUES ('john_doe', 'john@example.com', '$2b$10$...');
```

### Creating a new task
```sql
INSERT INTO tasks (title, description, status, user_id, position) 
VALUES ('Complete project', 'Finish the TaskVerse application', 'To Do', 1, 1);
```

### Moving a task to different status
```sql
UPDATE tasks 
SET status = 'In Progress', position = 1 
WHERE id = 1;
```

### Getting user's tasks by status
```sql
SELECT * FROM tasks 
WHERE user_id = 1 AND status = 'To Do' 
ORDER BY position;
```

### Getting task statistics for a user
```sql
SELECT * FROM task_stats WHERE user_id = 1;
```

## Database Maintenance

### Backup
```bash
PGPASSWORD=dbuser123 pg_dump -h localhost -U appuser -d myapp -p 5000 > backup.sql
```

### Restore
```bash
PGPASSWORD=dbuser123 psql -h localhost -U appuser -d myapp -p 5000 < backup.sql
```

### Check database size
```sql
SELECT pg_size_pretty(pg_database_size('myapp')) as database_size;
```

## Performance Considerations

- All frequently queried columns have appropriate indexes
- Foreign key constraints ensure data integrity
- The `updated_at` trigger automatically maintains modification timestamps
- Views provide optimized queries for common operations
- Position-based ordering allows for efficient drag-and-drop operations

## Security Features

- User passwords should be hashed before storage (never store plain text)
- Foreign key constraints with CASCADE DELETE prevent orphaned records
- Proper user permissions are set for the application user account
- All inputs should be parameterized to prevent SQL injection
