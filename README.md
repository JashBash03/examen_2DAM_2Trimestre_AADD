# examen_2DAM_2Trimestre_AADD

## 1. Crear un servidor básico para un deploy y configurar archivo .yml con las claves que debe gestionar GitHub.

Creamos un servidor básico de express para comenzar con una base con el siguiente código en nuestro `server.js` (Dato importante: no olvidarse de descargar las dependencias con `npm i`):

```Javascript
const express = require('express');
const app = express();
const PORT = 3000;

// Ruta de prueba
app.get('/', (req, res) => {
  res.send('¡Hola desde el servidor Express!');
});

// Levantar el servidor
app.listen(PORT, () => {
  console.log(`Servidor corriendo en el puerto ${PORT}`);
});
```

A continuación, usamos el archivo `copy.yml` del repositorio `basic-deploy` para configurar las referencias de las claves tando del host del VPS como el usuario y la contraseña para no tener que guardarlas en el repositorio añadiéndole una capa de seguridad a nuestro servidor.
Para ello debemos crear una carpeta `.github` en la raíz. Dentro de esta creamos la carpeta `workflows` y ahí creamos el archivo `copy.yml` con lo siguiente:

```YML
name: Deploy to Linode

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

    - name: List files
      run: ls -la

    - name: Copy files via SCP
      env:
        SSHPASS: ${{ secrets.SSH_PASSWORD }}
      run: sshpass -e scp -r ./ ${{ secrets.SSH_USER }}@${{ secrets.SSH_HOST }}:/root/website
```

Una vez creado, procedemos a configurar los secretos en nuestro github con los mismos nombres que le hemos especificado en el archivo .yml