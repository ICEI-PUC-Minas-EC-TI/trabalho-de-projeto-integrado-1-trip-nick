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
 * HTTP Trigger Function for Getting Spots
 * Supports: GET /api/spots, GET /api/spots/{id}
 */
app.http('getSpots', {
    methods: ['GET'],
    authLevel: 'anonymous',
    route: 'spots/{id?}', // {id?} makes the id parameter optional
    handler: async (request, context) => {
        
        context.log('Get spots request received');

        try {
            // Get the spot ID from the URL (if provided)
            const spotId = request.params.id;
            
            // Get query parameters for filtering, pagination, and sorting
            const url = new URL(request.url);
            const page = parseInt(url.searchParams.get('page')) || 1;
            const limit = Math.min(parseInt(url.searchParams.get('limit')) || 20, 100); // Max 100 per page
            const category = url.searchParams.get('category');
            const country = url.searchParams.get('country');
            const city = url.searchParams.get('city');
            const search = url.searchParams.get('search');
            const orderBy = url.searchParams.get('orderBy') || 'created_date';
            const orderDirection = url.searchParams.get('order') || 'desc';
            const includeImages = url.searchParams.get('includeImages') !== 'false';
            const includeStats = url.searchParams.get('includeStats') === 'true';
            
            // Calculate offset for pagination
            const offset = (page - 1) * limit;
            
            context.log(`Request params - spotId: ${spotId}, page: ${page}, limit: ${limit}`);
            context.log(`Filters - category: ${category}, country: ${country}, city: ${city}, search: ${search}`);

            // Validate ordering parameters
            const validOrderBy = ['created_date', 'spot_name', 'city', 'category', 'country'];
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

            // Validate spot ID if provided
            if (spotId) {
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
            }

            // Connect to database
            context.log('Connecting to database...');
            const pool = await sql.connect(dbConfig);

            try {
                if (spotId) {
                    // Get specific spot by ID
                    return await getSpotById(parseInt(spotId), includeImages, includeStats, pool, context);
                } else {
                    // Get multiple spots with filtering and pagination
                    return await getSpotsList({
                        page, limit, offset, category, country, city, search, 
                        orderBy, orderDirection, includeImages, includeStats
                    }, pool, context);
                }

            } finally {
                // Always close the connection
                await pool.close();
            }

        } catch (error) {
            context.log('ERROR getting spots:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to retrieve spots. Please try again.',
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});

/**
 * Get a specific spot by ID with detailed information
 */
async function getSpotById(spotId, includeImages, includeStats, pool, context) {
    context.log(`Getting spot by ID: ${spotId}`);
    
    const request_db = new sql.Request(pool);
    
    // Build image join if requested
    const imageJoin = includeImages ? 'LEFT JOIN Images img ON s.spot_image_id = img.image_id' : '';
    const imageFields = includeImages ? ', img.blob_url as spot_image_url, img.image_name as spot_image_name' : '';
    
    const query = `
        SELECT 
            s.spot_id, s.spot_name, s.country, s.city, s.category, 
            s.description, s.created_date, s.spot_image_id
            ${imageFields}
        FROM Spot s
        ${imageJoin}
        WHERE s.spot_id = @spot_id
    `;

    const result = await request_db
        .input('spot_id', sql.Int, spotId)
        .query(query);

    if (result.recordset.length === 0) {
        return {
            status: 404,
            jsonBody: {
                success: false,
                error: `Spot with ID ${spotId} not found`
            }
        };
    }

    const spotData = transformSpotData(result.recordset[0], includeImages);

    // Add statistics if requested
    if (includeStats) {
        spotData.statistics = await getSpotStatistics(spotId, pool);
    }

    return {
        status: 200,
        jsonBody: {
            success: true,
            spot: spotData
        }
    };
}

/**
 * Get list of spots with filtering and pagination
 */
async function getSpotsList(params, pool, context) {
    const { page, limit, offset, category, country, city, search, 
            orderBy, orderDirection, includeImages, includeStats } = params;
    
    context.log('Getting spots list with filters...');
    
    // Build WHERE clause based on filters
    let whereConditions = [];
    let queryParams = {};
    
    if (category) {
        whereConditions.push('s.category = @category');
        queryParams.category = { type: sql.NVarChar(30), value: category };
    }
    
    if (country) {
        whereConditions.push('s.country = @country');
        queryParams.country = { type: sql.NVarChar(30), value: country };
    }
    
    if (city) {
        whereConditions.push('s.city = @city');
        queryParams.city = { type: sql.NVarChar(35), value: city };
    }
    
    if (search) {
        whereConditions.push(`(
            s.spot_name LIKE @search 
            OR s.description LIKE @search 
            OR s.city LIKE @search
            OR s.category LIKE @search
        )`);
        queryParams.search = { type: sql.NVarChar(500), value: `%${search}%` };
    }
    
    const whereClause = whereConditions.length > 0 
        ? 'WHERE ' + whereConditions.join(' AND ')
        : '';

    // Build ORDER BY clause
    let orderByClause;
    switch (orderBy) {
        case 'spot_name':
            orderByClause = `s.spot_name ${orderDirection.toUpperCase()}`;
            break;
        case 'city':
            orderByClause = `s.city ${orderDirection.toUpperCase()}, s.spot_name ASC`;
            break;
        case 'category':
            orderByClause = `s.category ${orderDirection.toUpperCase()}, s.spot_name ASC`;
            break;
        case 'country':
            orderByClause = `s.country ${orderDirection.toUpperCase()}, s.city ASC, s.spot_name ASC`;
            break;
        case 'created_date':
        default:
            orderByClause = `s.created_date ${orderDirection.toUpperCase()}`;
            break;
    }

    // Build image join if requested
    const imageJoin = includeImages ? 'LEFT JOIN Images img ON s.spot_image_id = img.image_id' : '';
    const imageFields = includeImages ? ', img.blob_url as spot_image_url, img.image_name as spot_image_name' : '';

    // Main query for spots
    const spotsQuery = `
        SELECT 
            s.spot_id, s.spot_name, s.country, s.city, s.category, 
            s.description, s.created_date, s.spot_image_id
            ${imageFields}
        FROM Spot s
        ${imageJoin}
        ${whereClause}
        ORDER BY ${orderByClause}
        OFFSET @offset ROWS FETCH NEXT @limit ROWS ONLY
    `;

    // Count query for pagination
    const countQuery = `
        SELECT COUNT(*) as total
        FROM Spot s
        ${whereClause}
    `;

    // Execute main query
    const spotsRequest = new sql.Request(pool);
    
    // Add parameters
    Object.entries(queryParams).forEach(([key, param]) => {
        spotsRequest.input(key, param.type, param.value);
    });
    spotsRequest.input('offset', sql.Int, offset);
    spotsRequest.input('limit', sql.Int, limit);

    const spotsResult = await spotsRequest.query(spotsQuery);

    // Execute count query
    const countRequest = new sql.Request(pool);
    Object.entries(queryParams).forEach(([key, param]) => {
        countRequest.input(key, param.type, param.value);
    });
    
    const countResult = await countRequest.query(countQuery);
    const total = countResult.recordset[0].total;

    // Transform spots data
    const spots = spotsResult.recordset.map(row => transformSpotData(row, includeImages));

    // Add statistics to each spot if requested (expensive operation)
    if (includeStats && spots.length > 0) {
        const spotIds = spots.map(s => s.spot_id);
        const statsMap = await getBulkSpotStatistics(spotIds, pool);
        spots.forEach(spot => {
            spot.statistics = statsMap[spot.spot_id] || getDefaultStatistics();
        });
    }

    // Calculate pagination info
    const totalPages = Math.ceil(total / limit);
    const hasNext = page < totalPages;
    const hasPrevious = page > 1;

    return {
        status: 200,
        jsonBody: {
            success: true,
            spots: spots,
            pagination: {
                page: page,
                limit: limit,
                total: total,
                total_pages: totalPages,
                has_next: hasNext,
                has_previous: hasPrevious
            },
            filters_applied: {
                category: category || null,
                country: country || null,
                city: city || null,
                search: search || null
            },
            query_info: {
                ordered_by: orderBy,
                order_direction: orderDirection,
                includes_images: includeImages,
                includes_stats: includeStats
            }
        }
    };
}

/**
 * Transform raw database row into spot object
 */
function transformSpotData(row, includeImages) {
    const spotData = {
        spot_id: row.spot_id,
        spot_name: row.spot_name,
        country: row.country,
        city: row.city,
        category: row.category,
        description: row.description,
        location: `${row.city}, ${row.country}`,
        created_date: row.created_date?.toISOString(),
        spot_image_id: row.spot_image_id
    };

    if (includeImages) {
        spotData.spot_image_url = row.spot_image_url || null;
        spotData.spot_image_name = row.spot_image_name || null;
    }

    return spotData;
}

/**
 * Get statistics for a single spot
 */
async function getSpotStatistics(spotId, pool) {
    try {
        const request = new sql.Request(pool);
        const result = await request
            .input('spot_id', sql.Int, spotId)
            .query(`
                SELECT 
                    -- Review statistics
                    COUNT(rp.post_id) as total_reviews,
                    COALESCE(AVG(CAST(rp.rating as FLOAT)), 0) as average_rating,
                    -- List statistics
                    (SELECT COUNT(*) FROM List_has_Spot WHERE spot_id = @spot_id) as times_added_to_lists,
                    -- Recent activity
                    (SELECT COUNT(*) FROM Review_Post rp2 
                     INNER JOIN Post p2 ON rp2.post_id = p2.post_id 
                     WHERE rp2.spot_id = @spot_id AND p2.created_date >= DATEADD(day, -30, GETDATE())
                    ) as reviews_last_30_days
                FROM Review_Post rp
                INNER JOIN Post p ON rp.post_id = p.post_id
                WHERE rp.spot_id = @spot_id
            `);
        
        return result.recordset[0] || getDefaultStatistics();
    } catch (error) {
        return getDefaultStatistics();
    }
}

/**
 * Get statistics for multiple spots efficiently
 */
async function getBulkSpotStatistics(spotIds, pool) {
    if (spotIds.length === 0) return {};
    
    try {
        const request = new sql.Request(pool);
        const spotIdsStr = spotIds.join(',');
        
        const result = await request.query(`
            SELECT 
                rp.spot_id,
                COUNT(rp.post_id) as total_reviews,
                COALESCE(AVG(CAST(rp.rating as FLOAT)), 0) as average_rating
            FROM Review_Post rp
            INNER JOIN Post p ON rp.post_id = p.post_id
            WHERE rp.spot_id IN (${spotIdsStr})
            GROUP BY rp.spot_id
        `);
        
        const statsMap = {};
        result.recordset.forEach(row => {
            statsMap[row.spot_id] = {
                total_reviews: row.total_reviews,
                average_rating: parseFloat(row.average_rating.toFixed(1)),
                times_added_to_lists: 0, // Would need separate query
                reviews_last_30_days: 0  // Would need separate query
            };
        });
        
        return statsMap;
    } catch (error) {
        return {};
    }
}

/**
 * Default statistics object
 */
function getDefaultStatistics() {
    return {
        total_reviews: 0,
        average_rating: 0,
        times_added_to_lists: 0,
        reviews_last_30_days: 0
    };
}