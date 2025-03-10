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

Posteriormente, continuamos por crear el archivo que utilizaremos para lanzar el deploy que llamaremos `deploy.sh`. En él debemos añadir lo siguiente:

Esta parte del código se encarga de exportar las variables del archivo `.env`
```SH
source .env # Cargar variables de entorno para mayor seguridad
```

En esta sección le damos valor a las referencias que haremos a lo largo del código necesarias para la configuración del deploy. Esto nos ayudará a encontrar de forma más eficiente la `privkey.pem` y la `fullchain.pem` para moverlas a la carpeta raíz del proyecto y que así pueda funcionar.
```SH
# Var
DOMAIN="dev2.cyberbunny.online"
EMAIL="javiercamarerolopez@gmail.com"
PROJECT_DIR="$PROJECT_DIR"  # Ruta especificada en el .env
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
MESSAGE_DIR="$PROJECT_DIR/message"
```

Esta parte actualiza las versiones de los programas del sistema para que no haya conflictos de versiones.
```SH
# Actualizar el sistema
echo "🔄 Actualizando paquetes..."
sudo apt update -y && sudo apt upgrade -y
```

Este código descarga Certbot, un programa que nos ayudará a obtener los permisos de seguridad para tener un servdor HTTPS.
```SH
# Instalar Certbot si no está instalado
if ! command -v certbot &> /dev/null; then
    echo "⚙️ Instalando Certbot..."
    sudo apt install -y certbot
else
    echo "✅ Certbot ya está instalado."
fi
```

Aquí nos encargamos de obtener los certificados para el servidor y de crear un directorio donde guardarlos.
```SH
# Obtener certificados SSL
echo "🔐 Obteniendo certificados SSL..."
sudo certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

# Crear directorio para los certificados si no existe
mkdir -p "$MESSAGE_DIR"
```

Copiamos los certificados a la carpeta en la que estamos trabajando, aseguramos los permisos, configuramos la actualización de los certificados.
```SH
# Copiar certificados al directorio del proyecto
echo "📂 Moviendo certificados..."
sudo cp "$CERT_DIR/privkey.pem" "$MESSAGE_DIR/"
sudo cp "$CERT_DIR/fullchain.pem" "$MESSAGE_DIR/"

# Asegurar permisos adecuados
sudo chown -R $USER:$USER "$MESSAGE_DIR"
sudo chmod 600 "$MESSAGE_DIR/privkey.pem" "$MESSAGE_DIR/fullchain.pem"

# Configurar renovación automática de certificados
echo "⏳ Configurando renovación automática de certificados..."
(crontab -l | grep -v certbot; echo "0 0 * * * /usr/bin/certbot renew --quiet") | crontab -
```

Por último, hacemos que se mueva al directorio del proyecto, que instale las dependencias y que inicie el servidor. Al final hacemos una comprobación de que todo funciona como debe.
```SH
# Entrar en el directorio del proyecto
cd "$PROJECT_DIR" || exit

# Instalar dependencias
echo "📦 Instalando dependencias..."
npm install

# Iniciar el servidor
echo "🚀 Iniciando servidor..."
npm run start &

# Comprobar que el servidor está corriendo
sleep 5
if curl -k --silent --fail "https://$DOMAIN:3000/" > /dev/null; then
    echo "✅ El servidor está en ejecución correctamente."
else
    echo "❌ Error al iniciar el servidor."
fi
```

Esta es la forma de iniciar el servidor VPS de forma remota para lanzar el archivo anterior.
![alt text](/images/inicio_VPS.png)

Así se clona el repo en el servidor.
![alt text](/images/image.png)

Estos son los comandos que he ido haciendo para hacer que funcionase el servidor de forma correcta sin darme fallos.
![alt text](/images/image_copy_2.png)

Y como resultado he obtenido el siguiente resultado:
![alt text](/images/image_copy.png)

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
