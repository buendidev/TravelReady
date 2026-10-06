# AWS_NOTES.md — TravelReady! · Uso de AWS
# Pablo Buendicho Ortín · Abril 2026

---

## Usos recomendados (coste $0 con Free Tier)

### 1. API proxy de clima con caché — EC2 t2.micro

**Por qué**: OpenWeatherMap free tier limita a 60 llamadas/min y 1000/día.
Con un proxy en EC2, haces 1 llamada cada 30 min y sirves a todos los usuarios.

**Setup**:
```bash
# En EC2 Ubuntu 24.04:
sudo apt update && sudo apt install -y nodejs npm nginx
sudo npm install -g pm2

# Crear API en Node.js con caché en memoria
# GET /weather?city=Madrid → OpenWeatherMap → caché 30 min → respuesta
```

**En Flutter** (`weather_service.dart`):
```dart
// En producción, cambiar _base a tu EC2:
static const _base = 'https://api.tudominio.com';
// En dev, seguir usando OpenWeatherMap directo
```

---

### 2. Hosting de documentación — S3 + CloudFront

**Por qué**: Publicar la web del producto con un enlace limpio y profesional.

```bash
# Crear bucket S3
aws s3 mb s3://travelready-docs
aws s3 website s3://travelready-docs --index-document index.html

# Subir docs (generados con MkDocs o similar)
aws s3 sync ./docs s3://travelready-docs --acl public-read

# CloudFront para HTTPS
# → aws cloudfront create-distribution ...
```

**URL resultado**: `https://dXXXX.cloudfront.net`

---

### 3. Servidor de notificaciones push — EC2

```bash
# Stack: Node.js + Firebase Admin SDK
# Cron jobs para recordatorios:
# - "Faltan 3 días para tu viaje a París"
# - "Tu lista está al 50%"
# - "Alerta de lluvia en tu destino"
```

```javascript
// Enviar notificación desde server:
const admin = require('firebase-admin');
await admin.messaging().send({
  token: userFcmToken,
  notification: { title: '🌧️ Lluvia en París', body: '...' }
});
```

---

### 4. VPN privada — WireGuard en EC2

```bash
sudo apt install wireguard
# Configura servidor + añade peers (PC + móvil de desarrollo)
# Útil para pruebas en entorno controlado
```

---

## Setup EC2 paso a paso

```bash
# 1. AWS Console → EC2 → Launch Instance
#    AMI: Ubuntu Server 24.04 LTS
#    Type: t2.micro (free tier)
#    Security Group: puertos 22, 80, 443
#    Key pair: crear + descargar .pem

# 2. Conectar
ssh -i "travelready-key.pem" ubuntu@<IP_PUBLICA>

# 3. Nginx como reverse proxy
sudo apt install -y nginx
sudo nano /etc/nginx/sites-available/weather-proxy
# server { listen 80; location / { proxy_pass http://localhost:3000; } }
sudo ln -s /etc/nginx/sites-available/weather-proxy /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 4. SSL gratuito (Let's Encrypt)
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.tudominio.com
```

---

## Coste estimado mensual

| Servicio | Uso | Coste |
|---|---|---|
| EC2 t2.micro | 750h/mes | $0 free tier |
| S3 | 5GB + peticiones | $0 free tier |
| CloudFront | 1TB transferencia | $0 primer año |
| Elastic IP | 1 IP estática | $0 si asociada |
| **Total** | | **$0/mes** |

---

## Importante — AWS Academy

La cuenta sandbox de AWS Academy caduca al final del curso.
**Antes de que expire**: exporta configuraciones como plantillas CloudFormation
para poder recrearlas en una cuenta propia si lo necesitas.

```bash
aws cloudformation describe-stacks --query 'Stacks[*]'
```

---

## No recomendado: reemplazar Firebase con AWS

- DynamoDB + Amplify requeriría reescribir toda la capa de datos
- Firebase ya cubre las necesidades actuales del producto
- La complejidad añadida de la migración no aporta valor frente a su coste
