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
 * HTTP Trigger Function for Syncing Firebase Users with Database
 * POST /api/users/sync-firebase
 * 
 * This endpoint:
 * 1. Receives Firebase user data from Flutter app
 * 2. Checks if user exists in database (by firebase_uid)
 * 3. Creates new user or updates existing user
 * 4. Returns internal user_id for API calls
 */
app.http('syncFirebaseUser', {
    methods: ['POST'],
    authLevel: 'anonymous',
    route: 'users/sync-firebase',
    handler: async (request, context) => {
        
        context.log('Firebase user sync request received');

        try {
            // Validate HTTP method
            if (request.method !== 'POST') {
                return {
                    status: 405,
                    jsonBody: { 
                        success: false,
                        error: 'Method not allowed. Use POST to sync Firebase users.' 
                    }
                };
            }

            // Get request body with Firebase user data
            const requestBody = await request.json();
            context.log('Request body:', requestBody);

            // Validate required Firebase fields
            const { firebase_uid, email, display_name, photo_url, provider } = requestBody;

            if (!firebase_uid || !email) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'firebase_uid and email are required fields' 
                    }
                };
            }

            // Validate Firebase UID format (basic check)
            if (firebase_uid.length < 10) {
                return {
                    status: 400,
                    jsonBody: { 
                        success: false,
                        error: 'Invalid firebase_uid format' 
                    }
                };
            }

            // Connect to database
            context.log('Connecting to database...');
            const pool = await sql.connect(dbConfig);
            
            // Start transaction
            const transaction = new sql.Transaction(pool);
            await transaction.begin();

            try {
                // Step 1: Check if user already exists by firebase_uid
                context.log('Checking if user exists by Firebase UID...');
                const existingUserRequest = new sql.Request(transaction);
                const existingUserResult = await existingUserRequest
                    .input('firebase_uid', sql.NVarChar(128), firebase_uid)
                    .query(`
                        SELECT user_id, display_name, username, user_email, creation_date
                        FROM Users 
                        WHERE firebase_uid = @firebase_uid
                    `);

                if (existingUserResult.recordset.length > 0) {
                    // User exists - update profile and return user_id
                    const existingUser = existingUserResult.recordset[0];
                    context.log('User exists, updating profile...');

                    const updateRequest = new sql.Request(transaction);
                    await updateRequest
                        .input('firebase_uid', sql.NVarChar(128), firebase_uid)
                        .input('display_name', sql.NVarChar(55), display_name || existingUser.display_name)
                        .input('user_email', sql.NVarChar(35), email)
                        .query(`
                            UPDATE Users 
                            SET 
                                display_name = @display_name,
                                user_email = @user_email,
                                last_update_date = CAST(GETDATE() AS DATE)
                            WHERE firebase_uid = @firebase_uid
                        `);

                    await transaction.commit();

                    return {
                        status: 200,
                        jsonBody: {
                            success: true,
                            user_id: existingUser.user_id,
                            action: 'updated',
                            message: 'User profile updated successfully',
                            user_data: {
                                user_id: existingUser.user_id,
                                firebase_uid: firebase_uid,
                                display_name: display_name || existingUser.display_name,
                                username: existingUser.username,
                                email: email
                            }
                        }
                    };
                }

                // Step 2: User doesn't exist - create new user
                context.log('User does not exist, creating new user...');

                // Generate unique username from email/display_name
                const generatedUsername = await generateUniqueUsername(
                    display_name || email, 
                    transaction
                );

                // Step 3: Create new user record
                const insertRequest = new sql.Request(transaction);
                const insertResult = await insertRequest
                    .input('firebase_uid', sql.NVarChar(128), firebase_uid)
                    .input('display_name', sql.NVarChar(55), display_name || 'User')
                    .input('username', sql.NVarChar(21), generatedUsername)
                    .input('user_email', sql.NVarChar(35), email)
                    .input('created_via', sql.NVarChar(20), provider || 'firebase')
                    .query(`
                        INSERT INTO Users (
                            firebase_uid, display_name, username, user_email, 
                            creation_date, last_update_date, created_via
                        )
                        OUTPUT INSERTED.user_id
                        VALUES (
                            @firebase_uid, @display_name, @username, @user_email,
                            CAST(GETDATE() AS DATE), CAST(GETDATE() AS DATE), @created_via
                        )
                    `);

                const newUserId = insertResult.recordset[0].user_id;
                context.log('Created new user with ID:', newUserId);

                await transaction.commit();

                return {
                    status: 201,
                    jsonBody: {
                        success: true,
                        user_id: newUserId,
                        action: 'created',
                        message: 'User created successfully',
                        user_data: {
                            user_id: newUserId,
                            firebase_uid: firebase_uid,
                            display_name: display_name || 'User',
                            username: generatedUsername,
                            email: email,
                            created_via: provider || 'firebase'
                        }
                    }
                };

            } catch (dbError) {
                await transaction.rollback();
                context.log('Database transaction error:', dbError);
                throw dbError;
            } finally {
                await pool.close();
            }

        } catch (error) {
            context.log('ERROR syncing Firebase user:', error.message);
            context.log('Full error details:', error);

            return {
                status: 500,
                jsonBody: {
                    success: false,
                    error: 'Internal server error',
                    message: 'Failed to sync user. Please try again.',
                    ...(process.env.NODE_ENV === 'development' && { details: error.message })
                }
            };
        }
    }
});

/**
 * Generate unique username from display name or email
 */
async function generateUniqueUsername(displayNameOrEmail, transaction) {
    // Start with display name or email prefix
    let baseUsername = displayNameOrEmail
        .split('@')[0] // Take part before @ if it's an email
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '') // Remove special characters
        .substring(0, 15); // Limit length

    // Fallback if empty
    if (!baseUsername) {
        baseUsername = 'user';
    }

    // Check if base username is available
    let username = baseUsername;
    let counter = 1;

    while (true) {
        const checkRequest = new sql.Request(transaction);
        const checkResult = await checkRequest
            .input('username', sql.NVarChar(21), username)
            .query('SELECT user_id FROM Users WHERE username = @username');

        if (checkResult.recordset.length === 0) {
            // Username is available
            return username;
        }

        // Username taken, try with number suffix
        username = `${baseUsername}${counter}`;
        counter++;

        // Safety check to avoid infinite loop
        if (counter > 9999) {
            // Fallback to random username
            username = `user${Date.now().toString().slice(-6)}`;
            break;
        }
    }

    return username;
}