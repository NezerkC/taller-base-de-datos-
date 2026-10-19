-- ============================================================================
-- SCRIPT: 01_esquema_y_datos.sql
-- PROYECTO: Sonido Vivo — Tienda de Instrumentos Musicales (Viña del Mar)
-- ASIGNATURA: BDY1103 - Taller de Base de Datos (Evaluación Parcial N° 1)
-- MOTOR: Oracle Database 19c / 21c / Express Edition / SQL Developer
-- DESCRIPCIÓN: Creación del esquema relacional (DDL) y carga inicial (DML)
-- ============================================================================

SET FEEDBACK ON;
SET DEFINE OFF;

-- ----------------------------------------------------------------------------
-- 1. LIMPIEZA DE OBJETOS PREVIOS (ORDEN POR DEPENDENCIAS)
-- ----------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_LOG_ERRORES';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_LIQUIDACION_CLIENTE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE LOG_ERRORES CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE LIQUIDACION_CLIENTE CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DETALLE_VENTA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE VENTA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CLIENTE CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE PRODUCTO CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CATEGORIA CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ----------------------------------------------------------------------------
-- 2. CREACIÓN DE TABLAS (DDL)
-- ----------------------------------------------------------------------------

-- Tabla 2.1: CATEGORIA
CREATE TABLE CATEGORIA (
    id_categoria     NUMBER(4)     NOT NULL,
    nombre_categoria VARCHAR2(50)  NOT NULL,
    descripcion      VARCHAR2(200),
    CONSTRAINT pk_categoria PRIMARY KEY (id_categoria),
    CONSTRAINT un_cat_nombre UNIQUE (nombre_categoria)
);

-- Tabla 2.2: PRODUCTO (Catálogo de Sonido Vivo)
CREATE TABLE PRODUCTO (
    id_producto   NUMBER(6)     NOT NULL,
    codigo        VARCHAR2(10)  NOT NULL,
    nombre        VARCHAR2(100) NOT NULL,
    marca         VARCHAR2(50)  NOT NULL,
    modelo        VARCHAR2(50),
    id_categoria  NUMBER(4)     NOT NULL,
    precio        NUMBER(10)    NOT NULL,
    stock         NUMBER(6)     NOT NULL,
    stock_critico NUMBER(6)     DEFAULT 3 NOT NULL,
    CONSTRAINT pk_producto PRIMARY KEY (id_producto),
    CONSTRAINT un_prod_codigo UNIQUE (codigo),
    CONSTRAINT fk_prod_cat FOREIGN KEY (id_categoria) REFERENCES CATEGORIA (id_categoria),
    CONSTRAINT chk_prod_precio CHECK (precio > 0),
    CONSTRAINT chk_prod_stock CHECK (stock >= 0),
    CONSTRAINT chk_prod_stock_critico CHECK (stock_critico >= 0)
);

-- Tabla 2.3: CLIENTE (Clientes registrados en la tienda y plataforma)
CREATE TABLE CLIENTE (
    id_cliente   NUMBER(6)     NOT NULL,
    rut          VARCHAR2(12)  NOT NULL,
    nombres      VARCHAR2(50)  NOT NULL,
    apellidos    VARCHAR2(50)  NOT NULL,
    email        VARCHAR2(100) NOT NULL,
    telefono     VARCHAR2(20),
    comuna       VARCHAR2(50)  DEFAULT 'Viña del Mar' NOT NULL,
    tipo_cliente VARCHAR2(20)  DEFAULT 'ESTANDAR' NOT NULL,
    CONSTRAINT pk_cliente PRIMARY KEY (id_cliente),
    CONSTRAINT un_cli_rut UNIQUE (rut),
    CONSTRAINT un_cli_email UNIQUE (email),
    CONSTRAINT chk_cli_tipo CHECK (tipo_cliente IN ('ESTANDAR', 'FRECUENTE', 'PREMIUM'))
);

-- Tabla 2.4: VENTA (Cabecera de transacciones comerciales)
CREATE TABLE VENTA (
    id_venta     NUMBER(8)    NOT NULL,
    nro_boleta   NUMBER(8)    NOT NULL,
    fecha_venta  DATE         DEFAULT SYSDATE NOT NULL,
    id_cliente   NUMBER(6)    NOT NULL,
    subtotal     NUMBER(10)   DEFAULT 0 NOT NULL,
    descuento    NUMBER(10)   DEFAULT 0 NOT NULL,
    total        NUMBER(10)   DEFAULT 0 NOT NULL,
    estado_venta VARCHAR2(20) DEFAULT 'PENDIENTE' NOT NULL,
    CONSTRAINT pk_venta PRIMARY KEY (id_venta),
    CONSTRAINT un_venta_boleta UNIQUE (nro_boleta),
    CONSTRAINT fk_venta_cliente FOREIGN KEY (id_cliente) REFERENCES CLIENTE (id_cliente),
    CONSTRAINT chk_venta_totales CHECK (subtotal >= 0 AND descuento >= 0 AND total = (subtotal - descuento)),
    CONSTRAINT chk_venta_estado CHECK (estado_venta IN ('PENDIENTE', 'LIQUIDADA', 'ANULADA'))
);

-- Tabla 2.5: DETALLE_VENTA (Líneas de productos por cada orden)
CREATE TABLE DETALLE_VENTA (
    id_detalle      NUMBER(10) NOT NULL,
    id_venta        NUMBER(8)  NOT NULL,
    id_producto     NUMBER(6)  NOT NULL,
    cantidad        NUMBER(4)  NOT NULL,
    precio_unitario NUMBER(10) NOT NULL,
    subtotal_linea  NUMBER(10) NOT NULL,
    CONSTRAINT pk_detalle_venta PRIMARY KEY (id_detalle),
    CONSTRAINT fk_det_venta FOREIGN KEY (id_venta) REFERENCES VENTA (id_venta),
    CONSTRAINT fk_det_prod FOREIGN KEY (id_producto) REFERENCES PRODUCTO (id_producto),
    CONSTRAINT chk_det_cant CHECK (cantidad > 0),
    CONSTRAINT chk_det_precio CHECK (precio_unitario > 0),
    CONSTRAINT chk_det_subtotal CHECK (subtotal_linea = cantidad * precio_unitario)
);

-- Tabla 2.6: LIQUIDACION_CLIENTE (Destino de procesamiento PL/SQL con RECORD y VARRAY)
-- JUSTIFICACIÓN 3FN / SNAPSHOT: La columna 'nombre_completo' representa una desnormalización
-- intencional como 'Snapshot Histórico' (cierre contable). Esto garantiza que la liquidación
-- conserve de forma inmutable la identidad nominal del cliente al momento de liquidar,
-- desacoplándola de eventuales mutaciones posteriores en la tabla maestra CLIENTE.
CREATE TABLE LIQUIDACION_CLIENTE (
    id_liquidacion      NUMBER(8)     NOT NULL,
    id_cliente          NUMBER(6)     NOT NULL,
    nombre_completo     VARCHAR2(120) NOT NULL,
    total_bruto         NUMBER(10)    NOT NULL,
    tasa_descuento_pct  NUMBER(5,2)   NOT NULL,
    monto_descuento     NUMBER(10)    NOT NULL,
    total_neto          NUMBER(10)    NOT NULL,
    cantidad_compras    NUMBER(4)     NOT NULL,
    fecha_liquidacion   DATE          DEFAULT SYSDATE NOT NULL,
    observacion         VARCHAR2(200),
    CONSTRAINT pk_liq_cliente PRIMARY KEY (id_liquidacion),
    CONSTRAINT fk_liq_cli FOREIGN KEY (id_cliente) REFERENCES CLIENTE (id_cliente)
);

-- Tabla 2.7: LOG_ERRORES (Auditoría centralizada de excepciones Oracle y de negocio)
CREATE TABLE LOG_ERRORES (
    id_log         NUMBER(8)      NOT NULL,
    codigo_error   VARCHAR2(50)   NOT NULL,
    mensaje_error  VARCHAR2(400)  NOT NULL,
    modulo_origen  VARCHAR2(100)  NOT NULL,
    usuario_bd     VARCHAR2(50)   DEFAULT USER NOT NULL,
    fecha_registro DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_log_errores PRIMARY KEY (id_log)
);

-- ----------------------------------------------------------------------------
-- 2.8 SECUENCIAS (GENERACIÓN CONCURRENTE Y ATÓMICA DE IDENTIFICADORES)
-- ----------------------------------------------------------------------------
CREATE SEQUENCE SEQ_LOG_ERRORES START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_LIQUIDACION_CLIENTE START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- ----------------------------------------------------------------------------
-- 3. CARGA INICIAL DE DATOS (DML)
-- ----------------------------------------------------------------------------

-- Categorías
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (1, 'Guitarras Acústicas', 'Guitarras folk, clásicas y electroacústicas');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (2, 'Guitarras Eléctricas', 'Modelos Stratocaster, Telecaster y Les Paul');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (3, 'Bajos Eléctricos', 'Bajos activos y pasivos de 4 y 5 cuerdas');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (4, 'Teclados y Pianos', 'Pianos digitales y sintetizadores');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (5, 'Audio Profesional', 'Micrófonos, monitores e interfaces');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (6, 'Accesorios', 'Cuerdas, baquetas, fundas y cables');

-- Productos (Basados en el catálogo real de Sonido Vivo)
INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (101, 'GA001', 'Guitarra Acústica Folk F310', 'Yamaha', 'F310', 1, 129990, 8, 3);

INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (102, 'GA002', 'Guitarra Acústica Dreadnought CD-60S', 'Fender', 'CD-60S', 1, 189990, 5, 3);

INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (103, 'GE001', 'Guitarra Eléctrica Player Stratocaster', 'Fender', 'Player HSS', 2, 749990, 4, 2);

INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (104, 'GE002', 'Guitarra Eléctrica Les Paul Tribute', 'Gibson', 'Tribute Satin', 2, 1199990, 2, 1);

INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (105, 'BA001', 'Bajo Eléctrico Player Precision Bass', 'Fender', 'P-Bass 4C', 3, 799990, 3, 2);

INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (106, 'TE001', 'Piano Digital P-45B 88 Teclas', 'Yamaha', 'P-45B', 4, 459990, 6, 2);

INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (107, 'AP001', 'Micrófono Dinámico Vocal SM58', 'Shure', 'SM58-LC', 5, 114990, 12, 4);

INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (108, 'AP002', 'Interfaz de Audio Scarlett 2i2 4th Gen', 'Focusrite', '2i2 Gen4', 5, 199990, 7, 3);

INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (109, 'AC001', 'Cuerdas Guitarra Eléctrica 010-046', 'Ernie Ball', 'Regular Slinky', 6, 8990, 35, 10);

INSERT INTO PRODUCTO (id_producto, codigo, nombre, marca, modelo, id_categoria, precio, stock, stock_critico)
VALUES (110, 'AC002', 'Baquetas American Classic 5A Madera', 'Vic Firth', '5A', 6, 12990, 20, 5);

-- Clientes (Clientes locales de Viña del Mar y alrededores)
INSERT INTO CLIENTE (id_cliente, rut, nombres, apellidos, email, telefono, comuna, tipo_cliente)
VALUES (1, '15.482.913-4', 'Carlos', 'Valenzuela Pinto', 'carlos.valenzuela@gmail.com', '+56981234567', 'Viña del Mar', 'PREMIUM');

INSERT INTO CLIENTE (id_cliente, rut, nombres, apellidos, email, telefono, comuna, tipo_cliente)
VALUES (2, '18.324.571-K', 'Valentina', 'Morales Soto', 'vale.morales@outlook.com', '+56972345678', 'Valparaíso', 'FRECUENTE');

INSERT INTO CLIENTE (id_cliente, rut, nombres, apellidos, email, telefono, comuna, tipo_cliente)
VALUES (3, '19.874.120-2', 'Matías', 'Lagos Herrera', 'matias.lagos@gmail.com', '+56963456789', 'Concón', 'ESTANDAR');

INSERT INTO CLIENTE (id_cliente, rut, nombres, apellidos, email, telefono, comuna, tipo_cliente)
VALUES (4, '14.102.345-8', 'Camila', 'Rojas Benítez', 'camila.rojas@vtr.net', '+56954567890', 'Quilpué', 'PREMIUM');

INSERT INTO CLIENTE (id_cliente, rut, nombres, apellidos, email, telefono, comuna, tipo_cliente)
VALUES (5, '20.145.892-1', 'Ignacio', 'Garrido Ruiz', 'ignacio.garrido@gmail.com', '+56945678901', 'Viña del Mar', 'ESTANDAR');

-- Ventas Históricas y Pendientes
-- Venta 1001 (Cliente 1: Carlos Valenzuela - Premium)
INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1001, 5001, TO_DATE('01/09/2026', 'DD/MM/YYYY'), 1, 864980, 0, 864980, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (1, 1001, 103, 1, 749990, 749990); -- Stratocaster

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (2, 1001, 107, 1, 114990, 114990); -- Shure SM58

-- Venta 1002 (Cliente 1: Segunda compra de Carlos)
INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1002, 5002, TO_DATE('05/09/2026', 'DD/MM/YYYY'), 1, 26970, 0, 26970, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (3, 1002, 109, 3, 8990, 26970); -- 3 packs cuerdas

-- Venta 1003 (Cliente 2: Valentina Morales - Frecuente)
INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1003, 5003, TO_DATE('03/09/2026', 'DD/MM/YYYY'), 2, 459990, 0, 459990, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (4, 1003, 106, 1, 459990, 459990); -- Piano Digital P-45

-- Venta 1004 (Cliente 3: Matías Lagos - Estándar)
INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1004, 5004, TO_DATE('06/09/2026', 'DD/MM/YYYY'), 3, 155970, 0, 155970, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (5, 1004, 101, 1, 129990, 129990); -- Acústica Yamaha F310

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (6, 1004, 110, 2, 12990, 25980);   -- 2 pares baquetas

-- Venta 1005 (Cliente 4: Camila Rojas - Premium)
INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1005, 5005, TO_DATE('08/09/2026', 'DD/MM/YYYY'), 4, 999980, 0, 999980, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (7, 1005, 105, 1, 799990, 799990); -- Bajo Precision

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (8, 1005, 108, 1, 199990, 199990); -- Focusrite Scarlett

COMMIT;

-- Verificación de registros creados
PROMPT ===================================================;
PROMPT TABLAS Y REGISTROS CREADOS CON ÉXITO:;
SELECT 'CATEGORIAS: ' || COUNT(*) FROM CATEGORIA;
SELECT 'PRODUCTOS:  ' || COUNT(*) FROM PRODUCTO;
SELECT 'CLIENTES:   ' || COUNT(*) FROM CLIENTE;
SELECT 'VENTAS:     ' || COUNT(*) FROM VENTA;
SELECT 'DETALLES:   ' || COUNT(*) FROM DETALLE_VENTA;
PROMPT ===================================================;
