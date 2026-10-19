---
tags:
  - taller-bd
  - pl-sql
  - unidad-2
  - guia-estudio
  - ep2
aliases:
  - Indice Estudio Unidad 2
  - Guia de Estudio BDY1103 Unidad 2
created: 2026-10-14
---

# Indice Maestro: Material de Estudio Unidad 2 (Transicion desde Unidad 1)

**Asignatura:** Taller de Base de Datos (BDY1103)  
**Institucion:** Duoc UC  
**Proyecto:** Sonido Vivo — Tienda de Instrumentos Musicales y Audio Profesional  
**Objetivo del Dossier:** Comprender en profundidad la evolucion tecnologica y arquitectonica desde los bloques anonimos de la Unidad 1 hacia los subprogramas almacenados permanentes (Packages, Procedimientos, Funciones) y automatizaciones reactivas (Triggers de fila y sentencia) de la Unidad 2.

---

## Estructura del Material de Estudio

Este conjunto de apuntes conecta directamente el trabajo realizado en la Evaluacion Parcial 1 con los requerimientos de la Evaluacion Parcial 2:

1. [[Taller Base de Datos (PL-SQL)/Material de Estudio Unidad 2/01 - Matriz de Transición de Unidad 1 a Unidad 2|01 - Matriz de Transición de Unidad 1 a Unidad 2]]
   - Comparativa conceptual y de ciclo de vida: Bloques anonimos vs Subprogramas almacenados.
   - Tabla de equivalencias directa entre los scripts de Unidad 1 y los artefactos de Unidad 2.
   - Ventajas en rendimiento, I/O, encapsulamiento y seguridad.

2. [[Taller Base de Datos (PL-SQL)/Material de Estudio Unidad 2/02 - Del Bloque RECORD y VARRAY al Package Modular|02 - Del Bloque RECORD y VARRAY al Package Modular]]
   - Analisis del bloque `02_bloque_record_varray.sql` y `03_bloque_cursores_anidados.sql`.
   - Como se refactoriza la liquidacion de clientes en funciones publicas (`fn_calcular_descuento`) y procedimientos masivos (`sp_liquidar_clientes`).
   - Anatomia del Package `PKG_SONIDO_VIVO`: Especificacion (interfaz publica) vs Cuerpo (implementacion y constructores privados).

3. [[Taller Base de Datos (PL-SQL)/Material de Estudio Unidad 2/03 - Del Manejo de Excepciones a Triggers y Auditoria Autonoma|03 - Del Manejo de Excepciones a Triggers y Auditoria Autonoma]]
   - Analisis del bloque `04_bloque_excepciones.sql` y `05_triggers_propuestos.sql`.
   - Transicion de la validacion manual de stock a la validacion automatica con Trigger de Fila (`BEFORE INSERT ON DETALLE_VENTA`) con `RAISE_APPLICATION_ERROR`.
   - Auditoria automatica de variaciones de precios (`AFTER UPDATE OF precio ON PRODUCTO`) hacia la tabla `AUDIT_PRECIOS_PRODUCTO`.
   - El patron `PRAGMA AUTONOMOUS_TRANSACTION` para blindar el registro de errores en `LOG_ERRORES`.
   - Como prevenir y justificar la Tabla Mutante (`ORA-04091`).

4. [[Taller Base de Datos (PL-SQL)/Material de Estudio Unidad 2/04 - Guia Rapida y Banco de Preguntas para Defensa EP2|04 - Guia Rapida y Banco de Preguntas para Defensa EP2]]
   - Resumen ejecutivo de terminos clave para la defensa oral ante el docente.
   - Banco de preguntas frecuentes y respuestas tecnicas precisas (Publico vs Privado, Fila vs Sentencia, Transaccion Autonoma, ORA-04091).
   - Diagrama de flujo de ejecucion de la arquitectura integrada.

---

## Ubicacion de los Scripts Fuente Relacionados

- **Scripts de Unidad 1:** En el repositorio local dentro de `unidad 1/scripts/`
  - `01_esquema_y_datos.sql`: Esquema relacional DDL/DML.
  - `02_bloque_record_varray.sql`: Bloque anonimo RECORD y VARRAY.
  - `03_bloque_cursores_anidados.sql`: Cursores explicitos anidados con parametros.
  - `04_bloque_excepciones.sql`: Excepciones predefinidas y de usuario.
  - `05_triggers_propuestos.sql`: Disparadores base preliminares.
- **Artefactos de Unidad 2:** En el repositorio local dentro de `unidad 2/scripts/`
  - `06_paquetes_y_triggers_unidad2.sql`: Implementacion completa de `PKG_SONIDO_VIVO`, triggers de fila y sentencia, y tabla de auditoria.
