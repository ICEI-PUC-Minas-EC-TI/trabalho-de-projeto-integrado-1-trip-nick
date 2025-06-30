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
 * HTTP Trigger Function for Deleting Posts
 * DELETE /api/posts/{postId}
 */
app.http('deletePost', {
    methods: ['DELETE'],
    authLevel: 'anonymous',
    route: 'posts/{postId}',
    handler: async (request, context) => {
        
        context.log('Delete post request received');

        try {
            // Validate HTTP method
            if (request.method !== 'DELETE') {
                return {
                    status: 405,
                    jsonBody: { 
                        success: false,
                        error: 'Method not allowed. Use DELETE to remove posts.' 
                    }
                };
            }

            // Get post ID from URL parameter
            const postId = request.params.postId;
            if (!postId) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'Post ID is required in URL path' 
                    }
                };
            }

            // Validate post ID is a number
            const postIdNum = parseInt(postId);
            if (isNaN(postIdNum) || postIdNum <= 0) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'Post ID must be a positive integer' 
                    }
                };
            }

            // Get query parameters for deletion options
            const url = new URL(request.url);
            const dryRun = url.searchParams.get('dryRun') === 'true'; // Preview what would be deleted
            const softDelete = url.searchParams.get('softDelete') === 'true'; // Mark as deleted instead of removing

            context.log(`Deleting post ${postIdNum}, dryRun: ${dryRun}, softDelete: ${softDelete}`);

            // Connect to database
            context.log('Connecting to database...');
            const pool = await sql.connect(dbConfig);
            
            // Start transaction for data consistency
            const transaction = new sql.Transaction(pool);
            await transaction.begin();

            try {
                // Step 1: Get full post details including type-specific data
                context.log('Getting post details...');
                const postDetailsRequest = new sql.Request(transaction);
                const postDetailsResult = await postDetailsRequest
                    .input('post_id', sql.Int, postIdNum)
                    .query(`
                        SELECT 
                            p.post_id, p.description, p.user_id, p.created_date, p.type,
                            u.display_name, u.username,
                            -- Review-specific data
                            rp.spot_id, rp.rating,
                            s.spot_name,
                            -- Community post data
                            cp.title as community_title, cp.list_id as community_list_id,
                            -- List post data
                            lp.title as list_title, lp.list_id as list_list_id,
                            -- List info (for both community and list posts)
                            sl.list_name
                        FROM Post p
                        LEFT JOIN Users u ON p.user_id = u.user_id
                        LEFT JOIN Review_Post rp ON p.post_id = rp.post_id
                        LEFT JOIN Spot s ON rp.spot_id = s.spot_id
                        LEFT JOIN Community_Post cp ON p.post_id = cp.post_id
                        LEFT JOIN List_Post lp ON p.post_id = lp.post_id
                        LEFT JOIN List sl ON COALESCE(cp.list_id, lp.list_id) = sl.list_id
                        WHERE p.post_id = @post_id
                    `);

                if (postDetailsResult.recordset.length === 0) {
                    await transaction.rollback();
                    return {
                        status: 404,
                        jsonBody: { 
                            success: false,
                            error: `Post with ID ${postIdNum} does not exist` 
                        }
                    };
                }

                const postInfo = postDetailsResult.recordset[0];
                context.log(`Found ${postInfo.type} post by user ${postInfo.username}`);

                // Step 2: Get associated images
                context.log('Getting post images...');
                const imagesRequest = new sql.Request(transaction);
                const imagesResult = await imagesRequest
                    .input('post_id', sql.Int, postIdNum)
                    .query(`
                        SELECT 
                            pi.image_id, pi.image_order, pi.is_thumbnail,
                            i.image_name, i.blob_url
                        FROM Post_Images pi
                        LEFT JOIN Images i ON pi.image_id = i.image_id
                        WHERE pi.post_id = @post_id
                        ORDER BY pi.image_order
                    `);

                const associatedImages = imagesResult.recordset;

                // Step 3: Assess deletion impact
                let impactAssessment = {
                    post_info: {
                        post_id: postIdNum,
                        type: postInfo.type,
                        description: postInfo.description,
                        user_id: postInfo.user_id,
                        username: postInfo.username,
                        created_date: postInfo.created_date,
                        associated_images: associatedImages.length
                    },
                    deletion_impact: {
                        post_images_to_unlink: associatedImages.length,
                        type_specific_data: postInfo.type
                    },
                    warnings: []
                };

                // Add type-specific impact details
                if (postInfo.type === 'review') {
                    impactAssessment.deletion_impact.review_impact = {
                        spot_affected: postInfo.spot_name,
                        rating_removed: postInfo.rating,
                        will_affect_spot_average: true
                    };
                    impactAssessment.warnings.push(`Rating of ${postInfo.rating} stars for "${postInfo.spot_name}" will be removed`);
                    impactAssessment.warnings.push('This will affect the spot\'s average rating');
                } else if (postInfo.type === 'community') {
                    impactAssessment.deletion_impact.community_impact = {
                        shared_list: postInfo.list_name,
                        community_visibility_lost: true
                    };
                    impactAssessment.warnings.push(`Community visibility of list "${postInfo.list_name}" will be removed`);
                } else if (postInfo.type === 'list') {
                    impactAssessment.deletion_impact.list_impact = {
                        shared_list: postInfo.list_name,
                        personal_sharing_removed: true
                    };
                }

                if (associatedImages.length > 0) {
                    impactAssessment.warnings.push(`${associatedImages.length} images will be unlinked (but not deleted from storage)`);
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
                            would_delete: impactAssessment
                        }
                    };
                }

                // Step 4: Perform deletion based on type
                let deletionResults = {
                    post_images_deleted: 0,
                    type_specific_deleted: false,
                    base_post_deleted: false,
                    soft_deleted: softDelete
                };

                if (softDelete) {
                    // Soft delete: just mark as deleted
                    context.log('Performing soft delete...');
                    const softDeleteRequest = new sql.Request(transaction);
                    await softDeleteRequest
                        .input('post_id', sql.Int, postIdNum)
                        .query(`
                            UPDATE Post 
                            SET description = description + ' [DELETED]'
                            WHERE post_id = @post_id
                        `);
                    
                    deletionResults.base_post_deleted = true;
                    
                } else {
                    // Hard delete: remove all records
                    
                    // 4a: Delete post images associations
                    if (associatedImages.length > 0) {
                        context.log('Deleting post-image associations...');
                        const deleteImagesRequest = new sql.Request(transaction);
                        const deleteImagesResult = await deleteImagesRequest
                            .input('post_id', sql.Int, postIdNum)
                            .query('DELETE FROM Post_Images WHERE post_id = @post_id');
                        
                        deletionResults.post_images_deleted = deleteImagesResult.rowsAffected[0];
                    }

                    // 4b: Delete from type-specific table
                    context.log(`Deleting from ${postInfo.type} post table...`);
                    if (postInfo.type === 'review') {
                        const deleteReviewRequest = new sql.Request(transaction);
                        const deleteReviewResult = await deleteReviewRequest
                            .input('post_id', sql.Int, postIdNum)
                            .query('DELETE FROM Review_Post WHERE post_id = @post_id');
                        
                        deletionResults.type_specific_deleted = deleteReviewResult.rowsAffected[0] > 0;
                        
                    } else if (postInfo.type === 'community') {
                        const deleteCommunityRequest = new sql.Request(transaction);
                        const deleteCommunityResult = await deleteCommunityRequest
                            .input('post_id', sql.Int, postIdNum)
                            .query('DELETE FROM Community_Post WHERE post_id = @post_id');
                        
                        deletionResults.type_specific_deleted = deleteCommunityResult.rowsAffected[0] > 0;
                        
                    } else if (postInfo.type === 'list') {
                        const deleteListRequest = new sql.Request(transaction);
                        const deleteListResult = await deleteListRequest
                            .input('post_id', sql.Int, postIdNum)
                            .query('DELETE FROM List_Post WHERE post_id = @post_id');
                        
                        deletionResults.type_specific_deleted = deleteListResult.rowsAffected[0] > 0;
                    }

                    // 4c: Delete from base Post table
                    context.log('Deleting from base Post table...');
                    const deletePostRequest = new sql.Request(transaction);
                    const deletePostResult = await deletePostRequest
                        .input('post_id', sql.Int, postIdNum)
                        .query('DELETE FROM Post WHERE post_id = @post_id');

                    if (deletePostResult.rowsAffected[0] === 0) {
                        await transaction.rollback();
                        return {
                            status: 500,
                            jsonBody: { 
                                success: false,
                                error: 'Failed to delete post record',
                                details: 'The post record could not be deleted from the database'
                            }
                        };
                    }

                    deletionResults.base_post_deleted = true;
                }

                // Step 5: Update related statistics (for review posts)
                if (postInfo.type === 'review' && postInfo.spot_id && !softDelete) {
                    context.log('Updating spot rating statistics...');
                    // The spot's average rating will be automatically recalculated 
                    // when the application queries for it, since we removed this review
                }

                // Commit the transaction
                await transaction.commit();
                context.log('Post deletion transaction committed successfully');

                // Step 6: Build success response
                const responseData = {
                    deleted_post: {
                        post_id: postIdNum,
                        type: postInfo.type,
                        description: postInfo.description,
                        user_id: postInfo.user_id,
                        username: postInfo.username,
                        created_date: postInfo.created_date.toISOString(),
                        deleted_at: new Date().toISOString()
                    },
                    deletion_results: deletionResults,
                    impact_summary: {
                        total_records_affected: (
                            deletionResults.post_images_deleted +
                            (deletionResults.type_specific_deleted ? 1 : 0) +
                            (deletionResults.base_post_deleted ? 1 : 0)
                        ),
                        images_unlinked: deletionResults.post_images_deleted,
                        soft_deleted: softDelete
                    }
                };

                // Add type-specific impact details to response
                if (postInfo.type === 'review') {
                    responseData.impact_summary.spot_rating_updated = !softDelete;
                    responseData.impact_summary.spot_affected = postInfo.spot_name;
                    responseData.impact_summary.rating_removed = postInfo.rating;
                } else if (postInfo.type === 'community' || postInfo.type === 'list') {
                    responseData.impact_summary.list_affected = postInfo.list_name;
                }

                return {
                    status: 200,
                    jsonBody: {
                        success: true,
                        message: `${postInfo.type.charAt(0).toUpperCase() + postInfo.type.slice(1)} post ${softDelete ? 'marked as deleted' : 'deleted'} successfully`,
                        data: responseData
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
            context.log('ERROR deleting post:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to delete post. Please try again.',
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});

/**
 * Helper function to validate post deletion permissions
 * For future use when you add user authentication
 */
function canUserDeletePost(requestingUserId, postUserId, isUserModerator = false) {
    // For now, anyone can delete any post (no authentication)
    // Later: return requestingUserId === postUserId || isUserModerator
    return true;
}

/**
 * Helper function to get posts by same user
 * Could be useful for bulk operations
 */
async function getUserPostCount(userId, pool) {
    try {
        const request = new sql.Request(pool);
        const result = await request
            .input('user_id', sql.Int, userId)
            .query(`
                SELECT 
                    COUNT(*) as total_posts,
                    SUM(CASE WHEN type = 'review' THEN 1 ELSE 0 END) as review_posts,
                    SUM(CASE WHEN type = 'community' THEN 1 ELSE 0 END) as community_posts,
                    SUM(CASE WHEN type = 'list' THEN 1 ELSE 0 END) as list_posts
                FROM Post 
                WHERE user_id = @user_id
            `);
        
        return result.recordset[0];
    } catch (error) {
        return null;
    }
}

/**
 * Helper function to log post deletion for analytics
 */
async function logPostDeletion(postInfo, deletionResults, requestingUserId, pool) {
    try {
        // This would insert into a hypothetical Post_Deletion_Log table
        const request = new sql.Request(pool);
        await request
            .input('post_id', sql.Int, postInfo.post_id)
            .input('post_type', sql.NVarChar(11), postInfo.type)
            .input('post_user_id', sql.Int, postInfo.user_id)
            .input('deleted_by_user_id', sql.Int, requestingUserId || postInfo.user_id)
            .input('soft_delete', sql.Bit, deletionResults.soft_deleted)
            .input('images_count', sql.Int, deletionResults.post_images_deleted)
            .input('deleted_at', sql.DateTime2, new Date())
            .query(`
                INSERT INTO Post_Deletion_Log 
                (post_id, post_type, post_user_id, deleted_by_user_id, soft_delete, images_count, deleted_at)
                VALUES (@post_id, @post_type, @post_user_id, @deleted_by_user_id, @soft_delete, @images_count, @deleted_at)
            `);
        return true;
    } catch (error) {
        // Don't fail the main operation if logging fails
        return false;
    }
}