-- ============================================================================
-- SCRIPT: 04_bloque_excepciones.sql
-- PROYECTO: Sonido Vivo — Tienda de Instrumentos Musicales (Viña del Mar)
-- ASIGNATURA: BDY1103 - Taller de Base de Datos (Evaluación Parcial N° 1)
-- INDICADOR: IE1.3.1 (Excepciones predefinidas y definidas por el usuario)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    -- ------------------------------------------------------------------------
    -- 1. EXCEPCIONES DEFINIDAS POR EL USUARIO (REGLAS DE NEGOCIO)
    -- ------------------------------------------------------------------------
    e_stock_insuficiente    EXCEPTION;
    e_cantidad_invalida     EXCEPTION;
    e_limite_credito_exceso EXCEPTION;

    -- Parámetros de simulación de venta (Intento de compra en caja o web)
    v_id_cliente_solicitado  NUMBER := 1;          -- Cliente Carlos Valenzuela
    v_codigo_prod_solicitado VARCHAR2(10) := 'GE002'; -- Gibson Les Paul Tribute (Stock: 2)
    v_cantidad_solicitada    NUMBER := 5;          -- Forzamos venta superior al stock para gatillar excepción

    -- Variables de soporte para consulta y cálculo
    v_id_producto   PRODUCTO.id_producto%TYPE;
    v_nombre_prod   PRODUCTO.nombre%TYPE;
    v_precio_prod   PRODUCTO.precio%TYPE;
    v_stock_actual  PRODUCTO.stock%TYPE;
    v_stock_critico PRODUCTO.stock_critico%TYPE;
    v_rut_cliente   CLIENTE.rut%TYPE;
    v_nombre_cli    CLIENTE.nombres%TYPE;
    
    -- Manejo de auditoría
    v_secuencia_log NUMBER(8);
    v_cod_error     VARCHAR2(50);
    v_msj_error     VARCHAR2(400);

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('     SONIDO VIVO — SIMULADOR TRANSACCIONAL CON CONTROL DE EXCEPCIONES           ');
    DBMS_OUTPUT.PUT_LINE('================================================================================');

    -- Obtener siguiente correlativo de log
    SELECT NVL(MAX(id_log), 0) + 1 INTO v_secuencia_log FROM LOG_ERRORES;

    -- ------------------------------------------------------------------------
    -- VALIDACIÓN 1: Existencia del cliente (Gatilla NO_DATA_FOUND si no existe)
    -- ------------------------------------------------------------------------
    SELECT rut, nombres
    INTO v_rut_cliente, v_nombre_cli
    FROM CLIENTE
    WHERE id_cliente = v_id_cliente_solicitado;

    DBMS_OUTPUT.PUT_LINE('>> Cliente Verificado: ' || v_nombre_cli || ' (RUT: ' || v_rut_cliente || ')');

    -- ------------------------------------------------------------------------
    -- VALIDACIÓN 2: Regla de cantidad positiva
    -- ------------------------------------------------------------------------
    IF v_cantidad_solicitada <= 0 THEN
        RAISE e_cantidad_invalida;
    END IF;

    -- ------------------------------------------------------------------------
    -- VALIDACIÓN 3: Existencia del producto (Gatilla NO_DATA_FOUND si código no existe)
    -- ------------------------------------------------------------------------
    SELECT id_producto, nombre, precio, stock, stock_critico
    INTO v_id_producto, v_nombre_prod, v_precio_prod, v_stock_actual, v_stock_critico
    FROM PRODUCTO
    WHERE codigo = v_codigo_prod_solicitado;

    DBMS_OUTPUT.PUT_LINE('>> Producto Seleccionado: ' || v_nombre_prod || 
                         ' | Stock en Bodega: ' || v_stock_actual || 
                         ' | Cantidad Pedida: ' || v_cantidad_solicitada);

    -- ------------------------------------------------------------------------
    -- VALIDACIÓN 4: Validación de Stock Disponible (Excepción de Usuario)
    -- ------------------------------------------------------------------------
    IF v_cantidad_solicitada > v_stock_actual THEN
        RAISE e_stock_insuficiente;
    END IF;

    -- Si las validaciones son exitosas, se procesaría la venta normalmente
    DBMS_OUTPUT.PUT_LINE('>> ÉXITO: Stock reservado y transacción completada satisfactoriamente.');
    COMMIT;

EXCEPTION
    -- ========================================================================
    -- MANEJO DE EXCEPCIONES PREDEFINIDAS POR ORACLE
    -- ========================================================================
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
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
        v_cod_error := 'ORA-01422 (TOO_MANY_ROWS)';
        v_msj_error := 'Inconsistencia de catálogo: Se encontró más de un registro para el identificador consultado.';
        
        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen, usuario_bd, fecha_registro)
        VALUES (v_secuencia_log, v_cod_error, v_msj_error, 'MODULO_VENTAS_CHECKOUT', USER, SYSDATE);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN ORACLE CAPTURADA]: ' || v_msj_error);

    -- ========================================================================
    -- MANEJO DE EXCEPCIONES DEFINIDAS POR EL USUARIO
    -- ========================================================================
    WHEN e_stock_insuficiente THEN
        ROLLBACK;
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
        v_cod_error := 'USR-002 (CANTIDAD_INVALIDA)';
        v_msj_error := 'Operación rechazada: La cantidad a comprar debe ser un entero estrictamente mayor a cero.';
        
        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen, usuario_bd, fecha_registro)
        VALUES (v_secuencia_log, v_cod_error, v_msj_error, 'MODULO_VENTAS_PARAMETROS', USER, SYSDATE);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[EXCEPCIÓN DE NEGOCIO CAPTURADA]: ' || v_msj_error);

    -- ========================================================================
    -- CAPTURA GENERAL DE ERRORES IMPREVISTOS
    -- ========================================================================
    WHEN OTHERS THEN
        ROLLBACK;
        v_cod_error := 'ORA-' || TO_CHAR(SQLCODE);
        v_msj_error := SUBSTR(SQLERRM, 1, 380);
        
        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, modulo_origen, usuario_bd, fecha_registro)
        VALUES (v_secuencia_log, v_cod_error, v_msj_error, 'MODULO_VENTAS_GENERAL', USER, SYSDATE);
        COMMIT;

        DBMS_OUTPUT.PUT_LINE('[ERROR NO CONTROLADO]: ' || v_msj_error);

END;
/
