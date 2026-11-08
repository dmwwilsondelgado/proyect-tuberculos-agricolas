BEGIN;
-- ---------------------------------------------------------------------
-- 0. TIPOS ENUM Y FUNCIONES
-- ---------------------------------------------------------------------
CREATE TYPE rol_usuario AS ENUM ('cliente', 'admin');

CREATE TYPE estado_pedido AS ENUM (
  'pendiente_pago',   -- creado, esperando que el cliente pague
  'pendiente',        -- pago reportado, en revisión
  'confirmado',       -- pago verificado por el admin
  'en_preparacion',
  'enviado',
  'entregado',
  'cancelado'
);

CREATE TYPE estado_pago AS ENUM ('pendiente', 'en_revision', 'confirmado', 'rechazado');

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- 1. USUARIOS (login normal + Google)
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
  id            SERIAL PRIMARY KEY,
  nombre        VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255),                 -- NULL para usuarios de Google
  google_id     VARCHAR(100) UNIQUE,
  foto_url      VARCHAR(300),
  telefono      VARCHAR(20),
  rol           rol_usuario NOT NULL DEFAULT 'cliente',
  activo        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT chk_credencial CHECK (password_hash IS NOT NULL OR google_id IS NOT NULL)
);
CREATE TRIGGER trg_usuarios_updated BEFORE UPDATE ON usuarios
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- 2. UBICACIÓN: DEPARTAMENTOS, CIUDADES, DIRECCIONES
-- ---------------------------------------------------------------------
CREATE TABLE departamentos (
  id     SERIAL PRIMARY KEY,
  nombre VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE ciudades (
  id              SERIAL PRIMARY KEY,
  departamento_id INT NOT NULL REFERENCES departamentos(id),
  nombre          VARCHAR(100) NOT NULL,
  costo_envio     NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (costo_envio >= 0),
  hace_envios     BOOLEAN NOT NULL DEFAULT TRUE,
  UNIQUE (departamento_id, nombre)
);
CREATE INDEX idx_ciudades_departamento ON ciudades(departamento_id);

CREATE TABLE direcciones (
  id           SERIAL PRIMARY KEY,
  usuario_id   INT NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
  ciudad_id    INT NOT NULL REFERENCES ciudades(id),
  alias        VARCHAR(50),                   -- "Casa", "Trabajo"
  direccion    VARCHAR(200) NOT NULL,
  barrio       VARCHAR(100),
  referencia   VARCHAR(200),
  es_principal BOOLEAN NOT NULL DEFAULT FALSE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_direcciones_usuario ON direcciones(usuario_id);
-- Solo una dirección principal por usuario
CREATE UNIQUE INDEX uq_direccion_principal ON direcciones(usuario_id) WHERE es_principal;

-- ---------------------------------------------------------------------
-- 3. CATÁLOGO: CATEGORÍAS, TIPOS DE PRODUCTO, PRODUCTOS, IMÁGENES
-- ---------------------------------------------------------------------
CREATE TABLE categorias (
  id          SERIAL PRIMARY KEY,
  nombre      VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT,
  activa      BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE tipos_producto (
  id          SERIAL PRIMARY KEY,
  nombre      VARCHAR(50) NOT NULL UNIQUE,    -- Bulto, Kilo, Libra, Unidad
  abreviatura VARCHAR(10)
);

CREATE TABLE productos (
  id               SERIAL PRIMARY KEY,
  categoria_id     INT NOT NULL REFERENCES categorias(id),
  tipo_producto_id INT NOT NULL REFERENCES tipos_producto(id),
  nombre           VARCHAR(150) NOT NULL,
  descripcion      TEXT,
  precio           NUMERIC(12,2) NOT NULL CHECK (precio >= 0),  -- por unidad de venta
  disponible       BOOLEAN NOT NULL DEFAULT TRUE,  -- true = activo; false = agotado/pausado
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_productos_categoria  ON productos(categoria_id);
CREATE INDEX idx_productos_disponible ON productos(disponible);
CREATE TRIGGER trg_productos_updated BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE producto_imagenes (
  id           SERIAL PRIMARY KEY,
  producto_id  INT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
  url          VARCHAR(300) NOT NULL,
  es_principal BOOLEAN NOT NULL DEFAULT FALSE,
  orden        INT NOT NULL DEFAULT 0
);
CREATE INDEX idx_imagenes_producto ON producto_imagenes(producto_id);

-- ---------------------------------------------------------------------
-- 4. CARRITO
-- ---------------------------------------------------------------------
CREATE TABLE carritos (
  id         SERIAL PRIMARY KEY,
  usuario_id INT NOT NULL UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE carrito_items (
  id          SERIAL PRIMARY KEY,
  carrito_id  INT NOT NULL REFERENCES carritos(id) ON DELETE CASCADE,
  producto_id INT NOT NULL REFERENCES productos(id),
  cantidad    NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
  UNIQUE (carrito_id, producto_id)
);

-- ---------------------------------------------------------------------
-- 5. PEDIDOS
-- ---------------------------------------------------------------------
CREATE TABLE pedidos (
  id           SERIAL PRIMARY KEY,
  usuario_id   INT NOT NULL REFERENCES usuarios(id),
  direccion_id INT NOT NULL REFERENCES direcciones(id),
  estado       estado_pedido NOT NULL DEFAULT 'pendiente_pago',
  subtotal     NUMERIC(12,2) NOT NULL CHECK (subtotal >= 0),
  costo_envio  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (costo_envio >= 0),
  total        NUMERIC(12,2) NOT NULL CHECK (total >= 0),
  notas        TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_pedidos_usuario ON pedidos(usuario_id);
CREATE INDEX idx_pedidos_estado  ON pedidos(estado);
CREATE TRIGGER trg_pedidos_updated BEFORE UPDATE ON pedidos
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE pedido_items (
  id              SERIAL PRIMARY KEY,
  pedido_id       INT NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  producto_id     INT NOT NULL REFERENCES productos(id),
  nombre_producto VARCHAR(150) NOT NULL,        -- copia histórica
  precio_unitario NUMERIC(12,2) NOT NULL,       -- copia histórica
  cantidad        NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
  subtotal        NUMERIC(12,2) NOT NULL
);
CREATE INDEX idx_pedido_items_pedido ON pedido_items(pedido_id);

-- ---------------------------------------------------------------------
-- 6. PAGOS (Nequi manual con comprobante)
-- ---------------------------------------------------------------------
CREATE TABLE metodos_pago (
  id            SERIAL PRIMARY KEY,
  nombre        VARCHAR(50) NOT NULL UNIQUE,
  instrucciones TEXT,
  activo        BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE pagos (
  id              SERIAL PRIMARY KEY,
  pedido_id       INT NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  metodo_pago_id  INT NOT NULL REFERENCES metodos_pago(id),
  monto           NUMERIC(12,2) NOT NULL CHECK (monto >= 0),
  referencia      VARCHAR(100),                  -- referencia de la transacción Nequi
  comprobante_url VARCHAR(300),
  estado          estado_pago NOT NULL DEFAULT 'pendiente',
  verificado_por  INT REFERENCES usuarios(id),   -- admin que confirmó
  verificado_en   TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_pagos_pedido ON pagos(pedido_id);
CREATE INDEX idx_pagos_estado ON pagos(estado);

-- ---------------------------------------------------------------------
-- 7. DATOS SEMILLA (ejemplos para probar; ajusta a tu caso)
-- ---------------------------------------------------------------------
--INSERT INTO departamentos (nombre) VALUES ('Santander'), ('Cundinamarca'), ('Antioquia');

--INSERT INTO ciudades (departamento_id, nombre, costo_envio) VALUES
  --(1, 'Bucaramanga', 5000),
  --(2, 'Bogotá', 12000),
  --(3, 'Medellín', 12000);

--INSERT INTO categorias (nombre) VALUES ('Frutas'), ('Tubérculos'), ('Cacao y derivados');

--INSERT INTO tipos_producto (nombre, abreviatura) VALUES
  --('Bulto', 'bto'), ('Kilo', 'kg'), ('Libra', 'lb'), ('Unidad', 'und');

--INSERT INTO productos (categoria_id, tipo_producto_id, nombre, precio) VALUES
  --(1, 2, 'Naranja',        3000),
  --(3, 1, 'Cacao en bulto', 450000),
  --(2, 2, 'Yuca',           2500),
  --(3, 3, 'Chocolate',      8000);

--INSERT INTO metodos_pago (nombre, instrucciones) VALUES
  --('Nequi', 'Envía el valor exacto al número 3XX XXX XXXX y sube tu comprobante con la referencia del pedido.');

--COMMIT;
-- Para crear tu usuario admin: registra una cuenta desde la web y luego ejecuta:
-- UPDATE usuarios SET rol = 'admin' WHERE email = 'tu_correo@ejemplo.com';