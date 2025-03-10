# examen_2DAM_2Trimestre_AADD

## 1. Crear un servidor básico para un deploy y configurar archivo .yml con las claves que debe gestionar GitHub.

Creamos un servidor de express implementando y configurando Cors y HTTPS con el siguiente código en nuestro `server.js` (Dato importante: no olvidarse de descargar las dependencias con `npm i`):

```Javascript
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
```

A continuación, creamos el archivo `copy.yml` para configurar las referencias de las claves tando del host del VPS como el usuario y la contraseña para no tener que guardarlas en el repositorio añadiéndole una capa de seguridad a nuestro servidor. En la parte de abajo le especificamos los comandos que debe ejecutar cuando lancemos el archivo en el servidor para que mediante `pm2` mantenga el servidor encendido mientras podemos usar la terminal para añadir cambios en caso de querer actualizarlo sin necesidad de hacer más pasos. Para automatizar este proceso le decimos que primero pare el servidor en caso de estar funcionando, después le decimos que se mueva hasta el repositorio y que haga un `git pull`. Con los cambios actualizados le decimos que instale las dependencias y finalmente iniciamos el servidor con `pm2 start ${nombre del servidor}`
Para ello debemos crear una carpeta `.github` en la raíz. Dentro de esta creamos la carpeta `workflows` y ahí creamos el archivo `copy.yml` con lo siguiente:

```YML
name: Deploy to CI/CD

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout repository
      uses: actions/checkout@v2

    - name: Install sshpass
      run: sudo apt-get install -y sshpass

    - name: Create .ssh directory
      run: mkdir -p ~/.ssh

    - name: Add remote host to known_hosts
      run: ssh-keyscan -H ${{ secrets.SSH_HOST }} >> ~/.ssh/known_hosts

    - name: Execute command on VPS
      env:
        SSHPASS: ${{ secrets.SSH_PASSWORD }}
      run: sshpass -e ssh ${{ secrets.SSH_USER }}@${{ secrets.SSH_HOST }} "pm2 stop examen && cd examen_2DAM_2Trimestre_AADD && git pull && npm install && pm2 start examen &"
```

Una vez creado, procedemos a configurar los secretos en nuestro github con los mismos nombres que le hemos especificado en el archivo .yml

![alt text](/images/captura_secretos.png)
