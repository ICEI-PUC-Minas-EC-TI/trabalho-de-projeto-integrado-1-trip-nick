# Get Spots - Understanding the Functionality

## What This Endpoint Powers in Your App

### 1. **"Descobrir" Tab Features**
- Browse all available tourist spots
- Filter by category (Praia, Cachoeira, Montanha, etc.)
- Filter by location (country, city)
- Search by name
- Pagination for performance

### 2. **Spot Discovery Workflows**
```
User opens "Descobrir" tab
    ↓
GET /api/spots?page=1&limit=20
    ↓ 
Display grid of spots with images
    ↓
User filters: "Show only beaches"
    ↓
GET /api/spots?category=Praia
    ↓
User searches: "Chapada"
    ↓
GET /api/spots?search=Chapada
```

### 3. **Advanced Filtering Options**

#### By Category
```http
GET /api/spots?category=Praia
GET /api/spots?category=Cachoeira
GET /api/spots?category=Montanha
```

#### By Location
```http
GET /api/spots?country=Brasil
GET /api/spots?city=Rio de Janeiro
GET /api/spots?country=Brasil&city=Lençóis
```

#### By Name Search
```http
GET /api/spots?search=Chapada
GET /api/spots?search=Fernando de Noronha
```

#### Combined Filters
```http
GET /api/spots?category=Praia&country=Brasil&search=Rosa
```

### 4. **Pagination for Performance**
```http
GET /api/spots?page=1&limit=20    # First 20 spots
GET /api/spots?page=2&limit=20    # Next 20 spots
GET /api/spots?page=3&limit=10    # Next 10 spots
```

### 5. **Sorting Options**
- By name (alphabetical)
- By creation date (newest first)
- By city (grouped by location)
- By category (grouped by type)

## Response Structure Design

### List View Response
```json
{
  "success": true,
  "spots": [
    {
      "spot_id": 5,
      "spot_name": "Cachoeira da Fumaça",
      "country": "Brasil",
      "city": "Lençóis",
      "category": "Cachoeira",
      "description": "Uma das cachoeiras mais altas...",
      "location": "Lençóis, Brasil",
      "created_date": "2025-06-11T10:00:00.000Z",
      "spot_image_url": "https://storage.blob.com/...",
      "spot_image_id": 15
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "total_pages": 8,
    "has_next": true,
    "has_previous": false
  },
  "filters_applied": {
    "category": "Cachoeira",
    "country": "Brasil",
    "search": null
  }
}
```

### Individual Spot Response
```http
GET /api/spots/5
```
```json
{
  "success": true,
  "spot": {
    "spot_id": 5,
    "spot_name": "Cachoeira da Fumaça",
    "country": "Brasil",
    "city": "Lençóis",
    "category": "Cachoeira", 
    "description": "Uma das cachoeiras mais altas do Brasil...",
    "location": "Lençóis, Brasil",
    "created_date": "2025-06-11T10:00:00.000Z",
    "spot_image_url": "https://storage.blob.com/...",
    "spot_image_id": 15,
    "statistics": {
      "total_reviews": 23,
      "average_rating": 4.7,
      "times_added_to_lists": 45
    }
  }
}
```

# Get Spots Function - Key Features

## 1. **Flexible Routing**
```javascript
route: 'spots/{id?}'  // One function handles both cases
```
- `GET /api/spots` - List all spots with filtering
- `GET /api/spots/123` - Get specific spot details

## 2. **Advanced Filtering System**

### Category Filtering
```
GET /api/spots?category=Praia
GET /api/spots?category=Cachoeira
GET /api/spots?category=Montanha
```

### Location Filtering
```
GET /api/spots?country=Brasil
GET /api/spots?city=Rio de Janeiro
GET /api/spots?country=Brasil&city=Lençóis
```

### Search Functionality
```
GET /api/spots?search=Chapada
```
Searches in: spot_name, description, city, category

### Combined Filters
```
GET /api/spots?category=Praia&country=Brasil&search=Rosa&orderBy=spot_name
```

## 3. **Sorting Options**

### Available Sort Fields
- `created_date` (default) - Newest spots first
- `spot_name` - Alphabetical
- `city` - Grouped by city, then by name
- `category` - Grouped by category, then by name  
- `country` - Grouped by country, then city, then name

### Usage Examples
```
GET /api/spots?orderBy=spot_name&order=asc      # A-Z
GET /api/spots?orderBy=category&order=asc       # Group by type
GET /api/spots?orderBy=city&order=desc          # Z-A by city
```

## 4. **Performance Controls**

### Image Loading Control
```
GET /api/spots?includeImages=false   # Skip image URLs (faster)
GET /api/spots?includeImages=true    # Include image URLs (default)
```

### Statistics Control  
```
GET /api/spots?includeStats=true     # Include review/rating stats (slower)
GET /api/spots?includeStats=false    # Skip stats (default, faster)
```

### Pagination Limits
```
GET /api/spots?limit=10              # 10 spots per page
GET /api/spots?limit=50              # 50 spots per page
GET /api/spots?limit=200             # Capped at 100 max
```

## 5. **Rich Response Data**

### List View Response
```json
{
  "success": true,
  "spots": [
    {
      "spot_id": 5,
      "spot_name": "Cachoeira da Fumaça",
      "country": "Brasil",
      "city": "Lençóis",
      "category": "Cachoeira",
      "description": "Uma das cachoeiras mais altas...",
      "location": "Lençóis, Brasil",           ← Computed field
      "created_date": "2025-06-11T10:00:00.000Z",
      "spot_image_id": 15,
      "spot_image_url": "https://...",         ← If includeImages=true
      "statistics": {                          ← If includeStats=true
        "total_reviews": 23,
        "average_rating": 4.7,
        "times_added_to_lists": 45
      }
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150,
    "total_pages": 8,
    "has_next": true,
    "has_previous": false
  },
  "filters_applied": {
    "category": "Cachoeira",
    "country": "Brasil", 
    "city": null,
    "search": null
  }
}
```

## 6. **Smart Database Queries**

### Conditional JOINs
```sql
-- Only join Images table if images are requested
LEFT JOIN Images img ON s.spot_image_id = img.image_id  -- when includeImages=true
```

### Efficient Search
```sql
WHERE (
    s.spot_name LIKE @search 
    OR s.description LIKE @search 
    OR s.city LIKE @search
    OR s.category LIKE @search
)
```

### Bulk Statistics (when needed)
```sql
-- Get statistics for multiple spots in one query instead of N queries
SELECT spot_id, COUNT(*) as total_reviews, AVG(rating) as average_rating
FROM Review_Post WHERE spot_id IN (1,2,3,4,5)
GROUP BY spot_id
```

## 7. **Error Handling & Validation**

### Invalid Parameters
```json
{
  "success": false,
  "error": "Invalid orderBy parameter. Valid options: created_date, spot_name, city, category, country"
}
```

### Spot Not Found
```json
{
  "success": false,
  "error": "Spot with ID 999 not found"
}
```

### Safe Pagination
- Automatically caps limit at 100 to prevent performance issues
- Handles invalid page numbers gracefully
- Returns proper pagination metadata