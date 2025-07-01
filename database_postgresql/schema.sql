-- TaskVerse Database Schema
-- PostgreSQL schema for the TaskVerse Kanban application

-- Create users table
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create columns table (for Kanban columns)
CREATE TABLE columns (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    position INTEGER NOT NULL UNIQUE
);

-- Create tasks table
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) NOT NULL DEFAULT 'To Do',
    user_id INTEGER NOT NULL,
    position INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_position ON tasks(position);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);
CREATE INDEX idx_tasks_updated_at ON tasks(updated_at);
CREATE INDEX idx_columns_position ON columns(position);

-- Create function to update the updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to automatically update updated_at on tasks
CREATE TRIGGER update_tasks_updated_at 
    BEFORE UPDATE ON tasks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Insert initial Kanban columns
INSERT INTO columns (name, position) VALUES 
    ('To Do', 1),
    ('In Progress', 2),
    ('Done', 3);

-- Create view for task statistics
CREATE VIEW task_stats AS
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

-- Create view for tasks with user information
CREATE VIEW tasks_with_users AS
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

-- Add comments for documentation
COMMENT ON TABLE users IS 'Stores user account information for authentication and task ownership';
COMMENT ON TABLE tasks IS 'Stores individual tasks with their status and positioning information';
COMMENT ON TABLE columns IS 'Defines the Kanban board columns and their order';
COMMENT ON VIEW task_stats IS 'Provides aggregated statistics of tasks per user';
COMMENT ON VIEW tasks_with_users IS 'Combines task information with user details for easier querying';

-- Grant necessary permissions to the appuser
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO appuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO appuser;
GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO appuser;
