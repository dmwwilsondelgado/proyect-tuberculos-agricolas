const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Conexión a PostgreSQL desde utils/db.js
require('./utils/db.js');

const app = express();
const PORT = process.env.PORT || 4000;

app.use(cors());
app.use(express.json());

app.get('/', (req, res) => {
  res.json({ ok: true, mensaje: 'API De la Finca a tu Mesa funcionando' });
});

app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});