---
tags:
  - taller-bd
  - pl-sql
  - unidad-2
  - packages
  - refactorizacion
aliases:
  - De Bloques RECORD y VARRAY a Packages
  - Refactorizacion PKG_SONIDO_VIVO
created: 2026-10-14
---

# 02 - Del Bloque RECORD y VARRAY al Package Modular

En esta guia se analiza paso a paso como la logica programada en los bloques anonimos de la Unidad 1 (`02_bloque_record_varray.sql` y `03_bloque_cursores_anidados.sql`) se refactoriza y consolida dentro del paquete modular **`PKG_SONIDO_VIVO`**.

---

## 1. El Codigo Origen en la Unidad 1

### A. Fragmento de `02_bloque_record_varray.sql`
En la Unidad 1, se declaraban tipos en memoria volatil para calcular tramos de descuento y almacenar temporalmente una liquidacion:

```sql
-- Codigo Unidad 1 (Bloque Anonimo)
DECLARE
    TYPE t_rec_liquidacion IS RECORD (
        id_cliente       CLIENTE.id_cliente%TYPE,
        nombre_cliente   VARCHAR2(100),
        monto_compras    NUMBER(12),
        tasa_descuento   NUMBER(4, 2),
        monto_descuento  NUMBER(12),
        monto_final      NUMBER(12)
    );
    TYPE t_arr_tasas IS VARRAY(4) OF NUMBER(4, 2);
    v_tasas t_arr_tasas := t_arr_tasas(0.00, 0.05, 0.10, 0.15);
    v_resumen t_rec_liquidacion;
BEGIN
    -- Logica de calculo que solo existia mientras corria el script
    NULL;
END;
/
```

### B. Fragmento de `03_bloque_cursores_anidados.sql`
Para procesar las compras de cada cliente, se utilizaban dos cursores explicitos coordinados con paso de parametros:

```sql
-- Codigo Unidad 1 (Bloque Anonimo)
DECLARE
    CURSOR c_clientes IS
        SELECT id_cliente, nombre || ' ' || apellido AS nombre_completo, tipo_cliente
        FROM CLIENTE ORDER BY id_cliente;

    CURSOR c_detalle_ventas (cp_id_cliente NUMBER) IS
        SELECT v.id_venta, v.total_neto, v.fecha_venta
        FROM VENTA v
        WHERE v.id_cliente = cp_id_cliente;
BEGIN
    FOR r_cli IN c_clientes LOOP
        FOR r_det IN c_detalle_ventas(r_cli.id_cliente) LOOP
            -- Acumulacion manual de totales
            NULL;
        END LOOP;
    END LOOP;
END;
/
```

**Problema en la Unidad 1:** Si otro modulo de la tienda o un sistema externo necesitaba calcular el descuento de un cliente, tenia que volver a escribir toda esa logica desde cero.

---

## 2. La Transformacion a Subprogramas en la Unidad 2

En la Unidad 2, desacoplamos la logica en dos artefactos reutilizables:

1. **La Calculadora (`fn_calcular_descuento`):** Funcion pura que recibe `tipo_cliente` y `monto_compra` y devuelve la tasa decimal. Puede usarse tanto en sentencias `SELECT` de SQL como dentro de bloques PL/SQL.
2. **El Procesador Transaccional (`sp_liquidar_clientes`):** Procedimiento que encapsula el cursor agrupado, invoca la funcion calculadora para cada cliente e inserta el resultado consolidado en la tabla `LIQUIDACION_CLIENTE` bajo control transaccional (`COMMIT` / `ROLLBACK`).

---

## 3. Estructura y Encapsulamiento del Package `PKG_SONIDO_VIVO`

El Package resuelve la modularizacion separando la interfaz de la implementacion:

### A. Especificacion (`PACKAGE` - Interfaz Publica)
Es el contrato visible para los programadores, administradores y aplicaciones externas.

```sql
CREATE OR REPLACE PACKAGE PKG_SONIDO_VIVO AS

    -- Constantes Publicas de Negocio
    c_iva_tasa       CONSTANT NUMBER(4, 2) := 0.19;
    c_desc_maximo    CONSTANT NUMBER(4, 2) := 0.25;

    -- Funciones Publicas
    FUNCTION fn_validar_email(
        p_email IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION fn_calcular_descuento(
        p_tipo_cliente IN VARCHAR2,
        p_monto_compra IN NUMBER
    ) RETURN NUMBER;

    -- Procedimientos Publicos
    PROCEDURE sp_reajustar_precios(
        p_porcentaje IN NUMBER,
        p_filas_afectadas OUT NUMBER
    );

    PROCEDURE sp_liquidar_clientes(
        p_periodo IN VARCHAR2,
        p_total_procesados OUT NUMBER
    );

END PKG_SONIDO_VIVO;
/
```

### B. Cuerpo (`PACKAGE BODY` - Logica Interna y Metodos Privados)
Aqui reside la implementacion real de cada funcion y procedimiento.

**Aspecto Critico de Arquitectura (Constructores Privados):**
En el cuerpo se declara el procedimiento `sp_registrar_log_interno`. Al no figurar en la especificacion (`PACKAGE`), es **privado e invisible** para cualquier usuario exterior. Solo los subprogramas que estan dentro del mismo paquete pueden ejecutarlo.

```sql
CREATE OR REPLACE PACKAGE BODY PKG_SONIDO_VIVO AS

    -- Subprograma Privado (Solo accesible internamente)
    PROCEDURE sp_registrar_log_interno(
        p_codigo_error  IN VARCHAR2,
        p_mensaje_error IN VARCHAR2,
        p_subprograma   IN VARCHAR2
    ) IS
        PRAGMA AUTONOMOUS_TRANSACTION;
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
            p_codigo_error,
            SUBSTR(p_mensaje_error, 1, 400),
            'PKG_SONIDO_VIVO.' || p_subprograma,
            USER,
            SYSDATE
        );
        COMMIT;
    END sp_registrar_log_interno;

    -- Implementacion de fn_calcular_descuento
    FUNCTION fn_calcular_descuento(
        p_tipo_cliente IN VARCHAR2,
        p_monto_compra IN NUMBER
    ) RETURN NUMBER IS
        v_tasa NUMBER(4, 2) := 0.0;
    BEGIN
        IF UPPER(p_tipo_cliente) = 'VIP' THEN
            IF p_monto_compra >= 500000 THEN
                v_tasa := 0.15;
            ELSE
                v_tasa := 0.10;
            END IF;
        ELSIF UPPER(p_tipo_cliente) = 'FRECUENTE' THEN
            IF p_monto_compra >= 300000 THEN
                v_tasa := 0.08;
            ELSE
                v_tasa := 0.05;
            END IF;
        ELSE
            IF p_monto_compra >= 1000000 THEN
                v_tasa := 0.05;
            ELSE
                v_tasa := 0.0;
            END IF;
        END IF;

        RETURN v_tasa;
    END fn_calcular_descuento;

    -- Implementacion de sp_liquidar_clientes (Reemplaza a los cursores anidados U1)
    PROCEDURE sp_liquidar_clientes(
        p_periodo IN VARCHAR2,
        p_total_procesados OUT NUMBER
    ) IS
        CURSOR c_resumen IS
            SELECT 
                v.id_cliente,
                c.tipo_cliente,
                SUM(v.total_neto) AS monto_acumulado
            FROM VENTA v
            JOIN CLIENTE c ON v.id_cliente = c.id_cliente
            WHERE TO_CHAR(v.fecha_venta, 'YYYY-MM') = p_periodo
            GROUP BY v.id_cliente, c.tipo_cliente;

        v_tasa       NUMBER(4, 2);
        v_descuento  NUMBER(10);
        v_neto_final NUMBER(10);
        v_contador   NUMBER := 0;
    BEGIN
        FOR reg IN c_resumen LOOP
            v_tasa := fn_calcular_descuento(reg.tipo_cliente, reg.monto_acumulado);
            v_descuento := ROUND(reg.monto_acumulado * v_tasa);
            v_neto_final := reg.monto_acumulado - v_descuento;

            INSERT INTO LIQUIDACION_CLIENTE (
                id_liquidacion,
                id_cliente,
                periodo,
                total_compras,
                porc_descuento,
                monto_descuento,
                monto_final,
                fecha_liquidacion
            ) VALUES (
                SEQ_LIQUIDACION.NEXTVAL,
                reg.id_cliente,
                p_periodo,
                reg.monto_acumulado,
                v_tasa * 100,
                v_descuento,
                v_neto_final,
                SYSDATE
            );
            v_contador := v_contador + 1;
        END LOOP;

        p_total_procesados := v_contador;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_total_procesados := 0;
            sp_registrar_log_interno('ERR-LIQUIDACION', SQLERRM, 'sp_liquidar_clientes');
            RAISE;
    END sp_liquidar_clientes;

    -- Implementacion de sp_reajustar_precios
    PROCEDURE sp_reajustar_precios(
        p_porcentaje IN NUMBER,
        p_filas_afectadas OUT NUMBER
    ) IS
        v_factor NUMBER;
    BEGIN
        IF p_porcentaje < -50 OR p_porcentaje > 100 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Porcentaje de reajuste fuera de rango permitido (-50% a +100%).');
        END IF;

        v_factor := 1 + (p_porcentaje / 100);

        UPDATE PRODUCTO
        SET precio = ROUND(precio * v_factor);

        p_filas_afectadas := SQL%ROWCOUNT;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            p_filas_afectadas := 0;
            sp_registrar_log_interno('ERR-REAJUSTE-PRECIOS', SQLERRM, 'sp_reajustar_precios');
            RAISE;
    END sp_reajustar_precios;

    -- Implementacion de fn_validar_email
    FUNCTION fn_validar_email(
        p_email IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        IF REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            sp_registrar_log_interno('ERR-VAL-MAIL', SQLERRM, 'fn_validar_email');
            RETURN 0;
    END fn_validar_email;

END PKG_SONIDO_VIVO;
/
```

---

## 4. Como Probar la Invocacion desde SQL Developer

Para verificar que el paquete quedo correctamente compilado y operativo:

```sql
-- 1. Probar la funcion en una consulta SQL directa
SELECT 
    nombre, 
    tipo_cliente, 
    PKG_SONIDO_VIVO.fn_calcular_descuento(tipo_cliente, 550000) AS tasa_descuento
FROM CLIENTE;

-- 2. Probar el procedimiento de reajuste de precios (aumento del 5%)
DECLARE
    v_filas NUMBER;
BEGIN
    PKG_SONIDO_VIVO.sp_reajustar_precios(5, v_filas);
    DBMS_OUTPUT.PUT_LINE('Total productos actualizados: ' || v_filas);
END;
/

-- 3. Probar la liquidacion del periodo actual
DECLARE
    v_total NUMBER;
BEGIN
    PKG_SONIDO_VIVO.sp_liquidar_clientes('2026-10', v_total);
    DBMS_OUTPUT.PUT_LINE('Total clientes liquidados: ' || v_total);
END;
/
```
