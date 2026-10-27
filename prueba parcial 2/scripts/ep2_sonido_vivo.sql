-- ============================================================
-- BDY1103 - Evaluación Parcial 2 - Caso Sonido Vivo
-- Script de trabajo. Ejecutar con F5 (Run Script) en SQL Developer
-- ============================================================

-- FASE 1: esquema y datos (copiado de parcial_1.sql, líneas 1-245)
SET FEEDBACK ON;
SET DEFINE OFF;

-- Elimina tablas y secuencias si ya existen, para poder correr el script de nuevo sin errores
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

-- Creacion de tablas (modelo de datos)
CREATE TABLE CATEGORIA (
    id_categoria     NUMBER(4)     NOT NULL,
    nombre_categoria VARCHAR2(50)  NOT NULL,
    descripcion      VARCHAR2(200),
    CONSTRAINT pk_categoria PRIMARY KEY (id_categoria),
    CONSTRAINT un_cat_nombre UNIQUE (nombre_categoria)
);

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

CREATE TABLE LOG_ERRORES (
    id_log         NUMBER(8)      NOT NULL,
    codigo_error   VARCHAR2(50)   NOT NULL,
    mensaje_error  VARCHAR2(400)  NOT NULL,
    modulo_origen  VARCHAR2(100)  NOT NULL,
    usuario_bd     VARCHAR2(50)   DEFAULT USER NOT NULL,
    fecha_registro DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_log_errores PRIMARY KEY (id_log)
);

-- Secuencias (generan los ID de forma atomica)
CREATE SEQUENCE SEQ_LOG_ERRORES START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_LIQUIDACION_CLIENTE START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- Carga de datos iniciales (categorias, productos, clientes, ventas de prueba)
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (1, 'Guitarras Acústicas', 'Guitarras folk, clásicas y electroacústicas');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (2, 'Guitarras Eléctricas', 'Modelos Stratocaster, Telecaster y Les Paul');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (3, 'Bajos Eléctricos', 'Bajos activos y pasivos de 4 y 5 cuerdas');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (4, 'Teclados y Pianos', 'Pianos digitales y sintetizadores');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (5, 'Audio Profesional', 'Micrófonos, monitores e interfaces');
INSERT INTO CATEGORIA (id_categoria, nombre_categoria, descripcion) VALUES (6, 'Accesorios', 'Cuerdas, baquetas, fundas y cables');

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

INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1001, 5001, TO_DATE('01/09/2026', 'DD/MM/YYYY'), 1, 864980, 0, 864980, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (1, 1001, 103, 1, 749990, 749990);

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (2, 1001, 107, 1, 114990, 114990);

INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1002, 5002, TO_DATE('05/09/2026', 'DD/MM/YYYY'), 1, 26970, 0, 26970, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (3, 1002, 109, 3, 8990, 26970);

INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1003, 5003, TO_DATE('03/09/2026', 'DD/MM/YYYY'), 2, 459990, 0, 459990, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (4, 1003, 106, 1, 459990, 459990);

INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1004, 5004, TO_DATE('06/09/2026', 'DD/MM/YYYY'), 3, 155970, 0, 155970, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (5, 1004, 101, 1, 129990, 129990);

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (6, 1004, 110, 2, 12990, 25980);

INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
VALUES (1005, 5005, TO_DATE('08/09/2026', 'DD/MM/YYYY'), 4, 999980, 0, 999980, 'PENDIENTE');

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (7, 1005, 105, 1, 799990, 799990);

INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
VALUES (8, 1005, 108, 1, 199990, 199990);

COMMIT;

PROMPT ===================================================;
PROMPT TABLAS Y REGISTROS CREADOS CON ÉXITO:;
SELECT 'CATEGORIAS: ' || COUNT(*) FROM CATEGORIA;
SELECT 'PRODUCTOS:  ' || COUNT(*) FROM PRODUCTO;
SELECT 'CLIENTES:   ' || COUNT(*) FROM CLIENTE;
SELECT 'VENTAS:     ' || COUNT(*) FROM VENTA;
SELECT 'DETALLES:   ' || COUNT(*) FROM DETALLE_VENTA;
PROMPT ===================================================;

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ============================================================
-- OBJETOS NUEVOS DE LA EP2
-- ============================================================

-- Limpieza para poder re-ejecutar el script completo
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_VENTA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_DETALLE'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_BOLETA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_AUDITORIA'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE AUDITORIA_OPERACION CASCADE CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Secuencias nuevas: empiezan despues de los datos de prueba (ventas 1001-1005, boletas 5001-5005, detalles 1-8)
CREATE SEQUENCE SEQ_VENTA     START WITH 1006 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_DETALLE   START WITH 9    INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_BOLETA    START WITH 5006 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE SEQ_AUDITORIA START WITH 1    INCREMENT BY 1 NOCACHE NOCYCLE;

-- Tabla para el trigger de sentencia (registra cada operacion sobre VENTA)
CREATE TABLE AUDITORIA_OPERACION (
    id_auditoria    NUMBER(8)    NOT NULL,
    tabla_afectada  VARCHAR2(30) NOT NULL,
    operacion       VARCHAR2(10) NOT NULL,
    usuario_bd      VARCHAR2(50) DEFAULT USER NOT NULL,
    fecha_operacion DATE         DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_auditoria_op PRIMARY KEY (id_auditoria)
);

-- ============================================================
-- FASE 2: FUNCIONES
-- ============================================================

-- Funcion CON parametros: devuelve la tasa de descuento (en %) segun el total y el tipo de cliente.
-- Misma regla de la EP1: <200.000 -> 0 ; 200.000 a 700.000 -> 5 ; >700.000 -> 10 ; PREMIUM suma 2 puntos.
CREATE OR REPLACE FUNCTION FN_CALCULAR_DESCUENTO (
    p_total_bruto  IN NUMBER,
    p_tipo_cliente IN CLIENTE.tipo_cliente%TYPE
) RETURN NUMBER
IS
    v_tasa NUMBER(5,2);
BEGIN
    IF p_total_bruto < 200000 THEN
        v_tasa := 0;
    ELSIF p_total_bruto <= 700000 THEN
        v_tasa := 5;
    ELSE
        v_tasa := 10;
    END IF;

    IF p_tipo_cliente = 'PREMIUM' THEN
        v_tasa := v_tasa + 2;
    END IF;

    RETURN v_tasa;
END FN_CALCULAR_DESCUENTO;
/

-- Funcion SIN parametros: monto total de todas las ventas en estado PENDIENTE.
CREATE OR REPLACE FUNCTION FN_TOTAL_PENDIENTE
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT NVL(SUM(total), 0)
    INTO v_total
    FROM VENTA
    WHERE estado_venta = 'PENDIENTE';

    RETURN v_total;
END FN_TOTAL_PENDIENTE;
/

-- ============================================================
-- FASE 3: PROCEDIMIENTOS
-- ============================================================

-- Procedimiento SIN parametros: liquida a todos los clientes con ventas PENDIENTE (reemplaza el bloque 1 de la EP1).
CREATE OR REPLACE PROCEDURE SP_LIQUIDAR_CLIENTES
IS
    v_tasa      NUMBER(5,2);
    v_descuento NUMBER(10);
    v_contador  NUMBER(8) := 0;
BEGIN
    DELETE FROM LIQUIDACION_CLIENTE;

    FOR reg IN (
        SELECT c.id_cliente,
               c.nombres || ' ' || c.apellidos AS nombre_completo,
               c.tipo_cliente,
               COUNT(v.id_venta)  AS cant_compras,
               SUM(v.total)       AS monto_acumulado
        FROM CLIENTE c
        JOIN VENTA v ON c.id_cliente = v.id_cliente
        WHERE v.estado_venta = 'PENDIENTE'
        GROUP BY c.id_cliente, c.nombres, c.apellidos, c.tipo_cliente
        ORDER BY c.id_cliente
    ) LOOP
        v_tasa      := FN_CALCULAR_DESCUENTO(reg.monto_acumulado, reg.tipo_cliente);
        v_descuento := ROUND(reg.monto_acumulado * (v_tasa / 100));

        INSERT INTO LIQUIDACION_CLIENTE (
            id_liquidacion, id_cliente, nombre_completo, total_bruto,
            tasa_descuento_pct, monto_descuento, total_neto,
            cantidad_compras, fecha_liquidacion, observacion
        ) VALUES (
            SEQ_LIQUIDACION_CLIENTE.NEXTVAL, reg.id_cliente, reg.nombre_completo, reg.monto_acumulado,
            v_tasa, v_descuento, reg.monto_acumulado - v_descuento,
            reg.cant_compras, SYSDATE, 'Generada por SP_LIQUIDAR_CLIENTES'
        );

        DBMS_OUTPUT.PUT_LINE(reg.nombre_completo || ' | bruto: ' || reg.monto_acumulado
                             || ' | tasa: ' || v_tasa || '% | neto: ' || (reg.monto_acumulado - v_descuento));
        v_contador := v_contador + 1;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Clientes liquidados: ' || v_contador);
END SP_LIQUIDAR_CLIENTES;
/

-- Procedimiento CON parametros: registra una venta de 1 producto (reemplaza el bloque 3 de la EP1).
-- El stock lo descuenta el trigger TRG_DESCUENTA_STOCK; si no alcanza, el trigger lanza el error -20001.
CREATE OR REPLACE PROCEDURE SP_REGISTRAR_VENTA (
    p_id_cliente      IN CLIENTE.id_cliente%TYPE,
    p_codigo_producto IN PRODUCTO.codigo%TYPE,
    p_cantidad        IN NUMBER
)
IS
    v_id_cliente  CLIENTE.id_cliente%TYPE;
    v_id_producto PRODUCTO.id_producto%TYPE;
    v_precio      PRODUCTO.precio%TYPE;
    v_id_venta    VENTA.id_venta%TYPE;
    v_total       NUMBER(10);
    v_paso        VARCHAR2(30);

    e_cantidad_invalida EXCEPTION;
    e_sin_stock         EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_sin_stock, -20001);

    -- Subprograma local: guarda el error en LOG_ERRORES
    PROCEDURE registrar_error (p_codigo IN VARCHAR2, p_mensaje IN VARCHAR2) IS
    BEGIN
        ROLLBACK;
        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen)
        VALUES (SEQ_LOG_ERRORES.NEXTVAL, SUBSTR(p_codigo, 1, 50), SUBSTR(p_mensaje, 1, 400), 'SP_REGISTRAR_VENTA');
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('ERROR [' || p_codigo || ']: ' || p_mensaje);
    END registrar_error;
BEGIN
    IF p_cantidad IS NULL OR p_cantidad <= 0 THEN
        RAISE e_cantidad_invalida;
    END IF;

    v_paso := 'CLIENTE';
    SELECT id_cliente INTO v_id_cliente
    FROM CLIENTE
    WHERE id_cliente = p_id_cliente;

    v_paso := 'PRODUCTO';
    SELECT id_producto, precio INTO v_id_producto, v_precio
    FROM PRODUCTO
    WHERE codigo = p_codigo_producto;

    v_total    := v_precio * p_cantidad;
    v_id_venta := SEQ_VENTA.NEXTVAL;

    INSERT INTO VENTA (id_venta, nro_boleta, fecha_venta, id_cliente, subtotal, descuento, total, estado_venta)
    VALUES (v_id_venta, SEQ_BOLETA.NEXTVAL, SYSDATE, v_id_cliente, v_total, 0, v_total, 'PENDIENTE');

    INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal_linea)
    VALUES (SEQ_DETALLE.NEXTVAL, v_id_venta, v_id_producto, p_cantidad, v_precio, v_total);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Venta ' || v_id_venta || ' registrada. Total: ' || v_total);
EXCEPTION
    WHEN e_cantidad_invalida THEN
        registrar_error('CANTIDAD_INVALIDA', 'La cantidad debe ser mayor que cero. Recibida: ' || NVL(TO_CHAR(p_cantidad), 'NULL'));
    WHEN NO_DATA_FOUND THEN
        registrar_error('NO_DATA_FOUND', 'No existe el ' || LOWER(v_paso) || ' indicado.');
    WHEN e_sin_stock THEN
        registrar_error('STOCK_INSUFICIENTE', SQLERRM);
    WHEN OTHERS THEN
        registrar_error('ERROR_' || SQLCODE, SQLERRM);
END SP_REGISTRAR_VENTA;
/

-- ============================================================
-- FASE 4: PACKAGE
-- ============================================================

-- ESPECIFICACION: todo lo que se declara aqui es PUBLICO
CREATE OR REPLACE PACKAGE PKG_SONIDO_VIVO IS
    c_nombre_tienda CONSTANT VARCHAR2(30) := 'Sonido Vivo';

    FUNCTION fn_stock_producto (p_codigo IN PRODUCTO.codigo%TYPE) RETURN NUMBER;
    PROCEDURE sp_reponer_stock (p_codigo IN PRODUCTO.codigo%TYPE, p_cantidad IN NUMBER);
    PROCEDURE sp_resumen_cliente (p_id_cliente IN CLIENTE.id_cliente%TYPE);
    PROCEDURE sp_mostrar_criticos;
END PKG_SONIDO_VIVO;
/

-- BODY: lo que esta aqui y NO esta en la especificacion es PRIVADO
CREATE OR REPLACE PACKAGE BODY PKG_SONIDO_VIVO IS

    -- PRIVADO: maximo de unidades por reposicion
    c_max_reposicion CONSTANT NUMBER := 100;

    -- PRIVADO: registra errores en LOG_ERRORES en una transaccion aparte
    PROCEDURE sp_registrar_log (p_modulo IN VARCHAR2, p_codigo IN VARCHAR2, p_mensaje IN VARCHAR2) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen)
        VALUES (SEQ_LOG_ERRORES.NEXTVAL, SUBSTR(p_codigo, 1, 50), SUBSTR(p_mensaje, 1, 400), p_modulo);
        COMMIT;
    END sp_registrar_log;

    -- PRIVADO: indica si existe un producto con ese codigo
    FUNCTION fn_existe_producto (p_codigo IN PRODUCTO.codigo%TYPE) RETURN BOOLEAN IS
        v_cuenta NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_cuenta FROM PRODUCTO WHERE codigo = p_codigo;
        RETURN v_cuenta > 0;
    END fn_existe_producto;

    -- PUBLICO
    FUNCTION fn_stock_producto (p_codigo IN PRODUCTO.codigo%TYPE) RETURN NUMBER IS
        v_stock PRODUCTO.stock%TYPE;
    BEGIN
        SELECT stock INTO v_stock FROM PRODUCTO WHERE codigo = p_codigo;
        RETURN v_stock;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END fn_stock_producto;

    -- PUBLICO
    PROCEDURE sp_reponer_stock (p_codigo IN PRODUCTO.codigo%TYPE, p_cantidad IN NUMBER) IS
    BEGIN
        IF p_cantidad IS NULL OR p_cantidad <= 0 OR p_cantidad > c_max_reposicion THEN
            sp_registrar_log('PKG_SONIDO_VIVO.SP_REPONER_STOCK', 'CANTIDAD_INVALIDA',
                             'Cantidad fuera de rango (1 a ' || c_max_reposicion || '): ' || NVL(TO_CHAR(p_cantidad), 'NULL'));
            DBMS_OUTPUT.PUT_LINE('ERROR: la cantidad debe estar entre 1 y ' || c_max_reposicion);
            RETURN;
        END IF;

        IF NOT fn_existe_producto(p_codigo) THEN
            sp_registrar_log('PKG_SONIDO_VIVO.SP_REPONER_STOCK', 'NO_DATA_FOUND', 'No existe el producto ' || p_codigo);
            DBMS_OUTPUT.PUT_LINE('ERROR: no existe el producto ' || p_codigo);
            RETURN;
        END IF;

        UPDATE PRODUCTO SET stock = stock + p_cantidad WHERE codigo = p_codigo;
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Stock de ' || p_codigo || ' repuesto. Nuevo stock: ' || fn_stock_producto(p_codigo));
    END sp_reponer_stock;

    -- PUBLICO
    PROCEDURE sp_resumen_cliente (p_id_cliente IN CLIENTE.id_cliente%TYPE) IS
        v_nombre CLIENTE.nombres%TYPE;
        v_tipo   CLIENTE.tipo_cliente%TYPE;
        v_total  NUMBER;
        v_cant   NUMBER;
        v_tasa   NUMBER;
    BEGIN
        SELECT nombres || ' ' || apellidos, tipo_cliente
        INTO v_nombre, v_tipo
        FROM CLIENTE
        WHERE id_cliente = p_id_cliente;

        SELECT NVL(SUM(total), 0), COUNT(*)
        INTO v_total, v_cant
        FROM VENTA
        WHERE id_cliente = p_id_cliente AND estado_venta = 'PENDIENTE';

        v_tasa := FN_CALCULAR_DESCUENTO(v_total, v_tipo);

        DBMS_OUTPUT.PUT_LINE(c_nombre_tienda || ' | ' || v_nombre || ' (' || v_tipo || ')');
        DBMS_OUTPUT.PUT_LINE('Compras pendientes: ' || v_cant || ' | total: ' || v_total || ' | descuento: ' || v_tasa || '%');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            sp_registrar_log('PKG_SONIDO_VIVO.SP_RESUMEN_CLIENTE', 'NO_DATA_FOUND', 'No existe el cliente ' || p_id_cliente);
            DBMS_OUTPUT.PUT_LINE('ERROR: no existe el cliente ' || p_id_cliente);
    END sp_resumen_cliente;

    -- PUBLICO (sin parametros)
    PROCEDURE sp_mostrar_criticos IS
    BEGIN
        FOR reg IN (SELECT codigo, nombre, stock, stock_critico
                    FROM PRODUCTO
                    WHERE stock <= stock_critico
                    ORDER BY codigo) LOOP
            DBMS_OUTPUT.PUT_LINE(reg.codigo || ' | ' || reg.nombre || ' | stock: ' || reg.stock || ' (critico: ' || reg.stock_critico || ')');
        END LOOP;
    END sp_mostrar_criticos;

END PKG_SONIDO_VIVO;
/

-- ============================================================
-- FASE 5: TRIGGERS
-- ============================================================

-- Trigger de FILA: se ejecuta una vez por cada fila insertada en DETALLE_VENTA.
-- Valida el stock y lo descuenta. Es el UNICO lugar que descuenta stock.
CREATE OR REPLACE TRIGGER TRG_DESCUENTA_STOCK
BEFORE INSERT ON DETALLE_VENTA
FOR EACH ROW
DECLARE
    v_stock PRODUCTO.stock%TYPE;
BEGIN
    SELECT stock INTO v_stock
    FROM PRODUCTO
    WHERE id_producto = :NEW.id_producto
    FOR UPDATE;

    IF v_stock < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(-20001, 'Stock insuficiente: hay ' || v_stock || ' y se piden ' || :NEW.cantidad);
    END IF;

    UPDATE PRODUCTO
    SET stock = stock - :NEW.cantidad
    WHERE id_producto = :NEW.id_producto;
END TRG_DESCUENTA_STOCK;
/

-- Trigger de SENTENCIA: se ejecuta UNA vez por cada INSERT, UPDATE o DELETE sobre VENTA,
-- sin importar cuantas filas afecte.
CREATE OR REPLACE TRIGGER TRG_AUDITA_VENTA
AFTER INSERT OR UPDATE OR DELETE ON VENTA
DECLARE
    v_operacion VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
    ELSE
        v_operacion := 'DELETE';
    END IF;

    INSERT INTO AUDITORIA_OPERACION (id_auditoria, tabla_afectada, operacion)
    VALUES (SEQ_AUDITORIA.NEXTVAL, 'VENTA', v_operacion);
END TRG_AUDITA_VENTA;
/

-- ============================================================
-- FASE 6: PRUEBAS DE DEMOSTRACION
-- Ejecutar de una en una (seleccionar y F5) para ver cada resultado
-- ============================================================

PROMPT === Funcion con parametros (esperado: 12, 5, 0, 12) ===
SELECT FN_CALCULAR_DESCUENTO(891950, 'PREMIUM')  AS carlos,
       FN_CALCULAR_DESCUENTO(459990, 'FRECUENTE') AS valentina,
       FN_CALCULAR_DESCUENTO(155970, 'ESTANDAR')  AS matias,
       FN_CALCULAR_DESCUENTO(999980, 'PREMIUM')   AS camila
FROM DUAL;

PROMPT === Funcion sin parametros (esperado: 2507890, suma de las 5 ventas pendientes) ===
SELECT FN_TOTAL_PENDIENTE AS total_pendiente FROM DUAL;

PROMPT === Procedimiento sin parametros: liquidacion ===
EXEC SP_LIQUIDAR_CLIENTES;
SELECT nombre_completo, total_bruto, tasa_descuento_pct, monto_descuento, total_neto FROM LIQUIDACION_CLIENTE ORDER BY id_cliente;

PROMPT === Procedimiento con parametros: venta correcta (Ignacio compra 2 baquetas AC002) ===
EXEC SP_REGISTRAR_VENTA(5, 'AC002', 2);
SELECT stock FROM PRODUCTO WHERE codigo = 'AC002';

PROMPT === Procedimiento con parametros: stock insuficiente (GE002 tiene 2) ===
EXEC SP_REGISTRAR_VENTA(1, 'GE002', 5);

PROMPT === Procedimiento con parametros: cantidad invalida ===
EXEC SP_REGISTRAR_VENTA(1, 'GA001', 0);

PROMPT === Package: elementos publicos ===
SELECT PKG_SONIDO_VIVO.fn_stock_producto('GA001') AS stock_ga001 FROM DUAL;
EXEC PKG_SONIDO_VIVO.sp_reponer_stock('GE002', 10);
EXEC PKG_SONIDO_VIVO.sp_resumen_cliente(1);
EXEC PKG_SONIDO_VIVO.sp_mostrar_criticos;

PROMPT === Package: elemento privado (debe fallar con PLS-00302) ===
EXEC PKG_SONIDO_VIVO.sp_registrar_log('X', 'Y', 'Z');

PROMPT === Trigger de sentencia: una fila por operacion sobre VENTA ===
SELECT * FROM AUDITORIA_OPERACION ORDER BY id_auditoria;

PROMPT === Errores registrados ===
SELECT id_log, codigo_error, mensaje_error, modulo_origen FROM LOG_ERRORES ORDER BY id_log;
