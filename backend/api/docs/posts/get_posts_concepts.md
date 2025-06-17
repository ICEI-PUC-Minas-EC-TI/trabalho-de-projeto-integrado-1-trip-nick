# GET Posts Function - Key Concepts

## 1. **Flexible Routing**
```javascript
route: 'posts/{id?}'  // {id?} means id is optional
```
This one function handles:
- `GET /api/posts` - Get all posts
- `GET /api/posts/123` - Get specific post

## 2. **Query Parameters**
```javascript
const url = new URL(request.url);
const page = parseInt(url.searchParams.get('page')) || 1;
```
Supports URLs like:
- `/api/posts?page=2&limit=10`
- `/api/posts?userId=5&type=review`

## 3. **Database Joins (Complex Part!)**
```sql
LEFT JOIN Users u ON p.user_id = u.user_id
LEFT JOIN Review_Post rp ON p.post_id = rp.post_id
LEFT JOIN Spot s ON rp.spot_id = s.spot_id
```
**What this does:**
- Joins Post table with Users (to get author info)
- Joins with Review_Post (only for review posts)
- Joins with Spot (to get spot details for reviews)
- Uses LEFT JOIN so non-review posts still appear

## 4. **Pagination**
```sql
OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
```
- `OFFSET`: Skip the first N records
- `FETCH NEXT`: Take only the next N records
- Like: "Skip first 20, give me next 10"

## 5. **Data Transformation**
The `transformPostData` function converts raw database rows into proper objects that match your Dart models.

Raw data:
```javascript
{
  post_id: 1,
  type: 'review', 
  spot_id: 5,
  rating: 5,
  spot_name: 'Cachoeira da Fumaça'
}
```

Transformed data:
```javascript
{
  post_id: 1,
  type: 'review',
  spot_id: 5,
  rating: 5,
  spot: {
    spot_name: 'Cachoeira da Fumaça'
  }
}
```

## 6. **Error Handling**
- 404 for post not found
- 500 for database errors
- Proper JSON responses for Flutter
