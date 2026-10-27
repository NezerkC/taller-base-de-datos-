-- =============================================================================
-- SCRIPT: 01_paquetes_y_triggers_ep2.sql
-- PROYECTO: Sonido Vivo — Tienda de Instrumentos Musicales y Audio Profesional
-- ASIGNATURA: BDY1103 - Taller de Base de Datos (Evaluacion Parcial N° 2)
-- MOTOR: Oracle Database 19c / 21c / Express Edition / SQL Developer
-- OBJETIVO: Implementacion integral de programas PL/SQL segun Rubrica Oficial:
--   - Procedimientos con y sin parametros para procesamiento masivo.
--   - Funciones con y sin parametros invocables en PL/SQL y sentencias SQL.
--   - Packages modulares con constructores publicos y privados.
--   - Triggers asociados a tablas a nivel de fila y a nivel de sentencia.
-- =============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET FEEDBACK ON;
SET DEFINE OFF;

-- -----------------------------------------------------------------------------
-- 1. LIMPIEZA Y RECREACION DE ESTRUCTURAS DE AUDITORIA Y CONTROL
-- -----------------------------------------------------------------------------
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER TRG_VALIDA_Y_DESCUENTA_STOCK';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER TRG_AUDITA_PRECIO_PRODUCTO';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TRIGGER TRG_CONTROL_OPERACION_VENTAS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE PKG_SONIDO_VIVO';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_AUDIT_PRECIOS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_CONTROL_VENTAS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE AUDIT_PRECIOS_PRODUCTO CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE CONTROL_OPERACION_VENTAS CASCADE CONSTRAINTS';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- Tabla para auditoria reactiva de precios (gatillada por trigger de fila)
CREATE SEQUENCE SEQ_AUDIT_PRECIOS START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE AUDIT_PRECIOS_PRODUCTO (
    id_audit        NUMBER(10)     NOT NULL,
    id_producto     NUMBER(6)      NOT NULL,
    precio_anterior NUMBER(10)     NOT NULL,
    precio_nuevo    NUMBER(10)     NOT NULL,
    usuario_bd      VARCHAR2(50)   DEFAULT USER NOT NULL,
    fecha_cambio    DATE           DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_audit_precios PRIMARY KEY (id_audit),
    CONSTRAINT fk_audit_prod FOREIGN KEY (id_producto) REFERENCES PRODUCTO (id_producto)
);

-- Tabla para auditoria de eventos a nivel de sentencia (gatillada por trigger de sentencia)
CREATE SEQUENCE SEQ_CONTROL_VENTAS START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE TABLE CONTROL_OPERACION_VENTAS (
    id_operacion    NUMBER(10)     NOT NULL,
    tipo_evento     VARCHAR2(25)   NOT NULL,
    usuario_bd      VARCHAR2(50)   DEFAULT USER NOT NULL,
    fecha_evento    DATE           DEFAULT SYSDATE NOT NULL,
    total_filas_bd  NUMBER(10)     NOT NULL,
    CONSTRAINT pk_control_ventas PRIMARY KEY (id_operacion)
);

-- -----------------------------------------------------------------------------
-- 2. ESPECIFICACION DEL PAQUETE (PACKAGE SPECIFICATION) - CONSTRUCTORES PUBLICOS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_SONIDO_VIVO AS
    -- Constante de version del paquete
    c_version CONSTANT VARCHAR2(10) := '2.0.0';

    -- 2.1 Funcion CON parametros: Calcula tasa de descuento por volumen y tipo de cliente
    -- Puede ser consumida en PL/SQL y en sentencias SELECT de SQL (WNDS / WNPS)
    FUNCTION fn_calcular_descuento(
        p_total_bruto IN NUMBER,
        p_tipo_cliente IN VARCHAR2
    ) RETURN NUMBER;

    -- 2.2 Funcion SIN parametros: Retorna el umbral minimo en pesos para descuento por volumen
    -- Centraliza la regla de negocio y puede ser invocada en sentencias SQL
    FUNCTION fn_obtener_umbral_descuento RETURN NUMBER;

    -- 2.3 Procedimiento CON parametros: Reajuste porcentual de precios por categoria
    -- Retorna la cantidad de productos actualizados mediante parametro OUT
    PROCEDURE sp_reajustar_precios(
        p_porcentaje        IN NUMBER,
        p_id_categoria      IN NUMBER,
        p_filas_afectadas   OUT NUMBER
    );

    -- 2.4 Procedimiento CON parametros: Liquidacion masiva de clientes por periodo mensual
    -- Retorna el total de liquidaciones generadas en LIQUIDACION_CLIENTE
    PROCEDURE sp_liquidar_clientes(
        p_periodo           IN VARCHAR2,
        p_filas_liquidadas  OUT NUMBER
    );

    -- 2.5 Procedimiento SIN parametros: Consolidacion y auditoria preventiva de inventario critico
    PROCEDURE sp_actualizar_estadisticas_inventario;

END PKG_SONIDO_VIVO;
/

-- -----------------------------------------------------------------------------
-- 3. CUERPO DEL PAQUETE (PACKAGE BODY) - IMPLEMENTACION Y CONSTRUCTORES PRIVADOS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE BODY PKG_SONIDO_VIVO AS

    -- -------------------------------------------------------------------------
    -- CONSTRUCTOR PRIVADO: sp_registrar_log_interno
    -- Encapsulado exclusivamente en el Body. No es visible para usuarios externos.
    -- Implementa PRAGMA AUTONOMOUS_TRANSACTION para persistir logs sin alterar
    -- ni comprometer la transaccion principal ante un eventual ROLLBACK.
    -- -------------------------------------------------------------------------
    PROCEDURE sp_registrar_log_interno(
        p_modulo_origen IN VARCHAR2,
        p_codigo_error  IN VARCHAR2,
        p_mensaje_error IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO LOG_ERRORES (
            id_log, codigo_error, mensaje_error, modulo_origen, usuario_bd, fecha_registro
        ) VALUES (
            SEQ_LOG_ERRORES.NEXTVAL,
            p_codigo_error,
            SUBSTR(p_mensaje_error, 1, 400),
            p_modulo_origen,
            USER,
            SYSDATE
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
    END sp_registrar_log_interno;

    -- -------------------------------------------------------------------------
    -- IMPLEMENTACION: fn_calcular_descuento (CON PARAMETROS)
    -- Tramos de descuento:
    --   < $200.000: 0%
    --   $200.000 a $700.000: 5%
    --   > $700.000: 10%
    --   Bono especial: Clientes PREMIUM reciben un 2% adicional en cualquier tramo
    -- -------------------------------------------------------------------------
    FUNCTION fn_calcular_descuento(
        p_total_bruto  IN NUMBER,
        p_tipo_cliente IN VARCHAR2
    ) RETURN NUMBER IS
        v_pct_base NUMBER := 0;
        v_pct_bono NUMBER := 0;
    BEGIN
        IF p_total_bruto IS NULL OR p_total_bruto < 0 THEN
            RETURN 0;
        END IF;

        IF p_total_bruto < 200000 THEN
            v_pct_base := 0;
        ELSIF p_total_bruto <= 700000 THEN
            v_pct_base := 5;
        ELSE
            v_pct_base := 10;
        END IF;

        IF UPPER(TRIM(NVL(p_tipo_cliente, 'ESTANDAR'))) = 'PREMIUM' THEN
            v_pct_bono := 2;
        END IF;

        RETURN (v_pct_base + v_pct_bono);
    END fn_calcular_descuento;

    -- -------------------------------------------------------------------------
    -- IMPLEMENTACION: fn_obtener_umbral_descuento (SIN PARAMETROS)
    -- -------------------------------------------------------------------------
    FUNCTION fn_obtener_umbral_descuento RETURN NUMBER IS
    BEGIN
        RETURN 200000;
    END fn_obtener_umbral_descuento;

    -- -------------------------------------------------------------------------
    -- IMPLEMENTACION: sp_reajustar_precios (CON PARAMETROS)
    -- -------------------------------------------------------------------------
    PROCEDURE sp_reajustar_precios(
        p_porcentaje        IN NUMBER,
        p_id_categoria      IN NUMBER,
        p_filas_afectadas   OUT NUMBER
    ) IS
    BEGIN
        IF p_porcentaje IS NULL OR p_porcentaje = 0 THEN
            p_filas_afectadas := 0;
            RETURN;
        END IF;

        UPDATE PRODUCTO
        SET precio = ROUND(precio * (1 + (p_porcentaje / 100)))
        WHERE id_categoria = p_id_categoria;

        p_filas_afectadas := SQL%ROWCOUNT;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            p_filas_afectadas := 0;
            sp_registrar_log_interno(
                'PKG_SONIDO_VIVO.sp_reajustar_precios',
                TO_CHAR(SQLCODE),
                SQLERRM
            );
            ROLLBACK;
            RAISE;
    END sp_reajustar_precios;

    -- -------------------------------------------------------------------------
    -- IMPLEMENTACION: sp_liquidar_clientes (CON PARAMETROS)
    -- Consolida compras mensuales de clientes, calcula snapshot y escribe en LIQUIDACION_CLIENTE
    -- -------------------------------------------------------------------------
    PROCEDURE sp_liquidar_clientes(
        p_periodo           IN VARCHAR2,
        p_filas_liquidadas  OUT NUMBER
    ) IS
        v_contador NUMBER := 0;
        v_tasa_pct NUMBER := 0;
        v_descuento NUMBER := 0;
        v_total_neto NUMBER := 0;

        CURSOR c_clientes_periodo IS
            SELECT 
                c.id_cliente,
                c.nombres || ' ' || c.apellidos AS nombre_completo,
                c.tipo_cliente,
                COUNT(v.id_venta) AS cantidad_compras,
                NVL(SUM(v.total), 0) AS total_bruto
            FROM CLIENTE c
            INNER JOIN VENTA v ON c.id_cliente = v.id_cliente
            WHERE TO_CHAR(v.fecha_venta, 'YYYY-MM') = p_periodo
              AND v.estado_venta = 'LIQUIDADA'
            GROUP BY c.id_cliente, c.nombres, c.apellidos, c.tipo_cliente;
    BEGIN
        FOR r_cli IN c_clientes_periodo LOOP
            v_tasa_pct := fn_calcular_descuento(r_cli.total_bruto, r_cli.tipo_cliente);
            v_descuento := ROUND(r_cli.total_bruto * (v_tasa_pct / 100));
            v_total_neto := r_cli.total_bruto - v_descuento;

            INSERT INTO LIQUIDACION_CLIENTE (
                id_liquidacion, id_cliente, nombre_completo, total_bruto,
                tasa_descuento_pct, monto_descuento, total_neto, cantidad_compras,
                fecha_liquidacion, observacion
            ) VALUES (
                SEQ_LIQUIDACION_CLIENTE.NEXTVAL,
                r_cli.id_cliente,
                r_cli.nombre_completo,
                r_cli.total_bruto,
                v_tasa_pct,
                v_descuento,
                v_total_neto,
                r_cli.cantidad_compras,
                SYSDATE,
                'PROCESO MENSUAL AUTOMATICO PERIODO ' || p_periodo
            );

            v_contador := v_contador + 1;
        END LOOP;

        p_filas_liquidadas := v_contador;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            p_filas_liquidadas := 0;
            sp_registrar_log_interno(
                'PKG_SONIDO_VIVO.sp_liquidar_clientes',
                TO_CHAR(SQLCODE),
                SQLERRM
            );
            ROLLBACK;
            RAISE;
    END sp_liquidar_clientes;

    -- -------------------------------------------------------------------------
    -- IMPLEMENTACION: sp_actualizar_estadisticas_inventario (SIN PARAMETROS)
    -- Mantenimiento y trazabilidad masiva de stock critico en HISTORIAL_STOCK
    -- -------------------------------------------------------------------------
    PROCEDURE sp_actualizar_estadisticas_inventario IS
    BEGIN
        INSERT INTO HISTORIAL_STOCK (
            id_historial, id_producto, fecha_movimiento, tipo_movimiento,
            cantidad, stock_anterior, stock_posterior, motivo, usuario_bd
        )
        SELECT 
            SEQ_HISTORIAL_STOCK.NEXTVAL,
            id_producto,
            SYSDATE,
            'AUDITORIA',
            0,
            stock,
            stock,
            'INSPECCION AUTOMATICA DE STOCK CRITICO',
            USER
        FROM PRODUCTO
        WHERE stock <= stock_critico;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            sp_registrar_log_interno(
                'PKG_SONIDO_VIVO.sp_actualizar_estadisticas_inventario',
                TO_CHAR(SQLCODE),
                SQLERRM
            );
            ROLLBACK;
    END sp_actualizar_estadisticas_inventario;

END PKG_SONIDO_VIVO;
/

-- -----------------------------------------------------------------------------
-- 4. TRIGGERS EXIGIDOS POR LA RUBRICA (NIVEL DE FILA Y NIVEL DE SENTENCIA)
-- -----------------------------------------------------------------------------

-- 4.1 TRIGGER A NIVEL DE FILA: Validacion y descuento automatico de stock
CREATE OR REPLACE TRIGGER TRG_VALIDA_Y_DESCUENTA_STOCK
BEFORE INSERT ON DETALLE_VENTA
FOR EACH ROW
DECLARE
    v_stock_disponible NUMBER;
BEGIN
    SELECT stock INTO v_stock_disponible
    FROM PRODUCTO
    WHERE id_producto = :NEW.id_producto;

    IF v_stock_disponible < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Operacion rechazada por regla de inventario: Stock insuficiente para producto ID ' || 
            :NEW.id_producto || '. Disponible en bodega: ' || v_stock_disponible || 
            ', Cantidad solicitada: ' || :NEW.cantidad
        );
    END IF;

    UPDATE PRODUCTO
    SET stock = stock - :NEW.cantidad
    WHERE id_producto = :NEW.id_producto;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'El producto ID ' || :NEW.id_producto || ' no existe en el catalogo de Sonido Vivo.'
        );
END;
/

-- 4.2 TRIGGER A NIVEL DE FILA: Auditoria forense reactiva de precios
CREATE OR REPLACE TRIGGER TRG_AUDITA_PRECIO_PRODUCTO
AFTER UPDATE OF precio ON PRODUCTO
FOR EACH ROW
WHEN (NEW.precio <> OLD.precio)
BEGIN
    INSERT INTO AUDIT_PRECIOS_PRODUCTO (
        id_audit, id_producto, precio_anterior, precio_nuevo, usuario_bd, fecha_cambio
    ) VALUES (
        SEQ_AUDIT_PRECIOS.NEXTVAL,
        :NEW.id_producto,
        :OLD.precio,
        :NEW.precio,
        USER,
        SYSDATE
    );
END;
/

-- 4.3 TRIGGER A NIVEL DE SENTENCIA: Control y conteo transaccional sobre VENTA
-- Se ejecuta exactamente UNA vez por sentencia ejecutada (sin FOR EACH ROW)
CREATE OR REPLACE TRIGGER TRG_CONTROL_OPERACION_VENTAS
AFTER INSERT OR UPDATE OR DELETE ON VENTA
DECLARE
    v_tipo VARCHAR2(25);
    v_total_ventas NUMBER;
BEGIN
    IF INSERTING THEN
        v_tipo := 'INSERCION SENTENCIA';
    ELSIF UPDATING THEN
        v_tipo := 'MODIFICACION SENTENCIA';
    ELSE
        v_tipo := 'ELIMINACION SENTENCIA';
    END IF;

    SELECT COUNT(*) INTO v_total_ventas FROM VENTA;

    INSERT INTO CONTROL_OPERACION_VENTAS (
        id_operacion, tipo_evento, usuario_bd, fecha_evento, total_filas_bd
    ) VALUES (
        SEQ_CONTROL_VENTAS.NEXTVAL,
        v_tipo,
        USER,
        SYSDATE,
        v_total_ventas
    );
END;
/

-- -----------------------------------------------------------------------------
-- 5. BLOQUES DE PRUEBA Y DEMOSTRACION DE CUMPLIMIENTO DE RUBRICA
-- -----------------------------------------------------------------------------

PROMPT =========================================================================
PROMPT PRUEBA 1: USO DE FUNCIONES EN SENTENCIAS SQL (INDICADOR IE2.1.3)
PROMPT =========================================================================

SELECT 
    c.rut,
    c.nombres || ' ' || c.apellidos AS cliente,
    c.tipo_cliente,
    v.id_venta,
    v.total AS monto_venta,
    PKG_SONIDO_VIVO.fn_calcular_descuento(v.total, c.tipo_cliente) AS pct_descuento_calculado,
    ROUND(v.total * (PKG_SONIDO_VIVO.fn_calcular_descuento(v.total, c.tipo_cliente) / 100)) AS ahorro_clp,
    PKG_SONIDO_VIVO.fn_obtener_umbral_descuento() AS umbral_minimo_pesos
FROM VENTA v
INNER JOIN CLIENTE c ON v.id_cliente = c.id_cliente
WHERE v.estado_venta = 'LIQUIDADA'
ORDER BY v.id_venta;

PROMPT =========================================================================
PROMPT PRUEBA 2: PROCEDIMIENTOS CON Y SIN PARAMETROS (INDICADOR IE2.1.1)
PROMPT =========================================================================

DECLARE
    v_filas_reajustadas NUMBER;
    v_filas_liquidadas  NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- INICIO PRUEBA PROCEDIMIENTOS ---');
    
    -- Procedimiento CON parametros: Reajuste 5% en Categoria 1 (Guitarras Acusticas)
    PKG_SONIDO_VIVO.sp_reajustar_precios(
        p_porcentaje => 5,
        p_id_categoria => 1,
        p_filas_afectadas => v_filas_reajustadas
    );
    DBMS_OUTPUT.PUT_LINE('Productos reajustados (sp_reajustar_precios): ' || v_filas_reajustadas);

    -- Procedimiento SIN parametros: Auditoria de stock critico
    PKG_SONIDO_VIVO.sp_actualizar_estadisticas_inventario;
    DBMS_OUTPUT.PUT_LINE('Procedimiento sp_actualizar_estadisticas_inventario ejecutado exitosamente.');

    -- Procedimiento CON parametros: Liquidacion de clientes
    PKG_SONIDO_VIVO.sp_liquidar_clientes(
        p_periodo => TO_CHAR(SYSDATE, 'YYYY-MM'),
        p_filas_liquidadas => v_filas_liquidadas
    );
    DBMS_OUTPUT.PUT_LINE('Clientes liquidados en LIQUIDACION_CLIENTE: ' || v_filas_liquidadas);
    DBMS_OUTPUT.PUT_LINE('--- FIN PRUEBA PROCEDIMIENTOS ---');
END;
/

PROMPT =========================================================================
PROMPT PRUEBA 3: VERIFICACION DE TABLAS DE AUDITORIA Y TRIGGERS
PROMPT =========================================================================

-- Auditoria reactiva de precios generada por el trigger de fila
SELECT * FROM AUDIT_PRECIOS_PRODUCTO ORDER BY id_audit DESC;

-- Control transaccional registrado por el trigger a nivel de sentencia
SELECT * FROM CONTROL_OPERACION_VENTAS ORDER BY id_operacion DESC;

-- Liquidaciones calculadas por el package
SELECT * FROM LIQUIDACION_CLIENTE ORDER BY id_liquidacion DESC;
