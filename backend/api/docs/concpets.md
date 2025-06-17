## What is a REST API and Endpoints?
Think of a REST API as a waiter in a restaurant:

You (Flutter app) are the customer
The kitchen (Azure SQL Database) has all the food (data)
The waiter (REST API) takes your orders and brings you food

An endpoint is like a specific item on the menu with a specific way to order it:
```sql
GET /api/spots          → "Give me all tourist spots"
GET /api/spots/123      → "Give me spot with ID 123"
POST /api/spots         → "Create a new spot with this data"
PUT /api/spots/123      → "Update spot 123 with new data"
DELETE /api/spots/123   → "Delete spot 123"
```


For your Trip Nick project, you'd need endpoints like:
```sql
Users:
GET /api/users/profile     → Get current user profile
POST /api/users/register   → Create new user account
PUT /api/users/profile     → Update user profile

Spots:
GET /api/spots             → Get all spots (with filters)
GET /api/spots/{id}        → Get specific spot
POST /api/spots            → Create new spot
GET /api/spots/nearby      → Get spots near user location

Posts:
GET /api/posts             → Get community posts
POST /api/posts            → Create new post (any type)
GET /api/posts/{id}        → Get specific post with details

Lists:
GET /api/lists             → Get user's lists
POST /api/lists            → Create new list
POST /api/lists/{id}/spots → Add spot to list
```

## Image Upload Strategy

Current plan: Flutter uploads directly to blob storage

✅ Faster uploads
✅ Reduces API server load
❌ Security risk - your storage keys are in the app
❌ No validation or processing

Better approach: Controlled direct upload

```
1. Flutter asks API: "I want to upload an image"
2. API responds: "Here's a secure upload URL (SAS token) valid for 1 hour"
3. Flutter uploads directly to blob storage using that URL
4. Flutter tells API: "Upload complete, here's the blob URL"
5. API saves the image record to database
```

This gives you security + speed.

## Database Structure
```sql
-- Base Post table
CREATE TABLE Post (
    post_id INT IDENTITY(1,1) PRIMARY KEY,
    type NVARCHAR(11) CHECK (type IN ('community', 'review', 'list')),
    -- other common fields
);

-- Specific post types inherit from Post
CREATE TABLE Review_Post (
    post_id INT PRIMARY KEY, -- Same ID as parent Post
    rating INT,
    spot_id INT
);
```
This means your API can have:

GET /api/posts returns all posts with their type
Based on the type field, your Flutter app knows whether to deserialize as CommunityPost, ReviewPost, or ListPost

## Overall Architecture
```
Flutter App
    ↓ HTTP requests
Azure Functions (REST API)
    ↓ SQL queries
Azure SQL Database

Separate direct connection:
Flutter App → Azure Blob Storage (with SAS tokens from API)
```

Node.js REST API that runs on Azure Functions:

- Node.js: The programming language/runtime (like Flutter uses Dart)
- Azure Functions: A service that runs your code when someone makes a request (like when your Flutter app asks for data)
- REST API: A set of rules for how your Flutter app talks to your backend