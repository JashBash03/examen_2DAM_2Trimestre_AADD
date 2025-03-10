const express = require('express');
const app = express();
const PORT = 3000;

// Ruta de prueba
app.get('/', (req, res) => {
  res.send('BIM BADABUM MR. WORLDWIRE');
});

// Levantar el servidor
app.listen(PORT, () => {
  console.log(`Servidor corriendo en el puerto ${PORT}`);
});
