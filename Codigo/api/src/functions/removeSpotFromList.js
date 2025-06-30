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
 * HTTP Trigger Function for Removing Spots from Lists
 * DELETE /api/lists/{listId}/spots/{spotId}
 */
app.http('removeSpotFromList', {
    methods: ['DELETE'],
    authLevel: 'anonymous',
    route: 'lists/{listId}/spots/{spotId}',
    handler: async (request, context) => {
        
        context.log('Remove spot from list request received');

        try {
            // Validate HTTP method
            if (request.method !== 'DELETE') {
                return {
                    status: 405,
                    jsonBody: { 
                        success: false,
                        error: 'Method not allowed. Use DELETE to remove spots from lists.' 
                    }
                };
            }

            // Get list ID and spot ID from URL parameters
            const listId = request.params.listId;
            const spotId = request.params.spotId;

            if (!listId || !spotId) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'Both list ID and spot ID are required in URL path' 
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

            // Validate spot ID is a number
            const spotIdNum = parseInt(spotId);
            if (isNaN(spotIdNum) || spotIdNum <= 0) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'Spot ID must be a positive integer' 
                    }
                };
            }

            context.log(`Removing spot ${spotIdNum} from list ${listIdNum}`);

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
                    .input('spot_id', sql.Int, spotIdNum)
                    .query('SELECT spot_id, spot_name, city, country FROM Spot WHERE spot_id = @spot_id');

                if (spotResult.recordset.length === 0) {
                    await transaction.rollback();
                    return {
                        status: 404,
                        jsonBody: { 
                            success: false,
                            error: `Spot with ID ${spotIdNum} does not exist` 
                        }
                    };
                }

                const spotInfo = spotResult.recordset[0];
                context.log('Found spot:', spotInfo.spot_name);

                // Step 3: Check if the association exists
                context.log('Checking if spot is in list...');
                const associationCheckRequest = new sql.Request(transaction);
                const associationResult = await associationCheckRequest
                    .input('list_id', sql.Int, listIdNum)
                    .input('spot_id', sql.Int, spotIdNum)
                    .query(`
                        SELECT 
                            list_id, spot_id, created_date, list_thumbnail_id
                        FROM List_has_Spot 
                        WHERE list_id = @list_id AND spot_id = @spot_id
                    `);

                if (associationResult.recordset.length === 0) {
                    await transaction.rollback();
                    return {
                        status: 404,
                        jsonBody: { 
                            success: false,
                            error: `Spot "${spotInfo.spot_name}" is not in list "${listInfo.list_name}"`,
                            details: 'Cannot remove a spot that is not in the list',
                            list_info: {
                                list_id: listIdNum,
                                list_name: listInfo.list_name
                            },
                            spot_info: {
                                spot_id: spotIdNum,
                                spot_name: spotInfo.spot_name,
                                location: `${spotInfo.city}, ${spotInfo.country}`
                            }
                        }
                    };
                }

                const associationInfo = associationResult.recordset[0];
                context.log('Found association, proceeding with deletion...');

                // Step 4: Get current list statistics before deletion
                context.log('Getting current list statistics...');
                const statsBeforeRequest = new sql.Request(transaction);
                const statsBeforeResult = await statsBeforeRequest
                    .input('list_id', sql.Int, listIdNum)
                    .query(`
                        SELECT COUNT(*) as total_spots
                        FROM List_has_Spot 
                        WHERE list_id = @list_id
                    `);

                const currentSpotCount = statsBeforeResult.recordset[0].total_spots;

                // Step 5: Delete the association
                context.log('Deleting association...');
                const deleteRequest = new sql.Request(transaction);
                const deleteResult = await deleteRequest
                    .input('list_id', sql.Int, listIdNum)
                    .input('spot_id', sql.Int, spotIdNum)
                    .query(`
                        DELETE FROM List_has_Spot 
                        WHERE list_id = @list_id AND spot_id = @spot_id
                    `);

                // Check if deletion was successful
                if (deleteResult.rowsAffected[0] === 0) {
                    await transaction.rollback();
                    return {
                        status: 500,
                        jsonBody: { 
                            success: false,
                            error: 'Failed to remove spot from list',
                            details: 'Database deletion operation failed'
                        }
                    };
                }

                context.log(`Successfully removed spot ${spotIdNum} from list ${listIdNum}`);

                // Step 6: Get updated list statistics after deletion
                const statsAfterRequest = new sql.Request(transaction);
                const statsAfterResult = await statsAfterRequest
                    .input('list_id', sql.Int, listIdNum)
                    .query(`
                        SELECT 
                            COUNT(*) as remaining_spots,
                            MAX(created_date) as last_spot_added
                        FROM List_has_Spot 
                        WHERE list_id = @list_id
                    `);

                const remainingSpots = statsAfterResult.recordset[0].remaining_spots;
                const lastSpotAdded = statsAfterResult.recordset[0].last_spot_added;

                // Commit the transaction
                await transaction.commit();
                context.log('Transaction committed successfully');

                // Send success response with comprehensive information
                return {
                    status: 200, // 200 = Success (for DELETE operations)
                    jsonBody: {
                        success: true,
                        message: `Spot "${spotInfo.spot_name}" removed from list "${listInfo.list_name}" successfully`,
                        data: {
                            list_id: listIdNum,
                            spot_id: spotIdNum,
                            removed_at: new Date().toISOString(),
                            association_info: {
                                was_added_on: associationInfo.created_date.toISOString(),
                                had_thumbnail: associationInfo.list_thumbnail_id !== null,
                                list_thumbnail_id: associationInfo.list_thumbnail_id
                            },
                            list_info: {
                                list_name: listInfo.list_name,
                                is_public: listInfo.is_public,
                                spots_before_removal: currentSpotCount,
                                remaining_spots: remainingSpots,
                                last_spot_added: lastSpotAdded?.toISOString() || null
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
            context.log('ERROR removing spot from list:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to remove spot from list. Please try again.',
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});

/**
 * Helper function to validate list permissions
 * For future use when you add user authentication
 */
function canUserModifyList(userId, listOwnerId, isPublic) {
    // For now, anyone can modify any list (no authentication)
    // Later: return userId === listOwnerId || (isPublic && hasPermission)
    return true;
}

/**
 * Helper function to get related lists that also contain this spot
 * Could be useful for suggesting where to move the spot instead of just removing
 */
async function getOtherListsWithSpot(spotId, excludeListId, pool) {
    try {
        const request = new sql.Request(pool);
        const result = await request
            .input('spot_id', sql.Int, spotId)
            .input('exclude_list_id', sql.Int, excludeListId)
            .query(`
                SELECT TOP 3
                    l.list_id,
                    l.list_name,
                    l.is_public,
                    lhs.created_date as added_date
                FROM List l
                INNER JOIN List_has_Spot lhs ON l.list_id = lhs.list_id
                WHERE lhs.spot_id = @spot_id 
                AND l.list_id != @exclude_list_id
                AND l.is_public = 1
                ORDER BY lhs.created_date DESC
            `);
        
        return result.recordset;
    } catch (error) {
        context.log('Error getting other lists with spot:', error);
        return [];
    }
}

/**
 * Helper function to log list modification history
 * Could be useful for analytics or undo functionality
 */
async function logListModification(listId, spotId, action, userId, pool) {
    try {
        // This would insert into a hypothetical List_Modifications_Log table
        // Useful for tracking user behavior and implementing undo functionality
        
        const request = new sql.Request(pool);
        await request
            .input('list_id', sql.Int, listId)
            .input('spot_id', sql.Int, spotId)
            .input('action', sql.NVarChar(20), action) // 'ADDED', 'REMOVED', 'MOVED'
            .input('user_id', sql.Int, userId || null)
            .input('timestamp', sql.DateTime2, new Date())
            .query(`
                INSERT INTO List_Modifications_Log (list_id, spot_id, action, user_id, timestamp)
                VALUES (@list_id, @spot_id, @action, @user_id, @timestamp)
            `);
        
        return true;
    } catch (error) {
        // Don't fail the main operation if logging fails
        context.log('Warning: Failed to log list modification:', error);
        return false;
    }
}