# Database Connection Concepts

## How Your API Will Talk to Azure SQL

```
Flutter App → HTTP Request → Azure Function → SQL Query → Azure SQL Database
                                   ↓
Flutter App ← HTTP Response ← Azure Function ← SQL Result ← Azure SQL Database
```

## Connection String
This is like a "phone number" for your database. It contains:
- **Server address**: Where your database lives
- **Database name**: Which database to use
- **Username/Password**: Credentials to access it

Example format:
```
Server=tcp:your-server.database.windows.net,1433;
Initial Catalog=your-database-name;
Persist Security Info=False;
User ID=your-username;
Password=your-password;
```

## SQL Driver
We'll use `mssql` package - it's like a translator that converts JavaScript commands into SQL that Azure SQL understands.

## Environment Variables
We'll store sensitive info (like passwords) in environment variables instead of hardcoding them. This keeps your secrets safe.

## What We Need From You
To continue, I need your Azure SQL connection details:
1. Server name (something like `your-server.database.windows.net`)
2. Database name
3. Username
4. Password

**Note**: Never share real passwords publicly. We'll use placeholder values in examples.
