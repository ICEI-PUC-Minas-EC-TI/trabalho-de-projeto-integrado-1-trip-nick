# Travel App API Development Checklist


### Phase 1: Core Features (Essential for MVP)
### Phase 2: Enhanced Features (Post-MVP)
### Phase 3: Advanced Features (Future iterations)

---

## 1. **Authentication & User Management** 🔐

### Registration & Authentication
- [ ] `POST /api/auth/register` - User registration
- [ ] `POST /api/auth/login` - User authentication
- [ ] `POST /api/auth/logout` - User logout
- [ ] `POST /api/auth/refresh` - Refresh access token
- [ ] `POST /api/auth/forgot-password` - Request password reset
- [ ] `POST /api/auth/reset-password` - Reset password with token

### User Profile Management
- [ ] `GET /api/users/profile` - Get current user profile
- [ ] `PUT /api/users/profile` - Update user profile
- [ ] `GET /api/users/{id}` - Get public user profile
- [ ] `DELETE /api/users/profile` - Delete user account
- [ ] `PUT /api/users/profile/image` - Update profile image
- [ ] `GET /api/users/search` - Search users by username/name

---

## 2. **Posts Management** 📝

### Universal Post Operations
- [x] `GET /api/posts` - Get all posts (community feed with pagination, filter by type)
- [x] `GET /api/posts/{id}` - Get specific post with full details
- [x] `POST /api/posts` - Create new post (any type: community, review, list)
- [ ] `PUT /api/posts/{id}` - Update post (respects post type constraints)
- [x] `DELETE /api/posts/{id}` - Delete specific post (author only)
- [ ] `GET /api/posts/user/{userId}` - Get posts by specific user (filter by type)

### Post Filtering & Discovery
- [x] `GET /api/posts?type=community` - Get community posts only
- [x] `GET /api/posts?type=review` - Get review posts only
- [x] `GET /api/posts?type=list` - Get list posts only
- [ ] `GET /api/posts?spot_id={spotId}` - Get all posts related to a specific spot
- [ ] `GET /api/posts?list_id={listId}` - Get all posts related to a specific list

---

## 3. **Spots Management** 📍

### Basic Spot Operations
- [x] `GET /api/spots/{id}` - Get specific spot with details
- [x] `POST /api/spots` - Create new spot
- [ ] `PUT /api/spots/{id}` - Update spot information
- [ ] `DELETE /api/spots/{id}` - Delete spot (admin only, therfore Phase 2)

### Spot Discovery
- [ ] `GET /api/spots/nearby` - Get spots near a location (lat, lng, radius)
- [ ] `GET /api/spots/trending` - Get trending/popular spots
- [ ] `GET /api/spots/categories` - Get all available categories
- [ ] `GET /api/spots/search` - Search spots by name, location, or category

### Spot Statistics & Reviews
- [ ] `GET /api/spots/{id}/rating` - Get average rating for spot
- [ ] `GET /api/spots/{id}/stats` - Get spot statistics (views, saves, reviews)
- [ ] `GET /api/spots/{id}/reviews` - Get all review posts for this spot
- [ ] `GET /api/spots/top-rated` - Get highest rated spots

---

## 4. **Lists Management** 📋

### Basic List Operations
- [x] `POST /api/lists` - Create new list 
- [ ] `PUT /api/lists/{id}` - Update list (name, visibility)
- [ ] `DELETE /api/lists/{id}` - Delete list

### List-Spot Association
- [x] `POST /api/lists/{id}/spots` - Add spot to list 
- [x] `DELETE /api/lists/{id}/spots/{spotId}` - Remove spot from list
- [x] `GET /api/lists/{id}/spots` - Get list details(all spots, name, creation, etc)
- [ ] `PUT /api/lists/{id}/spots/{spotId}` - Update spot in list (thumbnail)

### List Discovery & Posts
- [ ] `GET /api/lists/public` - Get all public lists
- [ ] `GET /api/lists/user/{userId}` - Get user's public lists
- [ ] `PUT /api/lists/{id}/visibility` - Toggle list privacy
- [ ] `GET /api/lists/popular` - Get popular public lists
- [ ] `GET /api/lists/{id}/posts` - Get all posts sharing/discussing this list

---

## 5. **Images Management** 🖼️

### Image Upload
- [ ] `POST /api/images/upload-url` - Get secure upload URL for blob storage
- [ ] `POST /api/images` - Register uploaded image metadata
- [ ] `DELETE /api/images/{id}` - Delete image (and blob)
- [ ] `GET /api/images/{id}` - Get image metadata

### Post Images Association
- [ ] `POST /api/posts/{id}/images` - Add image to post
- [ ] `DELETE /api/posts/{id}/images/{imageId}` - Remove image from post
- [ ] `PUT /api/posts/{id}/images/{imageId}/order` - Update image order
- [ ] `PUT /api/posts/{id}/images/{imageId}/thumbnail` - Set as thumbnail
- [ ] `GET /api/posts/{id}/images` - Get all images for a post

### Image Processing
- [ ] `POST /api/images/compress` - Compress uploaded image
- [ ] `POST /api/images/resize` - Resize image for different uses
- [ ] `GET /api/images/thumbnails/{id}` - Get optimized thumbnail

---

## 6. **Engagement Features** ❤️

### Post Interactions
- [ ] `POST /api/posts/{id}/like` - Like/unlike a post
- [ ] `GET /api/posts/{id}/likes` - Get post likes count and users
- [ ] `POST /api/posts/{id}/save` - Save/unsave post to bookmarks
- [ ] `GET /api/posts/saved` - Get user's saved posts

### Comments System
- [ ] `POST /api/posts/{id}/comments` - Add comment to post
- [ ] `GET /api/posts/{id}/comments` - Get post comments
- [ ] `PUT /api/comments/{id}` - Update comment
- [ ] `DELETE /api/comments/{id}` - Delete comment
- [ ] `POST /api/comments/{id}/like` - Like/unlike comment

### Follow System
- [ ] `POST /api/users/{id}/follow` - Follow/unfollow user
- [ ] `GET /api/users/{id}/followers` - Get user followers
- [ ] `GET /api/users/{id}/following` - Get users that user follows
- [ ] `GET /api/users/feed` - Get personalized feed from followed users

---

## 7. **Statistics & Analytics** 📊

### User Statistics
- [ ] `GET /api/users/stats` - Get user travel statistics
- [ ] `GET /api/users/stats/visited` - Get visited spots count by category
- [ ] `GET /api/users/stats/distance` - Get total distance traveled
- [ ] `GET /api/users/stats/photos` - Get photos shared count

### Platform Analytics
- [ ] `GET /api/analytics/spots/popular` - Most visited spots
- [ ] `GET /api/analytics/users/active` - Most active users
- [ ] `GET /api/analytics/posts/engagement` - Post engagement metrics
- [ ] `GET /api/analytics/trends` - Platform usage trends

---

## 8. **Search & Discovery** 🔍

### Global Search
- [ ] `GET /api/search/global` - Search across posts, spots, users, lists
- [ ] `GET /api/search/spots` - Advanced spot search with filters
- [ ] `GET /api/search/posts` - Search posts by content (filter by type)
- [ ] `GET /api/search/users` - Search users by name/username
- [ ] `GET /api/search/lists` - Search public lists

### Recommendations
- [ ] `GET /api/recommendations/spots` - Get personalized spot recommendations
- [ ] `GET /api/recommendations/users` - Get suggested users to follow
- [ ] `GET /api/recommendations/lists` - Get recommended lists to explore

---