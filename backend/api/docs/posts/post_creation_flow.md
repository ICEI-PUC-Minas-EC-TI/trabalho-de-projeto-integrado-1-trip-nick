# Post Creation Flow

## What Happens When Flutter App Creates a Post

### 1. Flutter App Sends HTTP Request
```http
POST /api/posts
Content-Type: application/json

{
  "type": "review",
  "description": "Amazing waterfall!",
  "user_id": 1,
  "spot_id": 5,
  "rating": 5
}
```

### 2. Azure Function Receives Request
- Validates the data
- Determines post type (review, community, or list)
- Starts database transaction

### 3. Database Operations (in order)
```sql
-- Step 1: Insert into Post table (base record)
INSERT INTO Post (description, user_id, created_date, type)
VALUES ('Amazing waterfall!', 1, GETDATE(), 'review')
-- Returns: post_id = 123

-- Step 2: Insert into specific post type table
INSERT INTO Review_Post (post_id, spot_id, rating)
VALUES (123, 5, 5)
```

### 4. Response Back to Flutter
```json
{
  "success": true,
  "post_id": 123,
  "message": "Post created successfully"
}
```

## Why This Two-Step Process?

Your database uses **table inheritance**:
- `Post` table has common fields (description, user_id, type)
- `Review_Post` table has review-specific fields (rating, spot_id)
- This keeps data organized and allows polymorphism

## Error Handling
If anything fails:
- Database transaction rolls back
- No partial data is saved
- Error message sent to Flutter app

# Understanding the Post Creation Code

## Key Concepts Explained

### 1. Environment Variables
```javascript
const dbConfig = {
    user: process.env.DB_USER || 'your-username',
    // ...
};
```
- `process.env.DB_USER` reads from environment variables
- `||` means "use this if the environment variable doesn't exist"
- Environment variables keep secrets out of your code

These Enviroment Variables are setup via `local.settings.json`

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "",
    "FUNCTIONS_WORKER_RUNTIME": "node",
    "DB_USER": "your-actual-username",
    "DB_PASSWORD": "your-actual-password",
    "DB_SERVER": "your-server.database.windows.net",
    "DB_DATABASE": "your-database-name"
  }
}
```

### 2. HTTP Status Codes
- `200`: OK (success)
- `201`: Created (successfully created something)
- `400`: Bad Request (client sent invalid data)
- `405`: Method Not Allowed (used GET instead of POST)
- `500`: Internal Server Error (something broke on server)

### 3. Database Transactions
```javascript
const transaction = new sql.Transaction(pool);
await transaction.begin();
// ... do multiple database operations
await transaction.commit(); // or rollback() if error
```
**Why transactions?** If creating a review post, we need to:
1. Insert into `Post` table
2. Insert into `Review_Post` table

If step 2 fails, we don't want a orphaned record in step 1.

### 4. SQL Parameterized Queries
```javascript
.input('user_id', sql.Int, user_id)
.query('INSERT INTO Post ... VALUES (@user_id, ...)')
```
**Why?** Prevents SQL injection attacks. Never do:
```javascript
// DANGEROUS - don't do this!
query(`INSERT INTO Post VALUES ('${user_input}')`)
```

### 5. Async/Await
```javascript
const result = await sql.connect(dbConfig);
```
- `await` waits for the database operation to complete
- Without `await`, your code would continue before the database responds

## Request/Response Flow

### Sample Request from Flutter:
```json
POST /api/posts
{
  "type": "review",
  "description": "Beautiful waterfall!",
  "user_id": 1,
  "spot_id": 5,
  "rating": 5
}
```

### Sample Success Response:
```json
{
  "success": true,
  "post_id": 123,
  "message": "Post created successfully",
  "data": {
    "post_id": 123,
    "type": "review",
    "description": "Beautiful waterfall!",
    "user_id": 1,
    "created_date": "2025-01-15T10:30:00.000Z"
  }
}
```