-- ============================================================================
-- SCRIPT: 03_bloque_cursores_anidados.sql
-- PROYECTO: Sonido Vivo — Tienda de Instrumentos Musicales (Viña del Mar)
-- ASIGNATURA: BDY1103 - Taller de Base de Datos (Evaluación Parcial N° 1)
-- INDICADOR: IE1.2.1 (Cursores explícitos complejos con parámetros y loops anidados)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    -- ------------------------------------------------------------------------
    -- 1. CURSORES EXPLÍCITOS
    -- ------------------------------------------------------------------------

    -- Cursor Padre (Principal): Obtiene los clientes con ventas asociadas
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

    -- Cursor Hijo (Secundario Complejo con Parámetro):
    -- Cruza Venta, Detalle, Producto y Categoría para un cliente específico
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

    -- Variables de control y acumuladores
    v_total_cliente       NUMBER(10);
    v_total_unidades      NUMBER(6);
    v_boleta_actual       NUMBER(8);
    v_contador_clientes   NUMBER(4) := 0;

BEGIN
    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('     SONIDO VIVO — AUDITORÍA DETALLADA DE COMPRAS POR CLIENTE (CURSORES)        ');
    DBMS_OUTPUT.PUT_LINE('================================================================================');

    -- ========================================================================
    -- BUCLE EXTERNO (LOOP 1): Itera sobre cada cliente
    -- ========================================================================
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

        -- ====================================================================
        -- BUCLE INTERNO (LOOP 2): Itera sobre los detalles del cliente parametrizado
        -- ====================================================================
        FOR reg_det IN c_ventas_cliente(reg_cli.id_cliente) LOOP
            
            -- Encabezado por boleta
            IF v_boleta_actual <> reg_det.nro_boleta THEN
                v_boleta_actual := reg_det.nro_boleta;
                DBMS_OUTPUT.PUT_LINE('  >> Boleta N° ' || v_boleta_actual || ' (Emitida: ' || TO_CHAR(reg_det.fecha_venta, 'DD/MM/YYYY') || '):');
            END IF;

            -- Impresión del detalle de producto
            DBMS_OUTPUT.PUT_LINE('     * [' || reg_det.codigo_prod || '] ' || 
                                 RPAD(reg_det.nombre_prod, 32) || 
                                 ' (' || RPAD(reg_det.nombre_categoria, 18) || ') ' ||
                                 ' | Cant: ' || LPAD(reg_det.cantidad, 2) || 
                                 ' x $' || LPAD(TO_CHAR(reg_det.precio_unitario, '999G999'), 9) || 
                                 ' = $' || LPAD(TO_CHAR(reg_det.subtotal_linea, '999G999'), 9));

            -- Acumuladores del cliente
            v_total_cliente  := v_total_cliente + reg_det.subtotal_linea;
            v_total_unidades := v_total_unidades + reg_det.cantidad;

        END LOOP; -- Fin Bucle Interno

        -- Resumen del cliente
        DBMS_OUTPUT.PUT_LINE('  --> RESUMEN CLIENTE: ' || v_total_unidades || ' unidades adquiridas | Total Acumulado: $' || 
                             TO_CHAR(v_total_cliente, '999G999G999'));

    END LOOP; -- Fin Bucle Externo

    DBMS_OUTPUT.PUT_LINE('================================================================================');
    DBMS_OUTPUT.PUT_LINE('>> PROCESAMIENTO COMPLETADO: ' || v_contador_clientes || ' clientes auditados con éxito.');
    DBMS_OUTPUT.PUT_LINE('================================================================================');

END;
/
