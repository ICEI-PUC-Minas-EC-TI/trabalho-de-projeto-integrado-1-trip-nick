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
 * HTTP Trigger Function for Creating Lists
 * POST /api/lists
 */
app.http('createList', {
    methods: ['POST'],
    authLevel: 'anonymous',
    route: 'lists',
    handler: async (request, context) => {
        
        context.log('Create list request received');

        try {
            // Validate HTTP method
            if (request.method !== 'POST') {
                return {
                    status: 405,
                    jsonBody: { 
                        success: false,
                        error: 'Method not allowed. Use POST to create lists.' 
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
            const { list_name, is_public } = requestBody;

            // Validate required fields
            if (!list_name) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'list_name is required' 
                    }
                };
            }

            // Validate list_name is not just whitespace
            if (list_name.trim().length === 0) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'list_name cannot be empty or just whitespace' 
                    }
                };
            }

            // Validate field length (based on your database schema)
            if (list_name.length > 45) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'list_name must be 45 characters or less' 
                    }
                };
            }

            // Validate is_public data type (if provided)
            let isPublic = true; // Default to public
            if (is_public !== undefined && is_public !== null) {
                if (typeof is_public !== 'boolean') {
                    return {
                        status: 400,
                        jsonBody: { 
                            success: false,
                            error: 'is_public must be a boolean (true or false)' 
                        }
                    };
                }
                isPublic = is_public;
            }

            // Trim the list name to remove extra whitespace
            const trimmedListName = list_name.trim();

            // Connect to database
            context.log('Connecting to database...');
            const pool = await sql.connect(dbConfig);
            
            // Start transaction for data consistency
            const transaction = new sql.Transaction(pool);
            await transaction.begin();

            try {
                // Optional: Check for duplicate list names (you might want to allow duplicates)
                // For now, we'll allow duplicate names since users might have similar lists
                
                // Insert the new list
                context.log('Inserting new list...');
                const insertRequest = new sql.Request(transaction);
                const insertResult = await insertRequest
                    .input('list_name', sql.NVarChar(45), trimmedListName)
                    .input('is_public', sql.Bit, isPublic)
                    .query(`
                        INSERT INTO List (list_name, is_public)
                        OUTPUT INSERTED.list_id
                        VALUES (@list_name, @is_public)
                    `);

                // Get the generated list_id
                const list_id = insertResult.recordset[0].list_id;
                
                context.log('Created list with ID:', list_id);

                // Commit the transaction
                await transaction.commit();
                context.log('Transaction committed successfully');

                // Send success response
                return {
                    status: 201, // 201 = Created
                    jsonBody: {
                        success: true,
                        list_id: list_id,
                        message: 'List created successfully',
                        data: {
                            list_id,
                            list_name: trimmedListName,
                            is_public: isPublic
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
            context.log('ERROR creating list:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to create list. Please try again.',
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});

/**
 * Helper function to validate list name content
 * You can expand this with more sophisticated validation
 */
function isValidListName(name) {
    const trimmed = name.trim();
    
    // Check minimum length
    if (trimmed.length < 3) {
        return { valid: false, error: 'List name must be at least 3 characters long' };
    }
    
    // Check for inappropriate content (basic example)
    const inappropriate = ['spam', 'test123', 'asdf'];
    if (inappropriate.some(word => trimmed.toLowerCase().includes(word))) {
        return { valid: false, error: 'List name contains inappropriate content' };
    }
    
    // Check for only special characters
    if (!/[a-zA-Z0-9]/.test(trimmed)) {
        return { valid: false, error: 'List name must contain at least one letter or number' };
    }
    
    return { valid: true };
}

/**
 * Helper function to suggest list categories based on common patterns
 * This could be useful for auto-categorization in the future
 */
function suggestListCategory(listName) {
    const name = listName.toLowerCase();
    
    if (name.includes('praia') || name.includes('beach')) return 'Praias';
    if (name.includes('cachoeira') || name.includes('waterfall')) return 'Cachoeiras';
    if (name.includes('montanha') || name.includes('mountain')) return 'Montanhas';
    if (name.includes('restaurante') || name.includes('comida')) return 'Gastronomia';
    if (name.includes('hotel') || name.includes('pousada')) return 'Hospedagem';
    if (name.includes('museu') || name.includes('história')) return 'Cultura';
    if (name.includes('trilha') || name.includes('hiking')) return 'Aventura';
    if (name.includes('desejo') || name.includes('wishlist')) return 'Lista de Desejos';
    
    return 'Geral';
}

// You could use these helper functions by uncommenting and adding validation:
// const validation = isValidListName(trimmedListName);
// if (!validation.valid) {
//     return {
//         status: 400,
//         jsonBody: { 
//             success: false,
//             error: validation.error 
//         }
//     };
// }