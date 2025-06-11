const { app } = require('@azure/functions');
const sql = require('mssql');

// Database configuration
// These values come from your local.settings.json file
const dbConfig = {
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_DATABASE,
    options: {
        encrypt: true, // Required for Azure SQL
        trustServerCertificate: false
    }
};

/**
 * HTTP Trigger Function for Post Creation
 * This replaces the old function.json + index.js approach
 */
app.http('posts', {
    methods: ['POST'],           // Only allow POST requests
    authLevel: 'anonymous',      // No authentication required
    route: 'posts',             // This makes the endpoint /api/posts
    handler: async (request, context) => {
        
        // Log the incoming request for debugging
        context.log('Post creation request received');

        try {
            // Get the JSON body from the request
            const requestBody = await request.json();
            context.log('Request body:', requestBody);

            // Validate request body exists
            if (!requestBody) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'Request body is required' 
                    }
                };
            }

            // Extract data from request
            const { type, description, user_id, spot_id, rating, list_id, title } = requestBody;

            // Validate required fields
            if (!type || !user_id) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'type and user_id are required fields' 
                    }
                };
            }

            // Validate post type
            const validTypes = ['review', 'community', 'list'];
            if (!validTypes.includes(type)) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: `Invalid post type. Must be one of: ${validTypes.join(', ')}` 
                    }
                };
            }

            // Validate type-specific requirements
            if (type === 'review') {
                if (!spot_id || rating === undefined || rating === null) {
                    return {
                        status: 400,
                        jsonBody: { 
                            success: false,
                            error: 'Review posts require spot_id and rating' 
                        }
                    };
                }
                
                // Validate rating range
                if (rating < 1 || rating > 5) {
                    return {
                        status: 400,
                        jsonBody: { 
                            success: false,
                            error: 'Rating must be between 1 and 5' 
                        }
                    };
                }
            }

            if ((type === 'community' || type === 'list') && (!title || !list_id)) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'Community and list posts require title and list_id' 
                    }
                };
            }

            // Connect to database
            context.log('Connecting to database...');
            const pool = await sql.connect(dbConfig);
            
            // Start a database transaction
            const transaction = new sql.Transaction(pool);
            await transaction.begin();

            try {
                // Step 1: Insert into base Post table
                context.log('Inserting into Post table...');
                const postRequest = new sql.Request(transaction);
                const postResult = await postRequest
                    .input('description', sql.NVarChar(500), description || null)
                    .input('user_id', sql.Int, user_id)
                    .input('type', sql.NVarChar(11), type)
                    .query(`
                        INSERT INTO Post (description, user_id, created_date, type)
                        OUTPUT INSERTED.post_id, INSERTED.created_date
                        VALUES (@description, @user_id, GETDATE(), @type)
                    `);

                // Get the generated post_id and created_date
                const post_id = postResult.recordset[0].post_id;
                const created_date = postResult.recordset[0].created_date;
                context.log('Created post with ID:', post_id);

                // Step 2: Insert into specific post type table
                if (type === 'review') {
                    context.log('Inserting into Review_Post table...');
                    const reviewRequest = new sql.Request(transaction);
                    await reviewRequest
                        .input('post_id', sql.Int, post_id)
                        .input('spot_id', sql.Int, spot_id)
                        .input('rating', sql.Int, rating)
                        .query(`
                            INSERT INTO Review_Post (post_id, spot_id, rating)
                            VALUES (@post_id, @spot_id, @rating)
                        `);
                } 
                else if (type === 'community') {
                    context.log('Inserting into Community_Post table...');
                    const communityRequest = new sql.Request(transaction);
                    await communityRequest
                        .input('post_id', sql.Int, post_id)
                        .input('title', sql.NVarChar(45), title)
                        .input('list_id', sql.Int, list_id)
                        .query(`
                            INSERT INTO Community_Post (post_id, title, list_id)
                            VALUES (@post_id, @title, @list_id)
                        `);
                }
                else if (type === 'list') {
                    context.log('Inserting into List_Post table...');
                    const listRequest = new sql.Request(transaction);
                    await listRequest
                        .input('post_id', sql.Int, post_id)
                        .input('title', sql.NVarChar(45), title)
                        .input('list_id', sql.Int, list_id)
                        .query(`
                            INSERT INTO List_Post (post_id, title, list_id)
                            VALUES (@post_id, @title, @list_id)
                        `);
                }

                // If we get here, everything worked - commit the transaction
                await transaction.commit();
                context.log('Transaction committed successfully');

                // Send success response
                return {
                    status: 201, // 201 = Created
                    jsonBody: {
                        success: true,
                        post_id: post_id,
                        message: 'Post created successfully',
                        data: {
                            post_id,
                            type,
                            description: description || null,
                            user_id,
                            created_date: created_date.toISOString(),
                            // Include type-specific data in response
                            ...(type === 'review' && { spot_id, rating }),
                            ...(type === 'community' && { title, list_id }),
                            ...(type === 'list' && { title, list_id })
                        }
                    }
                };

            } catch (dbError) {
                // Something went wrong - rollback the transaction
                await transaction.rollback();
                context.log('Transaction rolled back due to error:', dbError);
                throw dbError; // Re-throw to be caught by outer try-catch
            } finally {
                // Always close the database connection
                await pool.close();
            }

        } catch (error) {
            // Log the error for debugging (use context.log, not context.log.error)
            context.log('ERROR creating post:', error.message);
            context.log('Full error details:', error);

            // Send error response
            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to create post. Please try again.',
                    // In development, you might want to include error details
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});