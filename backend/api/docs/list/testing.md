### Create
#### Public List(Default)
```bash
curl -X POST http://localhost:7071/api/lists \
  -H "Content-Type: application/json" \
  -d '{
    "list_name": "Melhores Praias do Brasil"
  }'
```

#### Explicit Public List
```bash
curl -X POST http://localhost:7071/api/lists \
  -H "Content-Type: application/json" \
  -d '{
    "list_name": "Cachoeiras da Chapada Diamantina",
    "is_public": true
  }'
```

#### Private List
```bash
curl -X POST http://localhost:7071/api/lists \
  -H "Content-Type: application/json" \
  -d '{
    "list_name": "Minha Lista de Desejos 2025",
    "is_public": false
  }'
```

### Get
#### Basic Get
```bash
# Get all spots in list 1
curl http://localhost:7071/api/lists/1/spots
```
#### With Ordering Options
```bash
# Order by spot name (alphabetical)
curl "http://localhost:7071/api/lists/1/spots?orderBy=spot_name&order=asc"

# Order by category
curl "http://localhost:7071/api/lists/1/spots?orderBy=category&order=asc"

# Order by city
curl "http://localhost:7071/api/lists/1/spots?orderBy=city&order=asc"
```
#### Performance Options
```bash
# Without images (faster loading)
curl "http://localhost:7071/api/lists/1/spots?includeImages=false"

# With images (default)
curl "http://localhost:7071/api/lists/1/spots?includeImages=true"
```

### Delete
#### Prerequisites: Set up test data
```bash
# Create a test list
curl -X POST http://localhost:7071/api/lists \
  -H "Content-Type: application/json" \
  -d '{"list_name": "Test List for Deletion", "is_public": true}'

# Add some spots to it
curl -X POST http://localhost:7071/api/lists/1/spots \
  -H "Content-Type: application/json" \
  -d '{"spot_id": 1}'

curl -X POST http://localhost:7071/api/lists/1/spots \
  -H "Content-Type: application/json" \
  -d '{"spot_id": 2}'

# Create a post referencing the list (if you have posts working)
curl -X POST http://localhost:7071/api/posts \
  -H "Content-Type: application/json" \
  -d '{
    "type": "community",
    "description": "Check out my amazing list!",
    "user_id": 1,
    "title": "My Test List",
    "list_id": 1
  }'
```
#### Test Dry Run
```bash
# See what would be deleted without actually deleting
curl -X DELETE "http://localhost:7071/api/lists/1?dryRun=true"
```
#### Test Protected Deletion
```bash
# Try to delete list with posts (should be blocked)
curl -X DELETE http://localhost:7071/api/lists/1
```
#### Test Force Deletion
```bash
# Force delete even with posts
curl -X DELETE "http://localhost:7071/api/lists/1?force=true"
```
#### Test Simple Deletion
```bash
# Create a simple list
curl -X POST http://localhost:7071/api/lists \
  -H "Content-Type: application/json" \
  -d '{"list_name": "Simple List"}'

# Add a spot
curl -X POST http://localhost:7071/api/lists/2/spots \
  -H "Content-Type: application/json" \
  -d '{"spot_id": 1}'

# Delete it (should work smoothly)
curl -X DELETE http://localhost:7071/api/lists/2
```