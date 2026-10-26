---
tags:
  - taller-bd
  - pl-sql
  - unidad-2
  - defensa-oral
  - preguntas-respuestas
  - ep2
aliases:
  - Banco de Preguntas Defensa EP2
  - Guia Rapida de Repaso Unidad 2
created: 2026-10-14
---

# 04 - Guia Rapida y Banco de Preguntas para Defensa EP2

Este documento recopila las definiciones conceptuales indispensables y las preguntas tecnicas mas frecuentes que realiza el cuerpo docente en la evaluacion de la **Unidad 2 (Evaluacion Parcial 2)** de Taller de Base de Datos (BDY1103).

---

## 1. Glosario Tecnico Esencial (Dominio de Conceptos)

1. **Subprograma Almacenado:** Objeto compilado con nombre que reside en el catalogo de la base de datos (procedimiento o funcion). Acepta parametros y puede ser ejecutado por multiples usuarios concurrentes con los permisos adecuados.
2. **Package Specification (Especificacion):** Interfaz publica obligatoria del paquete. Declara constantes, tipos, cursores, excepciones y cabeceras de subprogramas visibles para el exterior.
3. **Package Body (Cuerpo):** Contenedor de la implementacion de la logica. Opcional si la especificacion solo contiene constantes, pero obligatorio cuando se definen procedimientos o funciones.
4. **Subprograma Privado:** Procedimiento o funcion declarado e implementado unicamente dentro del `PACKAGE BODY`, sin presencia en la especificacion. No puede ser invocado desde fuera del paquete, garantizando encapsulamiento.
5. **Row-Level Trigger (Disparador de Fila):** Se define con la clausula `FOR EACH ROW`. Se ejecuta una vez por cada registro individual que sea modificado, insertado o eliminado por la sentencia DML. Tiene acceso a `:OLD` y `:NEW`.
6. **Statement-Level Trigger (Disparador de Sentencia):** Disparador por defecto (sin `FOR EACH ROW`). Se ejecuta exactamente una vez por cada sentencia DML emitida, sin importar si afecto a cero, una o diez mil filas. No tiene acceso a pseudocolumnas de fila.
7. **Pseudocolumnas `:OLD` y `:NEW`:** Estructuras de datos que representan el estado anterior y posterior de los campos de la fila afectada en un trigger de fila. En `INSERT`, `:OLD` es nulo; en `DELETE`, `:NEW` es nulo; en `UPDATE`, ambas estan disponibles.
8. **RAISE_APPLICATION_ERROR:** Procedimiento del paquete `DBMS_STANDARD` que permite al desarrollador abortar una transaccion y devolver un codigo de error personalizado (en el rango de `-20000` a `-20999`) junto con un mensaje descriptivo al cliente.
9. **PRAGMA AUTONOMOUS_TRANSACTION:** Directiva del compilador que suspende la transaccion principal y ejecuta el bloque actual dentro de una transaccion independiente con su propio ciclo de `COMMIT` o `ROLLBACK`.
10. **Error ORA-04091 (Mutating Table):** Error que se produce cuando un trigger a nivel de fila intenta consultar o modificar la misma tabla que esta sufriendo la operacion DML activa.

---

## 2. Banco de Preguntas y Respuestas para la Evaluacion Oral

### P1: ¿Cual es la diferencia fundamental entre una Funcion y un Procedimiento Almacenado?
**Respuesta:** Una funcion almacena una logica orientada al calculo o transformacion de datos y esta obligada a retornar un unico valor mediante la instruccion `RETURN`. Por esta razon, las funciones pueden ser invocadas directamente dentro de sentencias SQL (`SELECT`, `WHERE`, `ORDER BY`). Un procedimiento, en cambio, esta disenado para ejecutar operaciones transaccionales o tareas de mantenimiento masivas (`INSERT`, `UPDATE`, `DELETE`); no retorna un valor directamente en su nombre, aunque puede devolver multiples resultados utilizando parametros de salida (`OUT` o `IN OUT`).

---

### P2: ¿Que ventajas ofrece utilizar un Package en lugar de procedimientos y funciones sueltas?
**Respuesta:** Las principales ventajas son tres:
1. **Modularidad y Mantenibilidad:** Agrupa logicamente todos los subprogramas relacionados con un dominio de negocio (en nuestro caso, `PKG_SONIDO_VIVO` gestiona clientes, precios y liquidaciones en un solo artefacto).
2. **Encapsulamiento y Ocultamiento de Informacion:** Permite definir subprogramas privados (como `sp_registrar_log_interno`) a los que solo el propio paquete tiene acceso, protegiendo las tablas criticas de manipulaciones externas directas.
3. **Rendimiento:** La primera vez que se invoca cualquier elemento del paquete, Oracle carga el paquete completo en la memoria compartida (`Shared Pool`). Las llamadas subsiguientes a cualquier funcion o procedimiento del paquete no requieren lectura de disco, reduciendo drsticamente los tiempos de respuesta.

---

### P3: ¿Por que es necesario usar `BEFORE INSERT` para el control de stock y no `AFTER INSERT`?
**Respuesta:** Porque el objetivo del control de inventario es **preventivo**. Si usaramos `AFTER INSERT`, la fila de la venta ya se habria insertado en `DETALLE_VENTA` antes de comprobar si existia mercaderia fisica suficiente. Al usar `BEFORE INSERT`, evaluamos la condicion antes de persistir la fila; si el stock disponible en `PRODUCTO` es menor al solicitado, ejecutamos `RAISE_APPLICATION_ERROR`, lo cual cancela la operacion inmediatamente, evita el ingreso del registro invalido y previene inconsistencias en la base de datos.

---

### P4: ¿Como justificas que tu trigger de stock no genere el error de Tabla Mutante (`ORA-04091`)?
**Respuesta:** El error `ORA-04091` ocurre exclusivamente cuando un trigger a nivel de fila intenta leer o alterar la misma tabla que esta en proceso de modificacion por la sentencia que disparo el trigger. En nuestra arquitectura, el trigger `TRG_VALIDA_STOCK_VENTA` esta asociado a la tabla `DETALLE_VENTA`, mientras que la consulta y actualizacion de stock se realiza sobre una tabla diferente: `PRODUCTO`. Como la tabla `PRODUCTO` no esta mutando durante el evento de insercion en `DETALLE_VENTA`, Oracle no bloquea la operacion y no existe riesgo de tabla mutante.

---

### P5: ¿Para que sirve `PRAGMA AUTONOMOUS_TRANSACTION` y donde lo implementaste?
**Respuesta:** Lo implementamos en el procedimiento privado `sp_registrar_log_interno` dentro del cuerpo de `PKG_SONIDO_VIVO`. Sirve para desvincular el registro de errores de la transaccion principal. Si el procedimiento de liquidacion o reajuste falla y ejecuta un `ROLLBACK`, la directiva autonoma garantiza que el `INSERT` en la tabla `LOG_ERRORES` se confirme de forma independiente con su propio `COMMIT`. Sin esta directiva, el `ROLLBACK` de la transaccion principal borraria tambien la evidencia del error, dejando al equipo de administracion a ciegas frente a las fallas operativas.

---

## 3. Checklist de Comprobacion en Consola (Oracle SQL Developer)

Antes de la presentacion, ejecutar estas pruebas para certificar que todos los objetos responden:

```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;

-- Prueba 1: Validar compilacion de objetos
SELECT object_name, object_type, status 
FROM user_objects 
WHERE object_name IN ('PKG_SONIDO_VIVO', 'TRG_VALIDA_STOCK_VENTA', 'TRG_AUDIT_PRECIO_PRODUCTO')
ORDER BY object_type;
-- Todos deben mostrar STATUS = 'VALID'

-- Prueba 2: Validar calculo de descuento
SELECT PKG_SONIDO_VIVO.fn_calcular_descuento('VIP', 600000) AS tasa_vip FROM dual;
-- Debe retornar 0.15

-- Prueba 3: Probar trigger de auditoria de precios
UPDATE PRODUCTO SET precio = precio + 1000 WHERE id_producto = 1;
SELECT * FROM AUDIT_PRECIOS_PRODUCTO ORDER BY fecha_modifica DESC;
-- Debe mostrar la fila con el precio anterior, precio nuevo y la variacion porcentual

-- Prueba 4: Probar disparo de error por stock insuficiente
-- Si el producto 1 tiene stock 10, intentar insertar 999 unidades:
-- INSERT INTO DETALLE_VENTA (id_detalle, id_venta, id_producto, cantidad, precio_unitario, subtotal)
-- VALUES (SEQ_DETALLE_VENTA.NEXTVAL, 1, 1, 999, 100000, 99900000);
-- Debe arrojar: ORA-20001: OPERACION CANCELADA: Stock insuficiente...
```
