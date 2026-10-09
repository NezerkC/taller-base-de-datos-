-- ============================================================================
-- SCRIPT: 05_triggers_propuestos.sql
-- PROYECTO: Sonido Vivo — Tienda de Instrumentos Musicales (Viña del Mar)
-- ASIGNATURA: BDY1103 - Taller de Base de Datos (Evaluación Parcial N° 1)
-- INDICADOR: IE1.4.1 (Evolución a Producción: Triggers de Inventario y Alertas)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;

-- ----------------------------------------------------------------------------
-- 1. TRIGGER: TRG_DESCUENTA_STOCK
-- PROPÓSITO: Descuenta automáticamente las unidades físicas de PRODUCTO tras
-- cada venta registrada en DETALLE_VENTA.
-- MITIGACIÓN ORA-04091: Al dispararse sobre DETALLE_VENTA y mutar PRODUCTO
-- (tabla externa), no produce error de tabla mutante.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_DESCUENTA_STOCK
AFTER INSERT ON DETALLE_VENTA
FOR EACH ROW
BEGIN
    UPDATE PRODUCTO
    SET stock = stock - :NEW.cantidad
    WHERE id_producto = :NEW.id_producto;
END;
/

-- ----------------------------------------------------------------------------
-- 2. TRIGGER: TRG_AUDITA_STOCK_CRITICO
-- PROPÓSITO: Monitorea las actualizaciones de inventario en PRODUCTO. Si el stock
-- resultante cae por debajo o igual al stock_critico, registra una alerta preventiva
-- en LOG_ERRORES para reabastecimiento en la bodega de Viña del Mar.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUDITA_STOCK_CRITICO
AFTER UPDATE OF stock ON PRODUCTO
FOR EACH ROW
WHEN (NEW.stock <= NEW.stock_critico)
BEGIN
    INSERT INTO LOG_ERRORES (
        id_log,
        codigo_error,
        mensaje_error,
        modulo_origen,
        usuario_bd,
        fecha_registro
    ) VALUES (
        SEQ_LOG_ERRORES.NEXTVAL,
        'WARN-STOCK-CRITICO',
        'ALERTA REPOSICIÓN: El producto ' || :NEW.codigo || ' (' || :NEW.nombre || 
        ') ha alcanzado nivel crítico de inventario. Stock actual: ' || :NEW.stock || 
        ' (Umbral mínimo: ' || :NEW.stock_critico || '). Requiere pedido a bodega.',
        'TRG_AUDITA_STOCK_CRITICO',
        USER,
        SYSDATE
    );
END;
/

-- ----------------------------------------------------------------------------
-- 3. DEMOSTRACIÓN Y VERIFICACIÓN EN CONSOLA
-- ----------------------------------------------------------------------------
PROMPT ========================================================================;
PROMPT >> TRIGGERS CREADOS CON ÉXITO:;
PROMPT    1. TRG_DESCUENTA_STOCK (AFTER INSERT ON DETALLE_VENTA);
PROMPT    2. TRG_AUDITA_STOCK_CRITICO (AFTER UPDATE OF stock ON PRODUCTO);
PROMPT ========================================================================;
