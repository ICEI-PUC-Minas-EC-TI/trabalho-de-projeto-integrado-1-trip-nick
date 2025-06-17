const { app } = require('@azure/functions');
const sql = require('mssql');

// Database configuration (same as posts.js)
const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_DATABASE,
    options: {
        encrypt: true,
        trustServerCertificate: false
    }
};

/**
 * HTTP Trigger Function for Getting Posts
 * Supports: GET /api/posts, GET /api/posts/{id}
 */
app.http('getPosts', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'posts/{id?}', // {id?} makes the id parameter optional
    handler: async (request, context) => {
        
        context.log('Get posts request received');

        try {
            // Get the post ID from the URL (if provided)
            const postId = request.params.id;
            
            // Get query parameters for pagination and filtering
            const url = new URL(request.url);
            const page = parseInt(url.searchParams.get('page')) || 1;
            const limit = parseInt(url.searchParams.get('limit')) || 20;
            const userId = url.searchParams.get('userId'); // Filter by user
            const type = url.searchParams.get('type'); // Filter by post type
            
            // Calculate offset for pagination
            const offset = (page - 1) * limit;
            
            context.log(`Request params - postId: ${postId}, page: ${page}, limit: ${limit}, userId: ${userId}, type: ${type}`);

            // Connect to database
            const pool = await sql.connect(dbConfig);
            const request_db = new sql.Request(pool);

            let query;
            let countQuery;

            if (postId) {
                // Get specific post by ID
                query = `
                    SELECT 
                        p.post_id, p.description, p.user_id, p.created_date, p.type,
                        u.display_name, u.username, u.user_email, u.biography,
                        -- Review-specific fields
                        rp.spot_id, rp.rating, 
                        s.spot_name, s.country, s.city, s.category, s.description as spot_description,
                        -- Community post fields
                        cp.title as community_title, cp.list_id as community_list_id,
                        -- List post fields  
                        lp.title as list_title, lp.list_id as list_list_id,
                        -- List info (for both community and list posts)
                        sl.list_name, sl.is_public as list_is_public
                    FROM Post p
                    LEFT JOIN Users u ON p.user_id = u.user_id
                    LEFT JOIN Review_Post rp ON p.post_id = rp.post_id
                    LEFT JOIN Spot s ON rp.spot_id = s.spot_id
                    LEFT JOIN Community_Post cp ON p.post_id = cp.post_id
                    LEFT JOIN List_Post lp ON p.post_id = lp.post_id
                    LEFT JOIN List sl ON COALESCE(cp.list_id, lp.list_id) = sl.list_id
                    WHERE p.post_id = @postId
                `;
                request_db.input('postId', sql.Int, postId);
            } else {
                // Get multiple posts with filtering and pagination
                let whereConditions = [];
                
                if (userId) {
                    whereConditions.push('p.user_id = @userId');
                    request_db.input('userId', sql.Int, userId);
                }
                
                if (type) {
                    whereConditions.push('p.type = @type');
                    request_db.input('type', sql.NVarChar(11), type);
                }
                
                const whereClause = whereConditions.length > 0 
                    ? 'WHERE ' + whereConditions.join(' AND ')
                    : '';

                query = `
                    SELECT 
                        p.post_id, p.description, p.user_id, p.created_date, p.type,
                        u.display_name, u.username,
                        -- Review-specific fields
                        rp.spot_id, rp.rating, 
                        s.spot_name, s.country, s.city, s.category,
                        -- Community post fields
                        cp.title as community_title, cp.list_id as community_list_id,
                        -- List post fields  
                        lp.title as list_title, lp.list_id as list_list_id,
                        -- List info
                        sl.list_name, sl.is_public as list_is_public
                    FROM Post p
                    LEFT JOIN Users u ON p.user_id = u.user_id
                    LEFT JOIN Review_Post rp ON p.post_id = rp.post_id
                    LEFT JOIN Spot s ON rp.spot_id = s.spot_id
                    LEFT JOIN Community_Post cp ON p.post_id = cp.post_id
                    LEFT JOIN List_Post lp ON p.post_id = lp.post_id
                    LEFT JOIN List sl ON COALESCE(cp.list_id, lp.list_id) = sl.list_id
                    ${whereClause}
                    ORDER BY p.created_date DESC
                    OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
                `;

                // Count query for pagination
                countQuery = `
                    SELECT COUNT(*) as total
                    FROM Post p
                    ${whereClause}
                `;

                request_db.input('offset', sql.Int, offset);
                request_db.input('limit', sql.Int, limit);
            }

            // Execute the main query
            context.log('Executing posts query...');
            const result = await request_db.query(query);

            if (postId) {
                // Single post response
                if (result.recordset.length === 0) {
                    return {
                        status: 404,
                        jsonBody: {
                            success: false,
                            error: 'Post not found'
                        }
                    };
                }

                const postData = transformPostData(result.recordset[0]);
                
                return {
                    status: 200,
                    jsonBody: {
                        success: true,
                        post: postData
                    }
                };
            } else {
                // Multiple posts response with pagination
                let total = 0;
                if (countQuery) {
                    const countRequest = new sql.Request(pool);
                    if (userId) countRequest.input('userId', sql.Int, userId);
                    if (type) countRequest.input('type', sql.NVarChar(11), type);
                    
                    const countResult = await countRequest.query(countQuery);
                    total = countResult.recordset[0].total;
                }

                const posts = result.recordset.map(transformPostData);

                return {
                    status: 200,
                    jsonBody: {
                        success: true,
                        posts: posts,
                        pagination: {
                            total: total,
                            page: page,
                            limit: limit,
                            hasMore: offset + posts.length < total
                        }
                    }
                };
            }

        } catch (error) {
            context.log('ERROR getting posts:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to retrieve posts. Please try again.'
                }
            };
        }
    }
});

/**
 * Transform raw database row into proper post object
 * This handles the polymorphic nature of posts
 */
function transformPostData(row) {
    // Base post data
    const basePost = {
        post_id: row.post_id,
        description: row.description,
        user_id: row.user_id,
        created_date: row.created_date,
        type: row.type
    };

    // Add user data if available
    if (row.display_name) {
        basePost.user = {
            display_name: row.display_name,
            username: row.username,
            user_email: row.user_email || undefined,
            biography: row.biography || undefined
        };
    }

    // Add type-specific data
    if (row.type === 'review') {
        return {
            ...basePost,
            spot_id: row.spot_id,
            rating: row.rating,
            // Add spot data if available
            ...(row.spot_name && {
                spot: {
                    spot_name: row.spot_name,
                    country: row.country,
                    city: row.city,
                    category: row.category,
                    description: row.spot_description
                }
            })
        };
    } else if (row.type === 'community') {
        return {
            ...basePost,
            title: row.community_title,
            list_id: row.community_list_id,
            // Add list data if available
            ...(row.list_name && {
                list: {
                    list_name: row.list_name,
                    is_public: row.list_is_public
                }
            })
        };
    } else if (row.type === 'list') {
        return {
            ...basePost,
            title: row.list_title,
            list_id: row.list_list_id,
            // Add list data if available
            ...(row.list_name && {
                list: {
                    list_name: row.list_name,
                    is_public: row.list_is_public
                }
            })
        };
    }

    return basePost;
}