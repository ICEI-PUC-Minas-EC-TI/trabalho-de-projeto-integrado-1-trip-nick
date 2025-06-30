### Create
```bash
curl -X POST http://localhost:7071/api/spots \
  -H "Content-Type: application/json" \
  -d '{
    "spot_name": "Cachoeira da Fumaça",
    "country": "Brasil",
    "city": "Lençóis", 
    "category": "Cachoeira",
    "description": "Uma das cachoeiras mais altas do Brasil, localizada na Chapada Diamantina com 340 metros de queda."
  }'
```
```bash
curl -X POST http://localhost:7071/api/spots \
  -H "Content-Type: application/json" \
  -d '{
    "spot_name": "Exemplo",
    "country": "Brasil",
    "city": "Cidade Legal", 
    "category": "Trilha",
    "description": "Um dos pontos turísticos do mundo. Ele é legal!!!"
  }'
```
### Get
#### Basic Spot Retrieval
```bash
# Get all spots (default: newest first, 20 per page)
curl http://localhost:7071/api/spots

# Get specific spot
curl http://localhost:7071/api/spots/1
```
#### Pagination
```bash
# First page with 10 spots
curl "http://localhost:7071/api/spots?page=1&limit=10"

# Second page
curl "http://localhost:7071/api/spots?page=2&limit=10"
```
#### Filtering
```bash
# Filter by category
curl "http://localhost:7071/api/spots?category=Praia"

# Filter by country
curl "http://localhost:7071/api/spots?country=Brasil"

# Filter by city
curl "http://localhost:7071/api/spots?city=Rio de Janeiro"

# Search by name/description
curl "http://localhost:7071/api/spots?search=Chapada"

# Combined filters
curl "http://localhost:7071/api/spots?category=Cachoeira&country=Brasil&search=Fumaça"
```
#### Sorting
```bash
# Alphabetical by name
curl "http://localhost:7071/api/spots?orderBy=spot_name&order=asc"

# Group by category
curl "http://localhost:7071/api/spots?orderBy=category&order=asc"

# Group by city
curl "http://localhost:7071/api/spots?orderBy=city&order=asc"
```
#### Performance
```bash
# Without images (faster)
curl "http://localhost:7071/api/spots?includeImages=false"

# With statistics (slower, more detailed)
curl "http://localhost:7071/api/spots?includeStats=true"

# Optimized for mobile (small page, no images)
curl "http://localhost:7071/api/spots?limit=5&includeImages=false"
```