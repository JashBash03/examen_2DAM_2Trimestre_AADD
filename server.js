require('dotenv').config(); 
const express = require('express');
const fs = require('fs');
const https = require('https');
const http = require('http');
const path = require('path');
const cors = require('cors');

const port = 3000;
const app = express();
app.use(express.json());
app.use(express.static('public'));

app.use(cors()); // Se puede añadir a todas las rutas

// CORS middleware
/*const corsOptions = {
  origin: ['https://dev2.cyberbunny.online:3000', ''],
  optionsSuccessStatus: 200,
};*/

app.get('/', (req, res) => {
  res.send('BIM BADABUM MR. WORLDWIRE');
})


console.log(process.env.NODE_ENV); // Process.env busca la variable de entorno NODE_ENV en el proyecto
if(process.env.NODE_ENV === 'production'){

  const options = {
    key: fs.readFileSync(path.join(__dirname, 'privkey.pem')),
    cert: fs.readFileSync(path.join(__dirname, 'fullchain.pem'))
  };

  // Crear el servidor HTTPS
  https.createServer(options, app).listen(port, () => {
    console.log(`Server started on https://dev2.cyberbunny.online:${port}`);
  });
  
}else{

  // Crear el servidor HTTP
  http.createServer(app).listen(port, () => {
    console.log(`Server started on http://localhost:${port} o http://yourIP:${port}`);
  });
}