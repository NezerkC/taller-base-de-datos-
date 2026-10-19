---
tags:
  - taller-bd
  - pl-sql
  - unidad-2
  - triggers
  - excepciones
  - auditoria
aliases:
  - De Excepciones a Triggers
  - Triggers de Fila y Sentencia con Auditoria
created: 2026-10-14
---

# 03 - Del Manejo de Excepciones a Triggers y Auditoria Autonoma

En esta guia se profundiza en como las validaciones manuales y el manejo de excepciones de la Unidad 1 (`04_bloque_excepciones.sql`) se sustituyen por **Triggers de Fila y Sentencia**, garantizando la integridad de datos a nivel de motor y evitando errores de **Tabla Mutante (`ORA-04091`)**.

---

## 1. El Enfoque Manual de la Unidad 1

En `04_bloque_excepciones.sql`, la proteccion contra ventas sin stock dependia de que el desarrollador recordara escribir un bloque con excepciones de usuario:

```sql
-- Codigo Unidad 1: Validacion Manual en Bloque Anonimo
DECLARE
    e_stock_insuficiente EXCEPTION;
    v_stock_actual NUMBER;
    v_cant_pedida  NUMBER := 50; -- Intento de compra excesivo
BEGIN
    SELECT stock INTO v_stock_actual 
    FROM PRODUCTO WHERE id_producto = 1;

    IF v_stock_actual < v_cant_pedida THEN
        RAISE e_stock_insuficiente;
    END IF;

    -- Si pasaba la validacion, se hacia el insert
    INSERT INTO DETALLE_VENTA VALUES (...);
EXCEPTION
    WHEN e_stock_insuficiente THEN
        INSERT INTO LOG_ERRORES VALUES (..., 'Stock insuficiente');
        COMMIT;
END;
/
```

**Riesgo en Produccion:** Si alguien insertaba una fila en `DETALLE_VENTA` desde una aplicacion web o mediante una sentencia `INSERT` directa en SQL Developer, la validacion no se ejecutaba y se vendia producto sin inventario real.

---

## 2. La Solucion Automatica en la Unidad 2: Triggers de Base de Datos

En la Unidad 2, la regla se traslada al motor relacional mediante un **Trigger**. Nadie puede saltarse la regla porque se dispara automaticamente cada vez que una fila entra a la tabla.

### A. Trigger a Nivel de Fila: Validacion Preventiva de Stock (`TRG_VALIDA_STOCK_VENTA`)
- **Tipo:** `BEFORE INSERT ON DETALLE_VENTA FOR EACH ROW`
- **Mecanismo:** Antes de que la fila se grabe en el disco, consulta el stock disponible en `PRODUCTO`. Si es insuficiente, cancela la transaccion con `RAISE_APPLICATION_ERROR`. Si es suficiente, descuenta el stock de inmediato.

```sql
CREATE OR REPLACE TRIGGER TRG_VALIDA_STOCK_VENTA
BEFORE INSERT ON DETALLE_VENTA
FOR EACH ROW
DECLARE
    v_stock_disponible PRODUCTO.stock%TYPE;
    v_nombre_prod      PRODUCTO.nombre%TYPE;
BEGIN
    -- 1. Obtener el stock actual del producto involucrado
    SELECT stock, nombre
    INTO v_stock_disponible, v_nombre_prod
    FROM PRODUCTO
    WHERE id_producto = :NEW.id_producto;

    -- 2. Validar disponibilidad
    IF v_stock_disponible < :NEW.cantidad THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'OPERACION CANCELADA: Stock insuficiente para el producto ' || 
            v_nombre_prod || '. Solicitado: ' || :NEW.cantidad || 
            ' | Disponible en bodega: ' || v_stock_disponible
        );
    END IF;

    -- 3. Si hay stock suficiente, descontar automaticamente
    UPDATE PRODUCTO
    SET stock = stock - :NEW.cantidad
    WHERE id_producto = :NEW.id_producto;
END;
/
```

---

## 3. Auditoria Reactiva de Precios (`TRG_AUDIT_PRECIO_PRODUCTO`)

El segundo trigger solicitado en la Unidad 2 monitorea cambios de precios en el catalogo y guarda el historico en una tabla dedicada (`AUDIT_PRECIOS_PRODUCTO`):

- **Tipo:** `AFTER UPDATE OF precio ON PRODUCTO FOR EACH ROW`
- **Mecanismo:** Utiliza las pseudocolumnas `:OLD.precio` (valor antes del cambio) y `:NEW.precio` (nuevo valor asignado).

```sql
-- 1. Estructura de la tabla de auditoria
CREATE TABLE AUDIT_PRECIOS_PRODUCTO (
    id_audit         NUMBER(10) PRIMARY KEY,
    id_producto      NUMBER(10) NOT NULL,
    codigo_producto  VARCHAR2(20) NOT NULL,
    precio_anterior  NUMBER(10) NOT NULL,
    precio_nuevo     NUMBER(10) NOT NULL,
    porcentaje_var   NUMBER(5, 2),
    usuario_bd       VARCHAR2(50) DEFAULT USER NOT NULL,
    fecha_modifica   DATE DEFAULT SYSDATE NOT NULL
);

CREATE SEQUENCE SEQ_AUDIT_PRECIOS START WITH 1 INCREMENT BY 1 NOCACHE;

-- 2. Disparador de auditoria
CREATE OR REPLACE TRIGGER TRG_AUDIT_PRECIO_PRODUCTO
AFTER UPDATE OF precio ON PRODUCTO
FOR EACH ROW
WHEN (NEW.precio <> OLD.precio)
DECLARE
    v_variacion NUMBER(5, 2);
BEGIN
    v_variacion := ROUND(((:NEW.precio - :OLD.precio) / :OLD.precio) * 100, 2);

    INSERT INTO AUDIT_PRECIOS_PRODUCTO (
        id_audit,
        id_producto,
        codigo_producto,
        precio_anterior,
        precio_nuevo,
        porcentaje_var,
        usuario_bd,
        fecha_modifica
    ) VALUES (
        SEQ_AUDIT_PRECIOS.NEXTVAL,
        :NEW.id_producto,
        :NEW.codigo,
        :OLD.precio,
        :NEW.precio,
        v_variacion,
        USER,
        SYSDATE
    );
END;
/
```

---

## 4. Trigger a Nivel de Sentencia: Control Global de Operaciones

A diferencia de los triggers de fila (que se ejecutan una vez por cada registro afectado), un **Trigger a Nivel de Sentencia** se ejecuta **una sola vez por instruccion SQL**, sin importar si la sentencia toco una fila o un millon de filas.

```sql
CREATE OR REPLACE TRIGGER TRG_CONTROL_OPERACION_VENTAS
AFTER INSERT OR UPDATE OR DELETE ON VENTA
BEGIN
    IF INSERTING THEN
        DBMS_OUTPUT.PUT_LINE('AUDITORIA SENTENCIA: Se ha registrado una nueva venta en el sistema.');
    ELSIF UPDATING THEN
        DBMS_OUTPUT.PUT_LINE('AUDITORIA SENTENCIA: Se ha modificado un registro en la tabla VENTA.');
    ELSIF DELETING THEN
        DBMS_OUTPUT.PUT_LINE('AUDITORIA SENTENCIA: Se ha eliminado una venta del sistema.');
    END IF;
END;
/
```

---

## 5. Dos Preguntas de Defensa Criticas para el Profesor

### Pregunta 1: ¿Por que no ocurre el error de Tabla Mutante (`ORA-04091`) en `TRG_VALIDA_STOCK_VENTA`?
- **Explicacion Tecnica:** El error `ORA-04091` ocurre cuando un trigger a nivel de fila intenta leer o modificar la **misma tabla** sobre la cual se esta disparando (la tabla que esta "mutando" en medio de la transaccion).
- **En nuestra arquitectura:** El trigger se dispara sobre la tabla `DETALLE_VENTA` y realiza el `UPDATE` sobre una tabla externa (`PRODUCTO`). Como `PRODUCTO` no esta en estado mutante durante la insercion en `DETALLE_VENTA`, Oracle permite la operacion sin conflictos.

### Pregunta 2: ¿Por que usamos `PRAGMA AUTONOMOUS_TRANSACTION` en el registro de errores?
- **Explicacion Tecnica:** Si una transaccion principal falla (por ejemplo, un fallo en la liquidacion masiva), el sistema ejecuta un `ROLLBACK` para deshacer los cambios corruptos. Sin una transaccion autonoma, el `ROLLBACK` borraria tambien el registro del error en `LOG_ERRORES`.
- **Solucion:** Al declarar `PRAGMA AUTONOMOUS_TRANSACTION`, el procedimiento de log abre una transaccion hija e independiente que hace su propio `COMMIT` y se cierra, permitiendo que el error quede grabado en la base de datos aunque la transaccion padre sea revertida.
