const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || 'finca_chcury_db',
});

pool.connect()
  .then((client) => {
    console.log(`✅ Conectado a PostgreSQL (${process.env.DB_NAME || 'finca_chcury_db'})`);
    client.release();
  })
  .catch((err) => {
    console.error('❌ Error conectando a PostgreSQL:', err.message);
  });

module.exports = pool;