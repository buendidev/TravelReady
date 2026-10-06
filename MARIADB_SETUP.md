# MARIADB_SETUP.md — TravelReady! · Base de datos relacional
# Pablo Buendicho Ortín · Abril 2026
# Contexto: esto describe la BD MariaDB necesaria si se creara un backend propio
# en EC2 en lugar de usar Firestore. Es documentación de diseño del producto.

---

## PARTE 1 — BD DE CUENTAS (gestión de clientes/tenants del SaaS)

Esta BD gestiona el negocio: qué clientes tienen la app, sus planes y facturación.
Se separa de la BD de aplicación porque tiene datos sensibles de pago.

```sql
-- ======================================================================
-- BASE DE DATOS: travelready_accounts
-- Gestión de clientes, planes y facturación
-- ======================================================================

CREATE DATABASE IF NOT EXISTS travelready_accounts
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE travelready_accounts;

-- ── Planes de suscripción disponibles ───────────────────────────────────
CREATE TABLE plans (
  id           CHAR(36)       PRIMARY KEY DEFAULT (UUID()),
  name         VARCHAR(50)    NOT NULL UNIQUE,       -- 'free', 'premium_monthly', 'premium_yearly'
  display_name VARCHAR(100)   NOT NULL,              -- 'Plan Gratuito', 'Premium Mensual'
  price_eur    DECIMAL(8,2)   NOT NULL DEFAULT 0.00, -- Precio en euros
  billing_cycle ENUM('none','monthly','yearly') DEFAULT 'none',
  features     JSON,                                 -- Lista de features incluidas
  is_active    BOOLEAN        DEFAULT TRUE,
  created_at   DATETIME       DEFAULT CURRENT_TIMESTAMP
);

-- Datos iniciales
INSERT INTO plans (name, display_name, price_eur, billing_cycle, features) VALUES
('free', 'Plan Gratuito', 0.00, 'none', JSON_ARRAY(
  'Hasta 3 viajes activos',
  'Hasta 2 listas por viaje',
  'Asistente IA básico',
  'Chats privados'
)),
('premium_monthly', 'Premium Mensual', 2.99, 'monthly', JSON_ARRAY(
  'Viajes ilimitados',
  'Listas ilimitadas',
  'Generación IA completa',
  'Chats grupales',
  'Sin anuncios',
  'Exportar PDF',
  'Soporte prioritario'
)),
('premium_yearly', 'Premium Anual', 19.99, 'yearly', JSON_ARRAY(
  'Todo lo de Premium Mensual',
  'Ahorro del 44%',
  'Acceso anticipado a nuevas funciones'
));

-- ── Clientes / Tenants (empresas o usuarios individuales) ────────────────
CREATE TABLE tenants (
  id           CHAR(36)       PRIMARY KEY DEFAULT (UUID()),
  name         VARCHAR(150)   NOT NULL,
  email        VARCHAR(255)   NOT NULL UNIQUE,
  phone        VARCHAR(20),
  country_code CHAR(2)        DEFAULT 'ES',        -- ISO 3166-1 alpha-2
  vat_number   VARCHAR(30),                        -- NIF/CIF para facturación
  plan_id      CHAR(36)       NOT NULL REFERENCES plans(id),
  plan_start   DATE,
  plan_end     DATE,                               -- NULL = sin caducidad (free)
  is_active    BOOLEAN        DEFAULT TRUE,
  notes        TEXT,
  created_at   DATETIME       DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_plan_id (plan_id)
);

-- ── Historial de suscripciones ───────────────────────────────────────────
CREATE TABLE subscriptions (
  id              CHAR(36)   PRIMARY KEY DEFAULT (UUID()),
  tenant_id       CHAR(36)   NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  plan_id         CHAR(36)   NOT NULL REFERENCES plans(id),
  status          ENUM('active','cancelled','expired','trial','past_due') DEFAULT 'active',
  provider        VARCHAR(50) DEFAULT 'revenuecat',  -- 'revenuecat', 'stripe', 'manual'
  provider_sub_id VARCHAR(200),                       -- ID de suscripción en RevenueCat/Stripe
  started_at      DATETIME   NOT NULL,
  ends_at         DATETIME,
  cancelled_at    DATETIME,
  cancel_reason   VARCHAR(200),
  created_at      DATETIME   DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tenant_id (tenant_id),
  INDEX idx_status (status),
  INDEX idx_ends_at (ends_at)
);

-- ── Facturas ────────────────────────────────────────────────────────────
CREATE TABLE invoices (
  id              CHAR(36)        PRIMARY KEY DEFAULT (UUID()),
  tenant_id       CHAR(36)        NOT NULL REFERENCES tenants(id),
  subscription_id CHAR(36)        REFERENCES subscriptions(id),
  invoice_number  VARCHAR(30)     NOT NULL UNIQUE,  -- 'TRV-2026-00001'
  amount_eur      DECIMAL(10,2)   NOT NULL,
  tax_rate        DECIMAL(5,2)    DEFAULT 21.00,    -- IVA España
  tax_amount      DECIMAL(10,2)   NOT NULL,
  total_eur       DECIMAL(10,2)   NOT NULL,
  status          ENUM('draft','sent','paid','overdue','cancelled') DEFAULT 'draft',
  issued_at       DATE,
  due_at          DATE,
  paid_at         DATETIME,
  payment_method  VARCHAR(50),
  notes           TEXT,
  created_at      DATETIME        DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tenant_id (tenant_id),
  INDEX idx_status (status),
  INDEX idx_issued_at (issued_at)
);

-- ── API Keys (para integraciones futuras) ────────────────────────────────
CREATE TABLE api_keys (
  id          CHAR(36)      PRIMARY KEY DEFAULT (UUID()),
  tenant_id   CHAR(36)      NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  name        VARCHAR(100)  NOT NULL,                  -- 'Key de producción'
  key_hash    CHAR(64)      NOT NULL UNIQUE,            -- SHA-256 de la key
  prefix      CHAR(8)       NOT NULL,                   -- Primeros 8 chars en claro
  last_used   DATETIME,
  expires_at  DATETIME,
  is_active   BOOLEAN       DEFAULT TRUE,
  created_at  DATETIME      DEFAULT CURRENT_TIMESTAMP
);

-- ── Log de actividad de cuenta ───────────────────────────────────────────
CREATE TABLE account_events (
  id          BIGINT         AUTO_INCREMENT PRIMARY KEY,
  tenant_id   CHAR(36)       REFERENCES tenants(id),
  event_type  VARCHAR(50)    NOT NULL,    -- 'plan_upgrade','plan_cancel','login','payment_failed'
  payload     JSON,
  ip_address  VARCHAR(45),
  user_agent  VARCHAR(500),
  created_at  DATETIME       DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_tenant_id (tenant_id),
  INDEX idx_event_type (event_type),
  INDEX idx_created_at (created_at)
);
```

---

## PARTE 2 — BD DE APLICACIÓN (datos de usuarios y viajes)

Esta BD contiene todos los datos de la app por cliente. Si el SaaS es multi-tenant,
se puede usar una BD por tenant o una BD compartida con `tenant_id` en cada tabla.
Con el alcance actual del producto, se recomienda BD compartida (más sencillo).

```sql
-- ======================================================================
-- BASE DE DATOS: travelready_app
-- Datos de usuarios, viajes, listas de equipaje y chats
-- ======================================================================

CREATE DATABASE IF NOT EXISTS travelready_app
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

USE travelready_app;

-- ── Usuarios ─────────────────────────────────────────────────────────────
CREATE TABLE users (
  id              CHAR(36)       PRIMARY KEY DEFAULT (UUID()),
  tenant_id       CHAR(36)       NOT NULL,               -- ref a travelready_accounts.tenants
  firebase_uid    VARCHAR(128)   UNIQUE,                  -- UID de Firebase Auth
  name            VARCHAR(100)   NOT NULL,
  email           VARCHAR(255)   NOT NULL UNIQUE,
  email_verified  BOOLEAN        DEFAULT FALSE,
  plan            ENUM('free','premium') DEFAULT 'free',
  plan_renewal_at DATETIME,
  photo_url       VARCHAR(500),
  locale          CHAR(5)        DEFAULT 'es',            -- 'es', 'en'
  theme           ENUM('light','dark','system') DEFAULT 'system',
  last_login_at   DATETIME,
  is_active       BOOLEAN        DEFAULT TRUE,
  created_at      DATETIME       DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME       DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_firebase_uid (firebase_uid),
  INDEX idx_tenant_id (tenant_id)
);

-- ── Viajes ───────────────────────────────────────────────────────────────
CREATE TABLE trips (
  id           CHAR(36)    PRIMARY KEY DEFAULT (UUID()),
  user_id      CHAR(36)    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name         VARCHAR(80) NOT NULL,
  destination  VARCHAR(100) NOT NULL,
  start_date   DATE        NOT NULL,
  end_date     DATE        NOT NULL,
  trip_type    ENUM('beach','mountain','city','business','adventure','other') DEFAULT 'city',
  transport    JSON        DEFAULT '[]',   -- ["plane","train"]
  activities   JSON        DEFAULT '[]',   -- ["turismo","gastronomía"]
  progress     TINYINT UNSIGNED DEFAULT 0, -- 0-100
  notes        TEXT,
  is_deleted   BOOLEAN     DEFAULT FALSE,  -- soft delete
  created_at   DATETIME    DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT chk_dates CHECK (end_date >= start_date),
  INDEX idx_user_id (user_id),
  INDEX idx_start_date (start_date),
  INDEX idx_user_dates (user_id, start_date, end_date)
);

-- ── Listas de equipaje ───────────────────────────────────────────────────
CREATE TABLE packing_lists (
  id         CHAR(36)    PRIMARY KEY DEFAULT (UUID()),
  user_id    CHAR(36)    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  trip_id    CHAR(36)    REFERENCES trips(id) ON DELETE SET NULL,  -- NULL = lista standalone
  name       VARCHAR(80) NOT NULL,
  is_deleted BOOLEAN     DEFAULT FALSE,
  created_at DATETIME    DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_trip_id (trip_id)
);

-- ── Items de equipaje ────────────────────────────────────────────────────
CREATE TABLE packing_items (
  id               CHAR(36)    PRIMARY KEY DEFAULT (UUID()),
  list_id          CHAR(36)    NOT NULL REFERENCES packing_lists(id) ON DELETE CASCADE,
  name             VARCHAR(80) NOT NULL,
  category         ENUM('clothing','electronics','documents','hygiene',
                        'medicine','food','accessories','sports','other') DEFAULT 'other',
  is_packed        BOOLEAN     DEFAULT FALSE,
  is_auto_generated BOOLEAN    DEFAULT FALSE,
  quantity         TINYINT UNSIGNED DEFAULT 1,
  sort_order       SMALLINT UNSIGNED DEFAULT 0,
  notes            TEXT,
  created_at       DATETIME    DEFAULT CURRENT_TIMESTAMP,
  updated_at       DATETIME    DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_list_id (list_id),
  INDEX idx_list_order (list_id, sort_order)
);

-- ── Chats ────────────────────────────────────────────────────────────────
CREATE TABLE chats (
  id              CHAR(36)    PRIMARY KEY DEFAULT (UUID()),
  type            ENUM('private','group') NOT NULL,
  name            VARCHAR(100) NOT NULL,
  photo_url       VARCHAR(500),
  created_by      CHAR(36)    REFERENCES users(id) ON DELETE SET NULL,
  last_message    TEXT,
  last_message_at DATETIME,
  last_sender_id  CHAR(36)    REFERENCES users(id) ON DELETE SET NULL,
  is_active       BOOLEAN     DEFAULT TRUE,
  created_at      DATETIME    DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_last_message_at (last_message_at)
);

CREATE TABLE chat_members (
  chat_id  CHAR(36) NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  user_id  CHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  is_admin  BOOLEAN  DEFAULT FALSE,
  PRIMARY KEY (chat_id, user_id),
  INDEX idx_user_id (user_id)
);

-- ── Mensajes ─────────────────────────────────────────────────────────────
CREATE TABLE messages (
  id          CHAR(36)    PRIMARY KEY DEFAULT (UUID()),
  chat_id     CHAR(36)    NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
  sender_id   CHAR(36)    NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  text        TEXT        NOT NULL,
  is_deleted  BOOLEAN     DEFAULT FALSE,
  sent_at     DATETIME    DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_chat_sent (chat_id, sent_at),
  INDEX idx_sender (sender_id)
);

CREATE TABLE message_reads (
  message_id CHAR(36) NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id    CHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  read_at    DATETIME DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (message_id, user_id)
);

-- ── Sesiones de dispositivos ──────────────────────────────────────────────
CREATE TABLE user_devices (
  id          CHAR(36)     PRIMARY KEY DEFAULT (UUID()),
  user_id     CHAR(36)     NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  fcm_token   VARCHAR(500) UNIQUE,           -- Firebase Cloud Messaging token
  device_type ENUM('android','ios','web') NOT NULL,
  device_name VARCHAR(100),
  app_version VARCHAR(20),
  last_active DATETIME,
  created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_fcm_token (fcm_token)
);

-- ── Log de eventos de app (analytics básico) ──────────────────────────────
CREATE TABLE app_events (
  id         BIGINT   AUTO_INCREMENT PRIMARY KEY,
  user_id    CHAR(36) REFERENCES users(id) ON DELETE SET NULL,
  event_name VARCHAR(100) NOT NULL,   -- 'trip_created', 'item_packed', 'premium_viewed'
  payload    JSON,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_user_id (user_id),
  INDEX idx_event_name (event_name),
  INDEX idx_created_at (created_at)
);
```

---

## PARTE 3 — VISTAS ÚTILES

```sql
USE travelready_app;

-- Vista: progreso de cada lista de equipaje
CREATE OR REPLACE VIEW v_packing_progress AS
SELECT
  pl.id         AS list_id,
  pl.name       AS list_name,
  pl.user_id,
  pl.trip_id,
  COUNT(pi.id)  AS total_items,
  SUM(pi.is_packed) AS packed_items,
  ROUND(SUM(pi.is_packed) / NULLIF(COUNT(pi.id), 0) * 100, 0) AS progress_pct
FROM packing_lists pl
LEFT JOIN packing_items pi ON pi.list_id = pl.id
WHERE pl.is_deleted = FALSE
GROUP BY pl.id, pl.name, pl.user_id, pl.trip_id;

-- Vista: próximos viajes de un usuario
CREATE OR REPLACE VIEW v_upcoming_trips AS
SELECT
  t.*,
  DATEDIFF(t.start_date, CURDATE()) AS days_until_start,
  DATEDIFF(t.end_date, t.start_date) + 1 AS duration_days
FROM trips t
WHERE t.is_deleted = FALSE
  AND t.end_date >= CURDATE()
ORDER BY t.start_date ASC;

-- Vista: stats de usuario
CREATE OR REPLACE VIEW v_user_stats AS
SELECT
  u.id AS user_id,
  COUNT(DISTINCT t.id)  AS total_trips,
  COUNT(DISTINCT pl.id) AS total_lists,
  COUNT(pi.id)          AS total_items,
  SUM(pi.is_packed)     AS packed_items
FROM users u
LEFT JOIN trips t ON t.user_id = u.id AND t.is_deleted = FALSE
LEFT JOIN packing_lists pl ON pl.user_id = u.id AND pl.is_deleted = FALSE
LEFT JOIN packing_items pi ON pi.list_id = pl.id
GROUP BY u.id;
```

---

## PARTE 4 — ÍNDICES DE RENDIMIENTO

```sql
-- Los más importantes para la app en producción:

-- 1. Buscar viajes de un usuario ordenados por fecha
ALTER TABLE trips ADD INDEX idx_user_dates (user_id, start_date, end_date);

-- 2. Buscar items de una lista ordenados
ALTER TABLE packing_items ADD INDEX idx_list_order (list_id, sort_order);

-- 3. Mensajes de un chat ordenados cronológicamente
ALTER TABLE messages ADD INDEX idx_chat_sent (chat_id, sent_at);

-- 4. Búsqueda de usuarios por email (ya está como UNIQUE)
-- 5. Chats de un usuario (ya está en chat_members.idx_user_id)
```

---

## PARTE 5 — USUARIO DE BASE DE DATOS (seguridad)

```sql
-- Crear usuario de aplicación con permisos mínimos
CREATE USER 'travelready_app'@'localhost' IDENTIFIED BY 'contraseña_segura_aqui';
CREATE USER 'travelready_accounts'@'localhost' IDENTIFIED BY 'contraseña_segura_aqui2';

-- Permisos solo en sus BDs
GRANT SELECT, INSERT, UPDATE, DELETE ON travelready_app.* TO 'travelready_app'@'localhost';
GRANT SELECT, INSERT, UPDATE ON travelready_accounts.* TO 'travelready_accounts'@'localhost';

-- El usuario de app NO puede DROP ni ALTER (solo el admin lo hace)
FLUSH PRIVILEGES;
```

---

## PARTE 6 — CONFIGURACIÓN MARIADB EN EC2 (AWS Academy)

```bash
# Instalar MariaDB en Ubuntu 24.04
sudo apt update && sudo apt install -y mariadb-server mariadb-client

# Configuración de seguridad inicial
sudo mysql_secure_installation

# Configurar para producción (/etc/mysql/mariadb.conf.d/50-server.cnf)
# bind-address = 127.0.0.1    # Solo localhost (no exponer al exterior)
# max_connections = 100
# innodb_buffer_pool_size = 256M  # Para t2.micro con 1GB RAM
# character-set-server = utf8mb4
# collation-server = utf8mb4_unicode_ci

# Reiniciar
sudo systemctl restart mariadb
sudo systemctl enable mariadb

# Verificar estado
sudo systemctl status mariadb

# Conectar
sudo mysql -u root -p
```

---

## PARTE 7 — CUÁNDO USAR MARIADB vs FIRESTORE

| Aspecto | Firebase Firestore | MariaDB |
|---------|-------------------|---------|
| Integración Flutter | Nativa, directa | Necesita API REST propia |
| Real-time | ✅ streams nativos | ❌ polling o websockets |
| Offline | ✅ nativo | ❌ manual |
| Escalabilidad | ✅ automática | Manual (replica, sharding) |
| Coste actual | Gratis (Spark) | $0 en EC2 free tier |
| Consultas complejas | Limitadas | Full SQL |
| Para TravelReady | **RECOMENDADO** | Solo si se justifica el backend |

**Recomendación**: usar Firestore para la app y conservar este documento
como diseño de BD relacional alternativo para un futuro backend propio.

---

## PARTE 8 — CONEXIÓN FLUTTER ↔ MARIADB (si se implementara)

Si se decide crear un backend REST (Node.js en EC2):

```javascript
// backend/src/db.js
const mariadb = require('mariadb');

const pool = mariadb.createPool({
  host:     process.env.DB_HOST || '127.0.0.1',
  port:     3306,
  user:     process.env.DB_USER || 'travelready_app',
  password: process.env.DB_PASS,
  database: 'travelready_app',
  connectionLimit: 10,
  charset:  'utf8mb4',
});

module.exports = pool;
```

```javascript
// backend/src/routes/trips.js
router.get('/trips', authenticate, async (req, res) => {
  const conn = await pool.getConnection();
  try {
    const trips = await conn.query(
      'SELECT * FROM trips WHERE user_id = ? AND is_deleted = FALSE ORDER BY start_date',
      [req.user.id]
    );
    res.json(trips);
  } finally {
    conn.release();
  }
});
```

En Flutter, se usaría `dio` para llamar a esta API:
```dart
// data/datasources/remote/trips_api_datasource.dart
final response = await _dio.get('/trips',
  options: Options(headers: {'Authorization': 'Bearer $token'}));
```

---

*Generado: Abril 2026 | TravelReady — Pablo Buendicho Ortín*
