### Create
```bash
curl -X POST http://localhost:7071/api/posts \
  -H "Content-Type: application/json" \
  -d '{
    "type": "review",
    "description": "Outra Review",
    "user_id": 1,
    "spot_id": 3,
    "rating": 4
  }'
```

```bash
curl -X POST http://localhost:7071/api/posts \
  -H "Content-Type: application/json" \
  -d '{
    "type": "community",
    "title": "Amazing place!",
    "user_id": 1,
    "list_id": 1
  }'
```

### Get
```bash
# Get all posts
curl http://localhost:7071/api/posts

# Get specific post
curl http://localhost:7071/api/posts/1

# Get posts with pagination
curl "http://localhost:7071/api/posts?page=1&limit=5"

# Get posts by user
curl "http://localhost:7071/api/posts?userId=1"

# Get only review posts
curl "http://localhost:7071/api/posts?type=review"
```