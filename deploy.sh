#!/bin/bash

source .env # Cargar variables de entorno para mayor seguridad

# Var
DOMAIN="dev2.cyberbunny.online"
EMAIL="javiercamarerolopez@gmail.com"
PROJECT_DIR="$PROJECT_DIR"  # Ruta especificada en el .env
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
MESSAGE_DIR="$PROJECT_DIR/message"

# Actualizar el sistema
echo "🔄 Actualizando paquetes..."
sudo apt update -y && sudo apt upgrade -y

# Instalar Certbot si no está instalado
if ! command -v certbot &> /dev/null; then
    echo "⚙️ Instalando Certbot..."
    sudo apt install -y certbot
else
    echo "✅ Certbot ya está instalado."
fi

# Obtener certificados SSL
echo "🔐 Obteniendo certificados SSL..."
sudo certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

# Crear directorio para los certificados si no existe
mkdir -p "$MESSAGE_DIR"

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

# Clonar repositorio (descomenta si es necesario)
# echo "🔄 Clonando repositorio..."
# git clone <URL_DEL_REPOSITORIO> "$PROJECT_DIR"

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