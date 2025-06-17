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
 * HTTP Trigger Function for Getting List Contents
 * GET /api/lists/{listId}/spots
 */
app.http('getListContents', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'lists/{listId}/spots',
    handler: async (request, context) => {
        
        context.log('Get list contents request received');

        try {
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

            // Get query parameters for ordering and filtering
            const url = new URL(request.url);
            const orderBy = url.searchParams.get('orderBy') || 'added_date'; // Default: newest first
            const orderDirection = url.searchParams.get('order') || 'desc'; // desc or asc
            const includeImages = url.searchParams.get('includeImages') !== 'false'; // Default: true

            context.log(`Getting contents for list ${listIdNum}, orderBy: ${orderBy}, order: ${orderDirection}`);

            // Validate ordering parameters
            const validOrderBy = ['added_date', 'spot_name', 'city', 'category'];
            const validOrderDirection = ['asc', 'desc'];
            
            if (!validOrderBy.includes(orderBy)) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: `Invalid orderBy parameter. Valid options: ${validOrderBy.join(', ')}` 
                    }
                };
            }

            if (!validOrderDirection.includes(orderDirection)) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: `Invalid order parameter. Valid options: ${validOrderDirection.join(', ')}` 
                    }
                };
            }

            // Connect to database
            context.log('Connecting to database...');
            const pool = await sql.connect(dbConfig);
            const request_db = new sql.Request(pool);

            try {
                // Step 1: Verify list exists and get list metadata
                context.log('Verifying list exists...');
                const listCheckResult = await request_db
                    .input('list_id', sql.Int, listIdNum)
                    .query(`
                        SELECT list_id, list_name, is_public
                        FROM List 
                        WHERE list_id = @list_id
                    `);

                if (listCheckResult.recordset.length === 0) {
                    return {
                        status: 404,
                        jsonBody: { 
                            success: false,
                            error: `List with ID ${listIdNum} does not exist` 
                        }
                    };
                }

                const listInfo = listCheckResult.recordset[0];
                context.log('Found list:', listInfo.list_name);

                // Step 2: Get list contents with full spot details
                context.log('Fetching list contents...');
                
                // Build the ORDER BY clause dynamically
                let orderByClause;
                switch (orderBy) {
                    case 'added_date':
                        orderByClause = `lhs.created_date ${orderDirection.toUpperCase()}`;
                        break;
                    case 'spot_name':
                        orderByClause = `s.spot_name ${orderDirection.toUpperCase()}`;
                        break;
                    case 'city':
                        orderByClause = `s.city ${orderDirection.toUpperCase()}, s.spot_name ASC`;
                        break;
                    case 'category':
                        orderByClause = `s.category ${orderDirection.toUpperCase()}, s.spot_name ASC`;
                        break;
                }

                // Build image joins and fields conditionally
                const imageJoins = includeImages ? `
                    LEFT JOIN Images thumb ON lhs.list_thumbnail_id = thumb.image_id
                    LEFT JOIN Images spot_img ON s.spot_image_id = spot_img.image_id
                ` : '';

                const imageFields = includeImages ? `,
                    thumb.blob_url as thumbnail_url,
                    thumb.image_name as thumbnail_name,
                    spot_img.blob_url as spot_image_url,
                    spot_img.image_name as spot_image_name` : '';

                const contentsQuery = `
                    SELECT 
                        lhs.list_id, 
                        lhs.spot_id, 
                        lhs.created_date as added_date, 
                        lhs.list_thumbnail_id,
                        s.spot_name, 
                        s.country, 
                        s.city, 
                        s.category, 
                        s.description as spot_description,
                        s.created_date as spot_created_date,
                        s.spot_image_id,
                        l.list_name, 
                        l.is_public${imageFields}
                    FROM List_has_Spot lhs
                    INNER JOIN Spot s ON lhs.spot_id = s.spot_id
                    INNER JOIN List l ON lhs.list_id = l.list_id${imageJoins}
                    WHERE lhs.list_id = @list_id
                    ORDER BY ${orderByClause}
                `;

                const contentsRequest = new sql.Request(pool);
                const contentsResult = await contentsRequest
                    .input('list_id', sql.Int, listIdNum)
                    .query(contentsQuery);

                // Step 3: Get list statistics
                context.log('Getting list statistics...');
                const statsRequest = new sql.Request(pool);
                const statsResult = await statsRequest
                    .input('list_id', sql.Int, listIdNum)
                    .query(`
                        SELECT 
                            COUNT(*) as total_spots,
                            COUNT(lhs.list_thumbnail_id) as spots_with_thumbnails,
                            MIN(lhs.created_date) as first_spot_added,
                            MAX(lhs.created_date) as last_spot_added
                        FROM List_has_Spot lhs
                        WHERE lhs.list_id = @list_id
                    `);

                const stats = statsResult.recordset[0];

                // Step 4: Transform the data for response
                const spots = contentsResult.recordset.map(row => {
                    const spotData = {
                        spot_id: row.spot_id,
                        spot_name: row.spot_name,
                        country: row.country,
                        city: row.city,
                        category: row.category,
                        description: row.spot_description,
                        location: `${row.city}, ${row.country}`,
                        spot_created_date: row.spot_created_date?.toISOString(),
                        added_to_list_date: row.added_date.toISOString(),
                        spot_image_id: row.spot_image_id,
                        list_thumbnail_id: row.list_thumbnail_id
                    };

                    // Add image URLs if requested
                    if (includeImages) {
                        spotData.thumbnail_url = row.thumbnail_url || null;
                        spotData.thumbnail_name = row.thumbnail_name || null;
                        spotData.spot_image_url = row.spot_image_url || null;
                        spotData.spot_image_name = row.spot_image_name || null;
                    }

                    return spotData;
                });

                context.log(`Found ${spots.length} spots in list`);

                // Step 5: Build comprehensive response
                const response = {
                    success: true,
                    list_info: {
                        list_id: listIdNum,
                        list_name: listInfo.list_name,
                        is_public: listInfo.is_public,
                        total_spots: stats.total_spots,
                        spots_with_thumbnails: stats.spots_with_thumbnails,
                        first_spot_added: stats.first_spot_added?.toISOString() || null,
                        last_spot_added: stats.last_spot_added?.toISOString() || null
                    },
                    spots: spots,
                    query_info: {
                        ordered_by: orderBy,
                        order_direction: orderDirection,
                        includes_images: includeImages
                    }
                };

                return {
                    status: 200,
                    jsonBody: response
                };

            } finally {
                // Always close the connection
                await pool.close();
            }

        } catch (error) {
            context.log('ERROR getting list contents:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to retrieve list contents. Please try again.',
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});

/**
 * Helper function to get category-based statistics
 * Could be useful for displaying list breakdowns
 */
async function getCategoryBreakdown(listId, pool) {
    try {
        const request = new sql.Request(pool);
        const result = await request
            .input('list_id', sql.Int, listId)
            .query(`
                SELECT 
                    s.category,
                    COUNT(*) as count
                FROM List_has_Spot lhs
                INNER JOIN Spot s ON lhs.spot_id = s.spot_id
                WHERE lhs.list_id = @list_id
                GROUP BY s.category
                ORDER BY count DESC
            `);
        
        return result.recordset;
    } catch (error) {
        context.log('Error getting category breakdown:', error);
        return [];
    }
}

/**
 * Helper function to get related lists
 * Lists that contain similar spots
 */
async function getRelatedLists(listId, pool) {
    try {
        const request = new sql.Request(pool);
        const result = await request
            .input('list_id', sql.Int, listId)
            .query(`
                SELECT TOP 5
                    l.list_id,
                    l.list_name,
                    l.is_public,
                    COUNT(*) as common_spots
                FROM List l
                INNER JOIN List_has_Spot lhs2 ON l.list_id = lhs2.list_id
                WHERE lhs2.spot_id IN (
                    SELECT spot_id 
                    FROM List_has_Spot 
                    WHERE list_id = @list_id
                )
                AND l.list_id != @list_id
                AND l.is_public = 1
                GROUP BY l.list_id, l.list_name, l.is_public
                HAVING COUNT(*) >= 2
                ORDER BY common_spots DESC
            `);
        
        return result.recordset;
    } catch (error) {
        context.log('Error getting related lists:', error);
        return [];
    }
}