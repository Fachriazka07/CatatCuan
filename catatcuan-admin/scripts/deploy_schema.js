
const fs = require('fs');
const path = require('path');
const postgres = require('postgres');
require('dotenv').config({ path: '.env.local' });

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('DATABASE_URL is not defined in .env.local');
  process.exit(1);
}

const sql = postgres(connectionString, { prepare: false });

async function deploy() {
  try {
    const schemaPath = path.join(__dirname, '../catatcuan_schema.sql');
    const schemaSql = fs.readFileSync(schemaPath, 'utf8');

    console.log('Deploying schema to Supabase...');
    // Split by statement if needed, or run as a whole block if supported.
    // postgres.js might need simple query execution.
    // However, the SQL file has transactions/comments. 
    // Best to use the simple query method.
    
    await sql.unsafe(schemaSql);
    
    console.log('Schema deployed successfully!');
  } catch (error) {
    console.error('Error deploying schema:', error);
  } finally {
    await sql.end();
  }
}

deploy();
