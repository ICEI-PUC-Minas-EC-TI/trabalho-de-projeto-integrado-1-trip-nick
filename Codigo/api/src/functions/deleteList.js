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
 * HTTP Trigger Function for Deleting Entire Lists
 * DELETE /api/lists/{listId}
 */
app.http('deleteList', {
    methods: ['DELETE'],
    authLevel: 'anonymous',
    route: 'lists/{listId}',
    handler: async (request, context) => {
        
        context.log('Delete list request received');

        try {
            // Validate HTTP method
            if (request.method !== 'DELETE') {
                return {
                    status: 405,
                    jsonBody: { 
                        success: false,
                        error: 'Method not allowed. Use DELETE to remove lists.' 
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

            // Get query parameters for deletion options
            const url = new URL(request.url);
            const force = url.searchParams.get('force') === 'true'; // Force delete even if has posts
            const dryRun = url.searchParams.get('dryRun') === 'true'; // Preview what would be deleted

            context.log(`Deleting list ${listIdNum}, force: ${force}, dryRun: ${dryRun}`);

            // Connect to database
            context.log('Connecting to database...');
            const pool = await sql.connect(dbConfig);
            
            // Start transaction for data consistency
            const transaction = new sql.Transaction(pool);
            await transaction.begin();

            try {
                // Step 1: Verify that the list exists and get its details
                context.log('Verifying list exists and getting details...');
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

                // Step 2: Assess the impact of deletion - count associated records
                context.log('Assessing deletion impact...');
                
                // Count spots in the list
                const spotsCountRequest = new sql.Request(transaction);
                const spotsCountResult = await spotsCountRequest
                    .input('list_id', sql.Int, listIdNum)
                    .query('SELECT COUNT(*) as spot_count FROM List_has_Spot WHERE list_id = @list_id');
                
                const spotCount = spotsCountResult.recordset[0].spot_count;

                // Count posts that reference this list
                const postsImpactRequest = new sql.Request(transaction);
                const postsImpactResult = await postsImpactRequest
                    .input('list_id', sql.Int, listIdNum)
                    .query(`
                        SELECT 
                            'Community_Post' as post_type,
                            COUNT(*) as post_count
                        FROM Community_Post WHERE list_id = @list_id
                        UNION ALL
                        SELECT 
                            'List_Post' as post_type,
                            COUNT(*) as post_count  
                        FROM List_Post WHERE list_id = @list_id
                    `);

                let communityPostsCount = 0;
                let listPostsCount = 0;
                
                postsImpactResult.recordset.forEach(row => {
                    if (row.post_type === 'Community_Post') {
                        communityPostsCount = row.post_count;
                    } else if (row.post_type === 'List_Post') {
                        listPostsCount = row.post_count;
                    }
                });

                const totalPostsAffected = communityPostsCount + listPostsCount;

                // Create impact summary
                const impactSummary = {
                    list_info: {
                        list_id: listIdNum,
                        list_name: listInfo.list_name,
                        is_public: listInfo.is_public,
                        spots_in_list: spotCount,
                        posts_referencing_list: totalPostsAffected
                    },
                    deletion_impact: {
                        list_spot_associations_to_delete: spotCount,
                        community_posts_to_delete: communityPostsCount,
                        list_posts_to_delete: listPostsCount,
                        total_posts_to_delete: totalPostsAffected
                    },
                    warnings: []
                };

                // Add warnings based on impact
                if (totalPostsAffected > 0) {
                    impactSummary.warnings.push(`${totalPostsAffected} posts will be permanently deleted`);
                }
                if (spotCount > 5) {
                    impactSummary.warnings.push(`${spotCount} spot associations will be removed`);
                }
                if (listInfo.is_public && totalPostsAffected > 0) {
                    impactSummary.warnings.push('Public posts will be deleted, affecting community visibility');
                }

                // If this is a dry run, return the impact without deleting
                if (dryRun) {
                    await transaction.rollback();
                    return {
                        status: 200,
                        jsonBody: {
                            success: true,
                            message: 'Dry run completed - no data was deleted',
                            dry_run: true,
                            would_delete: impactSummary
                        }
                    };
                }

                // Check if deletion should be blocked (safety check)
                if (totalPostsAffected > 0 && !force) {
                    await transaction.rollback();
                    return {
                        status: 409, // 409 = Conflict
                        jsonBody: { 
                            success: false,
                            error: 'List cannot be deleted because it has associated posts',
                            details: `${totalPostsAffected} posts reference this list. Use ?force=true to delete anyway, or delete the posts first.`,
                            impact: impactSummary,
                            suggestion: `DELETE /api/lists/${listIdNum}?force=true to force deletion`
                        }
                    };
                }

                // Step 3: Perform the actual deletion (cascading order is important)
                context.log('Starting cascading deletion...');

                let deletionResults = {
                    list_spot_associations_deleted: 0,
                    community_posts_deleted: 0,
                    list_posts_deleted: 0,
                    base_posts_deleted: 0,
                    list_deleted: false
                };

                // 3a: Delete List_has_Spot associations first
                if (spotCount > 0) {
                    context.log('Deleting list-spot associations...');
                    const deleteAssociationsRequest = new sql.Request(transaction);
                    const deleteAssociationsResult = await deleteAssociationsRequest
                        .input('list_id', sql.Int, listIdNum)
                        .query('DELETE FROM List_has_Spot WHERE list_id = @list_id');
                    
                    deletionResults.list_spot_associations_deleted = deleteAssociationsResult.rowsAffected[0];
                }

                // 3b: Delete posts referencing this list (and their base Post records)
                if (communityPostsCount > 0) {
                    context.log('Deleting community posts...');
                    
                    // Get the post IDs first
                    const getCommunityPostIdsRequest = new sql.Request(transaction);
                    const communityPostIds = await getCommunityPostIdsRequest
                        .input('list_id', sql.Int, listIdNum)
                        .query('SELECT post_id FROM Community_Post WHERE list_id = @list_id');
                    
                    // Delete from Community_Post table
                    const deleteCommunityPostsRequest = new sql.Request(transaction);
                    const deleteCommunityResult = await deleteCommunityPostsRequest
                        .input('list_id', sql.Int, listIdNum)
                        .query('DELETE FROM Community_Post WHERE list_id = @list_id');
                    
                    deletionResults.community_posts_deleted = deleteCommunityResult.rowsAffected[0];

                    // Delete from base Post table (if any community posts were deleted)
                    if (communityPostIds.recordset.length > 0) {
                        const postIdsList = communityPostIds.recordset.map(r => r.post_id).join(',');
                        const deleteBasePostsRequest = new sql.Request(transaction);
                        const deleteBaseResult = await deleteBasePostsRequest
                            .query(`DELETE FROM Post WHERE post_id IN (${postIdsList})`);
                        
                        deletionResults.base_posts_deleted += deleteBaseResult.rowsAffected[0];
                    }
                }

                if (listPostsCount > 0) {
                    context.log('Deleting list posts...');
                    
                    // Get the post IDs first
                    const getListPostIdsRequest = new sql.Request(transaction);
                    const listPostIds = await getListPostIdsRequest
                        .input('list_id', sql.Int, listIdNum)
                        .query('SELECT post_id FROM List_Post WHERE list_id = @list_id');
                    
                    // Delete from List_Post table
                    const deleteListPostsRequest = new sql.Request(transaction);
                    const deleteListResult = await deleteListPostsRequest
                        .input('list_id', sql.Int, listIdNum)
                        .query('DELETE FROM List_Post WHERE list_id = @list_id');
                    
                    deletionResults.list_posts_deleted = deleteListResult.rowsAffected[0];

                    // Delete from base Post table (if any list posts were deleted)
                    if (listPostIds.recordset.length > 0) {
                        const postIdsList = listPostIds.recordset.map(r => r.post_id).join(',');
                        const deleteBasePostsRequest = new sql.Request(transaction);
                        const deleteBaseResult = await deleteBasePostsRequest
                            .query(`DELETE FROM Post WHERE post_id IN (${postIdsList})`);
                        
                        deletionResults.base_posts_deleted += deleteBaseResult.rowsAffected[0];
                    }
                }

                // 3c: Finally, delete the list itself
                context.log('Deleting the list record...');
                const deleteListRequest = new sql.Request(transaction);
                const deleteListResult = await deleteListRequest
                    .input('list_id', sql.Int, listIdNum)
                    .query('DELETE FROM List WHERE list_id = @list_id');

                if (deleteListResult.rowsAffected[0] === 0) {
                    await transaction.rollback();
                    return {
                        status: 500,
                        jsonBody: { 
                            success: false,
                            error: 'Failed to delete list record',
                            details: 'The list record could not be deleted from the database'
                        }
                    };
                }

                deletionResults.list_deleted = true;

                // Commit the transaction
                await transaction.commit();
                context.log('List deletion transaction committed successfully');

                // Send comprehensive success response
                return {
                    status: 200, // 200 = Success for DELETE operations
                    jsonBody: {
                        success: true,
                        message: `List "${listInfo.list_name}" deleted successfully`,
                        data: {
                            deleted_list: {
                                list_id: listIdNum,
                                list_name: listInfo.list_name,
                                was_public: listInfo.is_public,
                                deleted_at: new Date().toISOString()
                            },
                            deletion_results: deletionResults,
                            impact_summary: {
                                total_records_deleted: (
                                    deletionResults.list_spot_associations_deleted +
                                    deletionResults.community_posts_deleted +
                                    deletionResults.list_posts_deleted +
                                    deletionResults.base_posts_deleted +
                                    (deletionResults.list_deleted ? 1 : 0)
                                ),
                                spots_removed_from_list: deletionResults.list_spot_associations_deleted,
                                posts_deleted: deletionResults.community_posts_deleted + deletionResults.list_posts_deleted,
                                operation_forced: force
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
            context.log('ERROR deleting list:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to delete list. Please try again.',
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});

/**
 * Helper function to validate list deletion permissions
 * For future use when you add user authentication
 */
function canUserDeleteList(userId, listOwnerId, isPublic) {
    // For now, anyone can delete any list (no authentication)
    // Later: return userId === listOwnerId || hasAdminPermission(userId)
    return true;
}

/**
 * Helper function to archive list instead of deleting
 * Alternative to permanent deletion
 */
async function archiveList(listId, pool) {
    try {
        const request = new sql.Request(pool);
        await request
            .input('list_id', sql.Int, listId)
            .query(`
                UPDATE List 
                SET 
                    list_name = list_name + ' (Archived)',
                    is_public = 0,
                    archived_date = GETDATE()
                WHERE list_id = @list_id
            `);
        return true;
    } catch (error) {
        return false;
    }
}

/**
 * Helper function to get list deletion history
 * Could be useful for analytics
 */
async function logListDeletion(listInfo, deletionResults, userId, pool) {
    try {
        // This would insert into a hypothetical List_Deletion_Log table
        const request = new sql.Request(pool);
        await request
            .input('list_id', sql.Int, listInfo.list_id)
            .input('list_name', sql.NVarChar(45), listInfo.list_name)
            .input('was_public', sql.Bit, listInfo.is_public)
            .input('spots_count', sql.Int, deletionResults.list_spot_associations_deleted)
            .input('posts_count', sql.Int, deletionResults.community_posts_deleted + deletionResults.list_posts_deleted)
            .input('deleted_by_user_id', sql.Int, userId || null)
            .input('deleted_at', sql.DateTime2, new Date())
            .query(`
                INSERT INTO List_Deletion_Log 
                (list_id, list_name, was_public, spots_count, posts_count, deleted_by_user_id, deleted_at)
                VALUES (@list_id, @list_name, @was_public, @spots_count, @posts_count, @deleted_by_user_id, @deleted_at)
            `);
        return true;
    } catch (error) {
        // Don't fail the main operation if logging fails
        return false;
    }
}