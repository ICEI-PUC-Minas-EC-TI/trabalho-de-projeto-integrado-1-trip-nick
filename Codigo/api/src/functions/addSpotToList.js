const { app } = require('@azure/functions');
const sql = require('mssql');

// Database configuration
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
 * HTTP Trigger Function for Adding Spots to Lists
 * POST /api/lists/{listId}/spots
 */
app.http('addSpotToList', {
    methods: ['POST'],
    authLevel: 'anonymous',
    route: 'lists/{listId}/spots',
    handler: async (request, context) => {
        
        context.log('Add spot to list request received');

        try {
            // Validate HTTP method
            if (request.method !== 'POST') {
                return {
                    status: 405,
                    jsonBody: { 
                        success: false,
                        error: 'Method not allowed. Use POST to add spots to lists.' 
                    }
                };
            }

            // Get list ID from URL parameter
            const listId = request.params.listId;
            if (!listId) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'List ID is required in URL path' 
                    }
                };
            }

            // Validate list ID is a number
            const listIdNum = parseInt(listId);
            if (isNaN(listIdNum) || listIdNum <= 0) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'List ID must be a positive integer' 
                    }
                };
            }

            // Get request body
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

            // Extract fields from request
            const { spot_id, list_thumbnail_id } = requestBody;

            // Validate required fields
            if (!spot_id) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'spot_id is required' 
                    }
                };
            }

            // Validate spot_id is a positive integer
            if (!Number.isInteger(spot_id) || spot_id <= 0) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'spot_id must be a positive integer' 
                    }
                };
            }

            // Validate list_thumbnail_id if provided
            if (list_thumbnail_id !== null && list_thumbnail_id !== undefined) {
                if (!Number.isInteger(list_thumbnail_id) || list_thumbnail_id <= 0) {
                    return {
                        status: 400,
                        jsonBody: { 
                            success: false,
                            error: 'list_thumbnail_id must be a positive integer if provided' 
                        }
                    };
                }
            }

            // Connect to database
            context.log('Connecting to database...');
            const pool = await sql.connect(dbConfig);
            
            // Start transaction for data consistency
            const transaction = new sql.Transaction(pool);
            await transaction.begin();

            try {
                // Step 1: Verify that the list exists
                context.log('Verifying list exists...');
                const listCheckRequest = new sql.Request(transaction);
                const listResult = await listCheckRequest
                    .input('list_id', sql.Int, listIdNum)
                    .query('SELECT list_id, list_name, is_public FROM List WHERE list_id = @list_id');

                if (listResult.recordset.length === 0) {
                    await transaction.rollback();
                    return {
                        status: 404,
                        jsonBody: { 
                            success: false,
                            error: `List with ID ${listIdNum} does not exist` 
                        }
                    };
                }

                const listInfo = listResult.recordset[0];
                context.log('Found list:', listInfo.list_name);

                // Step 2: Verify that the spot exists
                context.log('Verifying spot exists...');
                const spotCheckRequest = new sql.Request(transaction);
                const spotResult = await spotCheckRequest
                    .input('spot_id', sql.Int, spot_id)
                    .query('SELECT spot_id, spot_name, city, country FROM Spot WHERE spot_id = @spot_id');

                if (spotResult.recordset.length === 0) {
                    await transaction.rollback();
                    return {
                        status: 404,
                        jsonBody: { 
                            success: false,
                            error: `Spot with ID ${spot_id} does not exist` 
                        }
                    };
                }

                const spotInfo = spotResult.recordset[0];
                context.log('Found spot:', spotInfo.spot_name);

                // Step 3: Verify thumbnail image exists (if provided)
                if (list_thumbnail_id) {
                    context.log('Verifying thumbnail image exists...');
                    const imageCheckRequest = new sql.Request(transaction);
                    const imageResult = await imageCheckRequest
                        .input('image_id', sql.Int, list_thumbnail_id)
                        .query('SELECT image_id FROM Images WHERE image_id = @image_id');

                    if (imageResult.recordset.length === 0) {
                        await transaction.rollback();
                        return {
                            status: 404,
                            jsonBody: { 
                                success: false,
                                error: `Image with ID ${list_thumbnail_id} does not exist` 
                            }
                        };
                    }
                    context.log('Thumbnail image validated');
                }

                // Step 4: Check if this association already exists
                context.log('Checking for existing association...');
                const duplicateCheckRequest = new sql.Request(transaction);
                const duplicateResult = await duplicateCheckRequest
                    .input('list_id', sql.Int, listIdNum)
                    .input('spot_id', sql.Int, spot_id)
                    .query(`
                        SELECT created_date 
                        FROM List_has_Spot 
                        WHERE list_id = @list_id AND spot_id = @spot_id
                    `);

                if (duplicateResult.recordset.length > 0) {
                    await transaction.rollback();
                    return {
                        status: 409, // 409 = Conflict
                        jsonBody: { 
                            success: false,
                            error: `Spot "${spotInfo.spot_name}" is already in list "${listInfo.list_name}"`,
                            existing_association: {
                                list_id: listIdNum,
                                spot_id: spot_id,
                                added_date: duplicateResult.recordset[0].created_date
                            }
                        }
                    };
                }

                // Step 5: Create the association
                context.log('Creating list-spot association...');
                const insertRequest = new sql.Request(transaction);
                const insertResult = await insertRequest
                    .input('list_id', sql.Int, listIdNum)
                    .input('spot_id', sql.Int, spot_id)
                    .input('list_thumbnail_id', sql.Int, list_thumbnail_id || null)
                    .query(`
                        INSERT INTO List_has_Spot (list_id, spot_id, created_date, list_thumbnail_id)
                        OUTPUT INSERTED.created_date
                        VALUES (@list_id, @spot_id, GETDATE(), @list_thumbnail_id)
                    `);

                const created_date = insertResult.recordset[0].created_date;
                
                context.log(`Successfully added spot ${spot_id} to list ${listIdNum}`);

                // Commit the transaction
                await transaction.commit();
                context.log('Transaction committed successfully');

                // Send success response with full context
                return {
                    status: 201, // 201 = Created
                    jsonBody: {
                        success: true,
                        message: `Spot "${spotInfo.spot_name}" added to list "${listInfo.list_name}" successfully`,
                        data: {
                            list_id: listIdNum,
                            spot_id: spot_id,
                            list_thumbnail_id: list_thumbnail_id || null,
                            created_date: created_date.toISOString(),
                            // Include context for better UX
                            list_info: {
                                list_name: listInfo.list_name,
                                is_public: listInfo.is_public
                            },
                            spot_info: {
                                spot_name: spotInfo.spot_name,
                                location: `${spotInfo.city}, ${spotInfo.country}`
                            }
                        }
                    }
                };

            } catch (dbError) {
                // Rollback transaction on database error
                await transaction.rollback();
                context.log('Transaction rolled back due to error:', dbError);
                throw dbError;
            } finally {
                // Always close the connection
                await pool.close();
            }

        } catch (error) {
            context.log('ERROR adding spot to list:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to add spot to list. Please try again.',
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});

/**
 * Helper function to get list statistics
 * This could be used to return additional context about the list
 */
async function getListStatistics(listId, transaction) {
    try {
        const statsRequest = new sql.Request(transaction);
        const result = await statsRequest
            .input('list_id', sql.Int, listId)
            .query(`
                SELECT 
                    COUNT(*) as total_spots,
                    COUNT(lhs.list_thumbnail_id) as spots_with_thumbnails
                FROM List_has_Spot lhs
                WHERE lhs.list_id = @list_id
            `);
        
        return result.recordset[0];
    } catch (error) {
        return null;
    }
}

/**
 * Helper function to validate list permissions
 * For future use when you add user authentication
 */
function canUserModifyList(userId, listOwnerId, isPublic) {
    // For now, anyone can modify any list (no authentication)
    // Later you'll add: return userId === listOwnerId || (isPublic && hasPermission)
    return true;
}