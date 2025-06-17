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
 * HTTP Trigger Function for Creating Tourist Spots
 * POST /api/spots
 */
app.http('createSpot', {
    methods: ['POST'],
    authLevel: 'anonymous',
    route: 'spots',
    handler: async (request, context) => {
        
        context.log('Create spot request received');

        try {
            // Validate HTTP method
            if (request.method !== 'POST') {
                return {
                    status: 405,
                    jsonBody: { 
                        success: false,
                        error: 'Method not allowed. Use POST to create spots.' 
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

            // Extract and validate required fields
            const { spot_name, country, city, category, description, spot_image_id } = requestBody;

            // Check required fields
            if (!spot_name || !country || !city || !category) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'spot_name, country, city, and category are required fields' 
                    }
                };
            }

            // Validate field lengths (based on your database schema)
            if (spot_name.length > 55) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'spot_name must be 55 characters or less' 
                    }
                };
            }

            if (country.length > 30) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'country must be 30 characters or less' 
                    }
                };
            }

            if (city.length > 35) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'city must be 35 characters or less' 
                    }
                };
            }

            if (category.length > 30) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'category must be 30 characters or less' 
                    }
                };
            }

            if (description && description.length > 500) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'description must be 500 characters or less' 
                    }
                };
            }

            // Validate data types
            if (spot_image_id !== null && spot_image_id !== undefined) {
                if (!Number.isInteger(spot_image_id) || spot_image_id <= 0) {
                    return {
                        status: 400,
                        jsonBody: { 
                            success: false,
                            error: 'spot_image_id must be a positive integer' 
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
                // Check if image exists (if provided)
                if (spot_image_id) {
                    context.log('Validating image exists...');
                    const imageCheckRequest = new sql.Request(transaction);
                    const imageResult = await imageCheckRequest
                        .input('image_id', sql.Int, spot_image_id)
                        .query('SELECT image_id FROM Images WHERE image_id = @image_id');

                    if (imageResult.recordset.length === 0) {
                        await transaction.rollback();
                        return {
                            status: 400,
                            jsonBody: { 
                                success: false,
                                error: `Image with ID ${spot_image_id} does not exist` 
                            }
                        };
                    }
                }

                // Check for duplicate spot (same name in same city)
                context.log('Checking for duplicate spots...');
                const duplicateCheckRequest = new sql.Request(transaction);
                const duplicateResult = await duplicateCheckRequest
                    .input('spot_name', sql.NVarChar(55), spot_name)
                    .input('city', sql.NVarChar(35), city)
                    .input('country', sql.NVarChar(30), country)
                    .query(`
                        SELECT spot_id 
                        FROM Spot 
                        WHERE spot_name = @spot_name 
                        AND city = @city 
                        AND country = @country
                    `);

                if (duplicateResult.recordset.length > 0) {
                    await transaction.rollback();
                    return {
                        status: 409, // 409 = Conflict
                        jsonBody: { 
                            success: false,
                            error: `A spot named "${spot_name}" already exists in ${city}, ${country}`,
                            existing_spot_id: duplicateResult.recordset[0].spot_id
                        }
                    };
                }

                // Insert the new spot
                context.log('Inserting new spot...');
                const insertRequest = new sql.Request(transaction);
                const insertResult = await insertRequest
                    .input('spot_name', sql.NVarChar(55), spot_name)
                    .input('country', sql.NVarChar(30), country)
                    .input('city', sql.NVarChar(35), city)
                    .input('category', sql.NVarChar(30), category)
                    .input('description', sql.NVarChar(500), description || null)
                    .input('spot_image_id', sql.Int, spot_image_id || null)
                    .query(`
                        INSERT INTO Spot (spot_name, country, city, category, description, created_date, spot_image_id)
                        OUTPUT INSERTED.spot_id, INSERTED.created_date
                        VALUES (@spot_name, @country, @city, @category, @description, GETDATE(), @spot_image_id)
                    `);

                // Get the generated spot_id and created_date
                const spot_id = insertResult.recordset[0].spot_id;
                const created_date = insertResult.recordset[0].created_date;
                
                context.log('Created spot with ID:', spot_id);

                // Commit the transaction
                await transaction.commit();
                context.log('Transaction committed successfully');

                // Send success response
                return {
                    status: 201, // 201 = Created
                    jsonBody: {
                        success: true,
                        spot_id: spot_id,
                        message: 'Spot created successfully',
                        data: {
                            spot_id,
                            spot_name,
                            country,
                            city,
                            category,
                            description: description || null,
                            created_date: created_date.toISOString(),
                            spot_image_id: spot_image_id || null
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
            context.log('ERROR creating spot:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to create spot. Please try again.',
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});

/**
 * Helper function to validate common Brazilian categories
 * You can expand this list based on your app's needs
 */
function isValidCategory(category) {
    const validCategories = [
        'Praia',
        'Cachoeira', 
        'Montanha',
        'Parque Nacional',
        'Centro Histórico',
        'Museu',
        'Santuário',
        'Mirante',
        'Trilha',
        'Lagoa',
        'Rio',
        'Gruta',
        'Hotel',
        'Pousada',
        'Camping',
        'Praça',
        'Monumento',
        'Memorial',
        'Estádio',
        'Chalé',
        'Natureza',
    ];
    
    return validCategories.includes(category);
}

// You could add this validation if you want to enforce specific categories:
// if (!isValidCategory(category)) {
//     return {
//         status: 400,
//         jsonBody: { 
//             success: false,
//             error: `Invalid category. Valid options: ${validCategories.join(', ')}` 
//         }
//     };
// }