---
tags:
  - taller-bd
  - pl-sql
  - unidad-2
  - arquitectura
  - transicion
aliases:
  - Matriz de Transicion U1 a U2
  - Comparativa Bloques Anonimos vs Subprogramas Almacenados
created: 2026-10-14
---

# 01 - Matriz de Transicion de Unidad 1 a Unidad 2

Esta guia establece el puente conceptual y tecnico entre la **Unidad 1** (programacion procedural en memoria mediante bloques anonimos) y la **Unidad 2** (arquitectura modular basada en objetos almacenados y automatizaciones reactivas).

---

## 1. El Salto Arquitectonico: Bloques Anonimos vs Programas Almacenados

| Criterio de Comparacion | Unidad 1: Bloques Anonimos | Unidad 2: Programas Almacenados (Packages / Triggers) |
| :--- | :--- | :--- |
| **Persistencia** | Volatil: Vive en el archivo `.sql` del cliente. No se almacena en el diccionario de datos. | Permanente: Reside compilado en el diccionario de datos de Oracle (`USER_SOURCE`, `USER_OBJECTS`). |
| **Ciclo de Compilacion** | Compilacion e interpretacion cada vez que se presiona "Ejecutar" en SQL Developer. | Se compila una sola vez (`CREATE OR REPLACE`) y se almacena en formato p-code ejecutable. |
| **Reutilizacion** | Nula: Debe copiarse y pegarse el bloque o ejecutarse el archivo completo a mano. | Alta: Cualquier sesion, procedimiento, aplicacion web o script puede invocar el subprograma por su nombre. |
| **Trafico de Red (I/O)** | Alto: Cada bloque anonimo viaja completo por la red desde la estacion cliente hacia el servidor de base de datos. | Minimo: Solo viaja la instruccion de invocacion (`EXEC pkg.sp(...)`) con sus parametros; la logica corre en el servidor. |
| **Encapsulamiento** | Inexistente: Todas las variables y tipos declarados son visibles en todo el bloque. | Estricto: Division formal entre interfaz publica (`PACKAGE`) y logica interna privada (`PACKAGE BODY`). |
| **Mecanismo de Disparo** | Exclusivamente manual: Requiere una accion humana explicita en la consola. | Hibrido: Invocacion manual (Procedimientos/Funciones) o automatica reactiva ante eventos DML (Triggers). |

---

## 2. Mapa de Equivalencias Directas: De Unidad 1 a Unidad 2

A continuacion se detalla como cada bloque desarrollado en la Evaluacion Parcial 1 se refactoriza y madura dentro del diseno de la Evaluacion Parcial 2:

```text
+--------------------------------------------------+       +--------------------------------------------------+
|               UNIDAD 1 (SCRIPTS U1)              |       |               UNIDAD 2 (ARTEFACTOS U2)           |
+--------------------------------------------------+       +--------------------------------------------------+
| 01_esquema_y_datos.sql                           | ====> | Esquema base + Tabla AUDIT_PRECIOS_PRODUCTO      |
| (Tablas relacionales y datos iniciales)          |       | (Estructuras de soporte para auditoria reactiva) |
+--------------------------------------------------+       +--------------------------------------------------+
| 02_bloque_record_varray.sql                      | ====> | PKG_SONIDO_VIVO.fn_calcular_descuento            |
| (Calculo de tasas y descuentos en memoria)       |       | (Funcion publica con retorno de tasa porcentual) |
+--------------------------------------------------+       +--------------------------------------------------+
| 03_bloque_cursores_anidados.sql                  | ====> | PKG_SONIDO_VIVO.sp_liquidar_clientes             |
| (Recorrido de clientes y compras acumuladas)     |       | (Procedimiento masivo de liquidacion mensual)    |
+--------------------------------------------------+       +--------------------------------------------------+
| Reajuste manual de precios (DML suelto)          | ====> | PKG_SONIDO_VIVO.sp_reajustar_precios             |
| (Sentencias UPDATE aisladas en SQL Developer)    |       | (Procedimiento masivo parametrizado con control) |
+--------------------------------------------------+       +--------------------------------------------------+
| 04_bloque_excepciones.sql                        | ====> | PKG_SONIDO_VIVO.sp_registrar_log_interno         |
| (Captura de errores e insercion en LOG_ERRORES)  |       | (Subprograma privado con AUTONOMOUS TRANSACTION) |
+--------------------------------------------------+       +--------------------------------------------------+
| 05_triggers_propuestos.sql                       | ====> | Suite de Triggers de Produccion:                 |
| (Disparadores base preliminares)                 |       | - TRG_VALIDA_STOCK_VENTA (Before Row)            |
|                                                  |       | - TRG_AUDIT_PRECIO_PRODUCTO (After Row)          |
|                                                  |       | - TRG_CONTROL_OPERACION_VENTAS (Statement)       |
+--------------------------------------------------+       +--------------------------------------------------+
```

---

## 3. Justificacion Tecnica para la Evaluacion Docente

Al defender esta evolucion ante el profesor, los tres argumentos clave son:

1. **Eficiencia y Caching:** Los subprogramas de la Unidad 2 se compilan a codigo de bytes (p-code) y se cargan en la `Shared Pool` (SGA) de Oracle. Si diez clientes invocan `PKG_SONIDO_VIVO.fn_calcular_descuento`, todos comparten la misma copia compilada en memoria, reduciendo radicalmente el consumo de CPU.
2. **Seguridad y Principio de Menor Privilegio:** En la Unidad 1, para que un usuario registre liquidaciones, debia tener permisos directos de `INSERT` sobre `LIQUIDACION_CLIENTE` y `LOG_ERRORES`. En la Unidad 2, el usuario solo necesita permiso `EXECUTE` sobre `PKG_SONIDO_VIVO`, ocultando la estructura interna de las tablas y protegiendo la base de datos contra accesos no autorizados.
3. **Automatizacion Transaccional Indestructible:** Con los Triggers de la Unidad 2, la regla de "no vender sin stock disponible" no depende de si el programador de frontend o backend se acordo de validar; la propia base de datos rechaza la operacion mediante `RAISE_APPLICATION_ERROR` independientemente de donde provenga la peticion.
