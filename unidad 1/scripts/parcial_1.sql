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

DECLARE

    -- RECORD: agrupa los datos de una liquidacion de cliente en una sola variable
    TYPE t_rec_liquidacion IS RECORD (
        id_cliente          CLIENTE.id_cliente%TYPE,
        nombre_completo     VARCHAR2(120),
        tipo_cliente        CLIENTE.tipo_cliente%TYPE,
        total_bruto         NUMBER(10),
        tasa_descuento_pct  NUMBER(5,2),
        monto_descuento     NUMBER(10),
        total_neto          NUMBER(10),
        cantidad_ordenes    NUMBER(4),
        observacion         VARCHAR2(200)
    );

    -- VARRAY: escala fija de tasas de descuento guardada en memoria
    TYPE t_arr_tasas IS VARRAY(3) OF NUMBER(5,2);

    v_liquidacion       t_rec_liquidacion;
    v_escalas_descuento t_arr_tasas := t_arr_tasas(0.00, 5.00, 10.00);
    v_contador_liq      NUMBER(8) := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('           SONIDO VIVO — MOTOR DE LIQUIDACIÓN DE CLIENTES (RECORD + VARRAY)     ');
    DBMS_OUTPUT.PUT_LINE('================================================================================');

    DELETE FROM LIQUIDACION_CLIENTE;

    FOR reg_cli IN (
        SELECT c.id_cliente,
               c.nombres || ' ' || c.apellidos AS nombre_completo,
               c.tipo_cliente,
               COUNT(v.id_venta) AS cant_compras,
               NVL(SUM(v.total), 0) AS monto_acumulado
        FROM CLIENTE c
        JOIN VENTA v ON c.id_cliente = v.id_cliente
        WHERE v.estado_venta = 'PENDIENTE'
        GROUP BY c.id_cliente, c.nombres, c.apellidos, c.tipo_cliente
        ORDER BY c.id_cliente
    ) LOOP

        v_liquidacion.id_cliente       := reg_cli.id_cliente;
        v_liquidacion.nombre_completo  := reg_cli.nombre_completo;
        v_liquidacion.tipo_cliente     := reg_cli.tipo_cliente;
        v_liquidacion.total_bruto      := reg_cli.monto_acumulado;
        v_liquidacion.cantidad_ordenes := reg_cli.cant_compras;

        IF v_liquidacion.total_bruto < 200000 THEN
            v_liquidacion.tasa_descuento_pct := v_escalas_descuento(1);
            v_liquidacion.observacion        := 'Tramo Inicial: Sin descuento adicional por volumen';
        ELSIF v_liquidacion.total_bruto BETWEEN 200000 AND 700000 THEN
            v_liquidacion.tasa_descuento_pct := v_escalas_descuento(2);
            v_liquidacion.observacion        := 'Tramo Plata: 5% descuento por volumen de compra';
        ELSE
            v_liquidacion.tasa_descuento_pct := v_escalas_descuento(3);
            v_liquidacion.observacion        := 'Tramo Oro: 10% beneficio preferencial por gran volumen';
        END IF;

        IF v_liquidacion.tipo_cliente = 'PREMIUM' THEN
            v_liquidacion.tasa_descuento_pct := v_liquidacion.tasa_descuento_pct + 2.00;
            v_liquidacion.observacion        := v_liquidacion.observacion || ' (+2% fidelidad PREMIUM)';
        END IF;

        v_liquidacion.monto_descuento := ROUND(v_liquidacion.total_bruto * (v_liquidacion.tasa_descuento_pct / 100));
        v_liquidacion.total_neto      := v_liquidacion.total_bruto - v_liquidacion.monto_descuento;

        INSERT INTO LIQUIDACION_CLIENTE (
            id_liquidacion,
            id_cliente,
            nombre_completo,
            total_bruto,
            tasa_descuento_pct,
            monto_descuento,
            total_neto,
            cantidad_compras,
            fecha_liquidacion,
            observacion
        ) VALUES (
            SEQ_LIQUIDACION_CLIENTE.NEXTVAL,
            v_liquidacion.id_cliente,
            v_liquidacion.nombre_completo,
            v_liquidacion.total_bruto,
            v_liquidacion.tasa_descuento_pct,
            v_liquidacion.monto_descuento,
            v_liquidacion.total_neto,
            v_liquidacion.cantidad_ordenes,
            SYSDATE,
            v_liquidacion.observacion
        );

        DBMS_OUTPUT.PUT_LINE('Cliente: ' || RPAD(v_liquidacion.nombre_completo, 30) ||
                             ' | Bruto: $' || LPAD(TO_CHAR(v_liquidacion.total_bruto, '999G999G999'), 12) ||
                             ' | Tasa: ' || LPAD(TO_CHAR(v_liquidacion.tasa_descuento_pct, '90.00'), 6) || '%' ||
                             ' | Neto: $' || LPAD(TO_CHAR(v_liquidacion.total_neto, '999G999G999'), 12));

        v_contador_liq := v_contador_liq + 1;

    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('>> PROCESO FINALIZADO: ' || v_contador_liq || ' liquidaciones calculadas y guardadas.');
    DBMS_OUTPUT.PUT_LINE('================================================================================');

END;
/

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE

    -- Cursor sin parametros (padre): recorre los clientes con ventas
    CURSOR c_clientes IS
        SELECT c.id_cliente,
               c.rut,
               c.nombres || ' ' || c.apellidos AS cliente_nombre,
               c.comuna,
               c.tipo_cliente
        FROM CLIENTE c
        WHERE EXISTS (
            SELECT 1
            FROM VENTA v
            WHERE v.id_cliente = c.id_cliente
        )
        ORDER BY c.id_cliente;

    -- Cursor con parametro (hijo): recibe el id del cliente y trae sus ventas
    CURSOR c_ventas_cliente (p_id_cli CLIENTE.id_cliente%TYPE) IS
        SELECT v.nro_boleta,
               v.fecha_venta,
               p.codigo AS codigo_prod,
               p.nombre AS nombre_prod,
               cat.nombre_categoria,
               d.cantidad,
               d.precio_unitario,
               d.subtotal_linea
        FROM VENTA v
        JOIN DETALLE_VENTA d ON v.id_venta = d.id_venta
        JOIN PRODUCTO p      ON d.id_producto = p.id_producto
        JOIN CATEGORIA cat   ON p.id_categoria = cat.id_categoria
        WHERE v.id_cliente = p_id_cli
        ORDER BY v.nro_boleta, d.id_detalle;

    v_total_cliente       NUMBER(10);
    v_total_unidades      NUMBER(6);
    v_boleta_actual       NUMBER(8);
    v_contador_clientes   NUMBER(4) := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('     SONIDO VIVO — AUDITORÍA DETALLADA DE COMPRAS POR CLIENTE (CURSORES)        ');
    DBMS_OUTPUT.PUT_LINE('================================================================================');

    FOR reg_cli IN c_clientes LOOP
        v_contador_clientes := v_contador_clientes + 1;
        v_total_cliente     := 0;
        v_total_unidades    := 0;
        v_boleta_actual     := 0;

        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('CLIENTE [' || reg_cli.id_cliente || '] ' || UPPER(reg_cli.cliente_nombre) ||
                             ' | RUT: ' || reg_cli.rut ||
                             ' | Comuna: ' || reg_cli.comuna ||
                             ' | Categoría: ' || reg_cli.tipo_cliente);
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------------------');

        FOR reg_det IN c_ventas_cliente(reg_cli.id_cliente) LOOP

            IF v_boleta_actual <> reg_det.nro_boleta THEN
                v_boleta_actual := reg_det.nro_boleta;
                DBMS_OUTPUT.PUT_LINE('  >> Boleta N° ' || v_boleta_actual || ' (Emitida: ' || TO_CHAR(reg_det.fecha_venta, 'DD/MM/YYYY') || '):');
            END IF;

            DBMS_OUTPUT.PUT_LINE('     * [' || reg_det.codigo_prod || '] ' ||
                                 RPAD(reg_det.nombre_prod, 32) ||
                                 ' (' || RPAD(reg_det.nombre_categoria, 18) || ') ' ||
                                 ' | Cant: ' || LPAD(reg_det.cantidad, 2) ||
                                 ' x $' || LPAD(TO_CHAR(reg_det.precio_unitario, '999G999'), 9) ||
                                 ' = $' || LPAD(TO_CHAR(reg_det.subtotal_linea, '999G999'), 9));

            v_total_cliente  := v_total_cliente + reg_det.subtotal_linea;
            v_total_unidades := v_total_unidades + reg_det.cantidad;

        END LOOP;

        DBMS_OUTPUT.PUT_LINE('  --> RESUMEN CLIENTE: ' || v_total_unidades || ' unidades adquiridas | Total Acumulado: $' ||
                             TO_CHAR(v_total_cliente, '999G999G999'));

    END LOOP;

    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('>> PROCESAMIENTO COMPLETADO: ' || v_contador_clientes || ' clientes auditados con éxito.');
    DBMS_OUTPUT.PUT_LINE('================================================================================');

END;
/

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE

    -- Excepciones definidas por el usuario (reglas de negocio)
    e_stock_insuficiente    EXCEPTION;
    e_cantidad_invalida     EXCEPTION;

    v_id_cliente_solicitado  NUMBER := 1;
    v_codigo_prod_solicitado VARCHAR2(10) := 'GE002';
    v_cantidad_solicitada    NUMBER := 5;

    v_id_producto   PRODUCTO.id_producto%TYPE;
    v_nombre_prod   PRODUCTO.nombre%TYPE;
    v_precio_prod   PRODUCTO.precio%TYPE;
    v_stock_actual  PRODUCTO.stock%TYPE;
    v_stock_critico PRODUCTO.stock_critico%TYPE;
    v_rut_cliente   CLIENTE.rut%TYPE;
    v_nombre_cli    CLIENTE.nombres%TYPE;

    v_secuencia_log NUMBER(8);
    v_cod_error     VARCHAR2(50);
    v_msj_error     VARCHAR2(400);

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('     SONIDO VIVO — SIMULADOR TRANSACCIONAL CON CONTROL DE EXCEPCIONES           ');
    DBMS_OUTPUT.PUT_LINE('================================================================================');

    SELECT rut, nombres
    INTO v_rut_cliente, v_nombre_cli
    FROM CLIENTE
    WHERE id_cliente = v_id_cliente_solicitado;

    DBMS_OUTPUT.PUT_LINE('>> Cliente Verificado: ' || v_nombre_cli || ' (RUT: ' || v_rut_cliente || ')');

    IF v_cantidad_solicitada <= 0 THEN
        RAISE e_cantidad_invalida;
    END IF;

    SELECT id_producto, nombre, precio, stock, stock_critico
    INTO v_id_producto, v_nombre_prod, v_precio_prod, v_stock_actual, v_stock_critico
    FROM PRODUCTO
    WHERE codigo = v_codigo_prod_solicitado;

    DBMS_OUTPUT.PUT_LINE('>> Producto Seleccionado: ' || v_nombre_prod ||
                         ' | Stock en Bodega: ' || v_stock_actual ||
                         ' | Cantidad Pedida: ' || v_cantidad_solicitada);

    IF v_cantidad_solicitada > v_stock_actual THEN
        RAISE e_stock_insuficiente;
    END IF;

    UPDATE PRODUCTO
    SET stock = stock - v_cantidad_solicitada
    WHERE id_producto = v_id_producto;

    DBMS_OUTPUT.PUT_LINE('>> ÉXITO: Stock descontado en tabla PRODUCTO (' ||
                         v_stock_actual || ' -> ' || (v_stock_actual - v_cantidad_solicitada) ||
                         ' unidades). Venta completada satisfactoriamente.');
    COMMIT;

EXCEPTION

    -- Excepciones predefinidas de Oracle
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        v_secuencia_log := SEQ_LOG_ERRORES.NEXTVAL;
        v_cod_error := 'ORA-01403 (NO_DATA_FOUND)';
        v_msj_error := 'Error de búsqueda: El cliente ID ' || v_id_cliente_solicitado ||
                       ' o el producto código ' || v_codigo_prod_solicitado || ' no existen en el sistema.';

        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen, usuario_bd, fecha_registro)
        VALUES (v_secuencia_log, v_cod_error, v_msj_error, 'MODULO_VENTAS_CHECKOUT', USER, SYSDATE);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN ORACLE CAPTURADA]: ' || v_msj_error);
        DBMS_OUTPUT.PUT_LINE('>> Incidente auditado en LOG_ERRORES con ID: ' || v_secuencia_log);

    WHEN TOO_MANY_ROWS THEN
        ROLLBACK;
        v_secuencia_log := SEQ_LOG_ERRORES.NEXTVAL;
        v_cod_error := 'ORA-01422 (TOO_MANY_ROWS)';
        v_msj_error := 'Inconsistencia de catálogo: Se encontró más de un registro para el identificador consultado.';

        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen, usuario_bd, fecha_registro)
        VALUES (v_secuencia_log, v_cod_error, v_msj_error, 'MODULO_VENTAS_CHECKOUT', USER, SYSDATE);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN ORACLE CAPTURADA]: ' || v_msj_error);
        DBMS_OUTPUT.PUT_LINE('>> Incidente auditado en LOG_ERRORES con ID: ' || v_secuencia_log);

    -- Excepciones definidas por el usuario (manejo)
    WHEN e_stock_insuficiente THEN
        ROLLBACK;
        v_secuencia_log := SEQ_LOG_ERRORES.NEXTVAL;
        v_cod_error := 'USR-001 (STOCK_INSUFICIENTE)';
        v_msj_error := 'Operación rechazada: No es posible vender ' || v_cantidad_solicitada ||
                       ' unidades del producto ' || v_nombre_prod || '. Stock disponible: ' || v_stock_actual || '.';

        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen, usuario_bd, fecha_registro)
        VALUES (v_secuencia_log, v_cod_error, v_msj_error, 'MODULO_VENTAS_STOCK', USER, SYSDATE);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN DE NEGOCIO CAPTURADA]: ' || v_msj_error);
        DBMS_OUTPUT.PUT_LINE('>> Incidente auditado en LOG_ERRORES con ID: ' || v_secuencia_log);

    WHEN e_cantidad_invalida THEN
        ROLLBACK;
        v_secuencia_log := SEQ_LOG_ERRORES.NEXTVAL;
        v_cod_error := 'USR-002 (CANTIDAD_INVALIDA)';
        v_msj_error := 'Operación rechazada: La cantidad a comprar debe ser un entero estrictamente mayor a cero.';

        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen, usuario_bd, fecha_registro)
        VALUES (v_secuencia_log, v_cod_error, v_msj_error, 'MODULO_VENTAS_PARAMETROS', USER, SYSDATE);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN DE NEGOCIO CAPTURADA]: ' || v_msj_error);
        DBMS_OUTPUT.PUT_LINE('>> Incidente auditado en LOG_ERRORES con ID: ' || v_secuencia_log);

    WHEN OTHERS THEN
        ROLLBACK;
        v_secuencia_log := SEQ_LOG_ERRORES.NEXTVAL;
        v_cod_error := 'ORA-' || TO_CHAR(SQLCODE);
        v_msj_error := SUBSTR(SQLERRM, 1, 380);

        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen, usuario_bd, fecha_registro)
        VALUES (v_secuencia_log, v_cod_error, v_msj_error, 'MODULO_VENTAS_GENERAL', USER, SYSDATE);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[ERROR NO CONTROLADO]: ' || v_msj_error);
        DBMS_OUTPUT.PUT_LINE('>> Incidente auditado en LOG_ERRORES con ID: ' || v_secuencia_log);

END;
/
