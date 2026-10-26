# Propuesta de Reglas de Negocio y Casos Adicionales (Unidad 2 - EP2)

**Proyecto:** Sonido Vivo — Tienda de Instrumentos Musicales y Audio Profesional  
**Asignatura:** Taller de Base de Datos (BDY1103)  
**Evaluacion:** Evaluacion Parcial N° 2  
**Estado:** Propuesta Modular Opcional para Discusion en Equipo  
**Nota de Alcance:** Estos artefactos se mantienen desacoplados del script base (`01_paquetes_y_triggers_ep2.sql`) para preservar la simplicidad del trabajo grupal y evitar agregar complejidad al codigo principal sin consenso del equipo.

---

## 1. Contexto y Justificacion para el Equipo

En la Evaluacion Parcial 2, la rubrica exige el dominio de:
- Procedimientos almacenados con y sin parametros (IE2.1.1 e IE2.1.2).
- Funciones con y sin parametros (IE2.1.3 e IE2.1.4).
- Packages con constructores publicos y privados (IE2.2.1 e IE2.2.2).
- Triggers a nivel de fila y sentencia (IE2.3.1 e IE2.3.2).

El script base acordado cubre los requisitos minimos obligatorios de la pauta. Los siguientes casos han sido formulados como **ampliaciones de valor** que pueden incluirse en el informe o exponerse durante la defensa oral como "casos de borde y robustez operativa", sin riesgo de alterar el codigo base de los companeros.

---

## 2. Caso Adicional A: Procedimiento de Anulacion de Ventas con Restitucion de Stock (`sp_anular_venta`)

### 2.1 Justificacion de Negocio
En la operacion real de Sonido Vivo, la anulacion de una orden de venta exige consistencia transaccional absoluta. Si se anula una venta, las unidades no deben desaparecer ni quedar huerfanas: deben reincorporarse atomicamente al inventario fisico de bodega (`PRODUCTO`), la cabecera debe marcarse como `ANULADA` y debe prevenirse una doble anulacion.

### 2.2 Codigo PL/SQL Propuesto
```sql
CREATE OR REPLACE PROCEDURE sp_anular_venta(
    p_id_venta          IN NUMBER,
    p_motivo_anulacion  IN VARCHAR2,
    p_items_restituidos OUT NUMBER,
    p_estado_final      OUT VARCHAR2
) IS
    -- Cursor explicito para leer los items vendidos que deben retornar a bodega
    CURSOR c_items IS
        SELECT id_producto, cantidad
        FROM DETALLE_VENTA
        WHERE id_venta = p_id_venta;

    v_estado_actual     VENTA.estado_venta%TYPE;
    v_contador_items    NUMBER := 0;
    e_venta_no_anulable EXCEPTION;
BEGIN
    -- 1. Verificacion de existencia y bloqueo pesimista de la orden
    SELECT estado_venta INTO v_estado_actual
    FROM VENTA
    WHERE id_venta = p_id_venta
    FOR UPDATE;

    -- Validacion de regla: no anular una venta previamente anulada
    IF v_estado_actual = 'ANULADA' THEN
        RAISE e_venta_no_anulable;
    END IF;

    -- 2. Restitucion masiva de unidades recorriendo el cursor
    FOR r_item IN c_items LOOP
        UPDATE PRODUCTO
        SET stock = stock + r_item.cantidad
        WHERE id_producto = r_item.id_producto;

        v_contador_items := v_contador_items + 1;
    END LOOP;

    -- 3. Actualizacion del estado en la cabecera
    UPDATE VENTA
    SET estado_venta = 'ANULADA'
    WHERE id_venta = p_id_venta;

    -- 4. Confirmacion de la unidad de trabajo (COMMIT)
    p_items_restituidos := v_contador_items;
    p_estado_final := 'EXITO: Orden anulada y stock retornado a bodega.';
    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_items_restituidos := 0;
        p_estado_final := 'ERROR: La venta N° ' || p_id_venta || ' no existe en el sistema.';
        ROLLBACK;
    WHEN e_venta_no_anulable THEN
        p_items_restituidos := 0;
        p_estado_final := 'ERROR: La venta ya se encuentra en estado ANULADA.';
        ROLLBACK;
    WHEN OTHERS THEN
        p_items_restituidos := 0;
        p_estado_final := 'ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM;
        ROLLBACK;
END sp_anular_venta;
/
```

### 2.3 Bloque de Prueba Independiente
```sql
DECLARE
    v_restituidos NUMBER;
    v_mensaje     VARCHAR2(200);
BEGIN
    -- Prueba de anulacion sobre la venta 1 (ajustar ID segun datos de prueba)
    sp_anular_venta(
        p_id_venta          => 1,
        p_motivo_anulacion  => 'Desistimiento de compra por parte del cliente en sucursal',
        p_items_restituidos => v_restituidos,
        p_estado_final      => v_mensaje
    );
    DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_mensaje);
    DBMS_OUTPUT.PUT_LINE('Total de productos restituidos: ' || v_restituidos);
END;
/
```

---

## 3. Caso Adicional B: Trigger de Fila de Control Comercial y Precio Minimo (`TRG_VALIDA_PRECIO_MINIMO`)

### 3.1 Justificacion de Negocio
Previene errores de digitacion o fraudes que vulneren el margen de ganancia de Sonido Vivo:
1. Ningun producto del catalogo puede tener un precio inferior a $10.000 CLP (precio base de articulos menores como cables o accesorios tecnicos).
2. Si un operador o script de actualizacion intenta rebajar el precio de un articulo en mas del 80% de su valor actual en un solo movimiento, la operacion es rechazada de inmediato.

### 3.2 Codigo PL/SQL Propuesto
```sql
CREATE OR REPLACE TRIGGER TRG_VALIDA_PRECIO_MINIMO
BEFORE INSERT OR UPDATE OF precio ON PRODUCTO
FOR EACH ROW
BEGIN
    -- Regla 1: Umbral minimo de venta
    IF :NEW.precio < 10000 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'RECHAZO COMERCIAL: El precio de ' || :NEW.nombre || 
            ' ($' || :NEW.precio || ') es inferior al precio base permitido ($10.000 CLP).'
        );
    END IF;

    -- Regla 2: Prevencion de devaluacion abrupta superior al 80%
    IF UPDATING('precio') AND :NEW.precio < (:OLD.precio * 0.20) THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'ALERTA SEGURIDAD PRECIOS: Devaluacion excesiva sobre ' || :OLD.nombre || 
            '. Precio actual: $' || :OLD.precio || ', Precio ingresado: $' || :NEW.precio
        );
    END IF;
END;
/
```

### 3.3 Bloque de Prueba Independiente
```sql
-- Prueba 1: Debe fallar con error ORA-20003 por precio menor a $10.000
BEGIN
    UPDATE PRODUCTO SET precio = 5000 WHERE id_producto = 1;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Prueba 1 Capturada Exitosamente: ' || SQLERRM);
END;
/
```

---

## 4. Estrategia de Uso Recomendada para el Grupo

1. **Mantener el Script Base Intacto:**
   No modificar [01_paquetes_y_triggers_ep2.sql](file:///c:/Users/NezerkC/OneDrive/Escritorio/instituto/taller%20base%20de%20datos/prueba%20parcial%202/scripts/01_paquetes_y_triggers_ep2.sql) para que todos los integrantes del equipo ejecuten exactamente el mismo codigo acordado sin conflictos de version.
2. **Presentacion al Equipo:**
   Compartir este documento con los companeros. Si el grupo decide incluirlos formalmente en la entrega, solo tomara 2 minutos copiar estos dos bloques al final del script principal o empaquetarlos dentro de `PKG_SONIDO_VIVO`.
3. **Respaldo para la Defensa Individual:**
   Si el profesor pregunta individualmente: *"¿Que otras reglas de negocio implementarian para robustecer el sistema?"*, puedes explicar verbalmente la logica de `sp_anular_venta` y `TRG_VALIDA_PRECIO_MINIMO`, demostrando un nivel de dominio arquitectonico superior al promedio.
