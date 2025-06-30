### Create
#### Prerequistes
```bash
# Create a list (note the returned list_id)
curl -X POST http://localhost:7071/api/lists \
  -H "Content-Type: application/json" \
  -d '{"list_name": "Best Beaches in Brazil"}'

# Create a spot (note the returned spot_id)
curl -X POST http://localhost:7071/api/spots \
  -H "Content-Type: application/json" \
  -d '{
    "spot_name": "Praia do Rosa",
    "country": "Brasil",
    "city": "Imbituba",
    "category": "Praia"
  }'
```
#### Add Spot to List
```bash
curl -X POST http://localhost:7071/api/lists/1/spots \
  -H "Content-Type: application/json" \
  -d '{
    "spot_id": 1
  }'
```

#### Add Spot with Thumbnail
```bash
curl -X POST http://localhost:7071/api/lists/1/spots \
  -H "Content-Type: application/json" \
  -d '{
    "spot_id": 2,
    "list_thumbnail_id": 1
  }'s
```
### Delete
#### Prerequisites: Set up test data
```bash
# Create a list
curl -X POST http://localhost:7071/api/lists \
  -H "Content-Type: application/json" \
  -d '{"list_name": "Test List for Removal"}'

# Add some spots to it
curl -X POST http://localhost:7071/api/lists/1/spots \
  -H "Content-Type: application/json" \
  -d '{"spot_id": 1}'

curl -X POST http://localhost:7071/api/lists/1/spots \
  -H "Content-Type: application/json" \
  -d '{"spot_id": 2}'
```
#### Successful Removal
```bash
# Remove spot 1 from list 1
curl -X DELETE http://localhost:7071/api/lists/1/spots/1
```