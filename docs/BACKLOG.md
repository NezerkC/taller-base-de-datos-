# Product Backlog & Tablero Kanban

## Proyecto: Sonido Vivo — Motor de Liquidación y Auditoría PL/SQL
**Metodología:** Agile / Scrum  
**Sprint:** Sprint 1 — Entrega y Defensa Evaluación Parcial N° 1  
**Objetivo del Sprint:** Implementar el esquema relacional, los bloques anónimos PL/SQL requeridos por la rúbrica y generar los entregables formales (Informe Técnico y Diapositivas de Presentación).

---

## Tablero Kanban

```text
+------------------------------------+-----------------------------+------------------------------------+
|            TO DO (Por Hacer)       |       IN PROGRESS (En Curso)|          DONE (Finalizado)         |
+------------------------------------+-----------------------------+------------------------------------+
|                                    |                             | [SV-00] PRD & Requerimientos       |
|                                    |                             | [SV-01] Modelo Relacional & DDL/DML|
|                                    |                             | [SV-02] Bloque RECORD & VARRAY     |
|                                    |                             | [SV-03] Cursores Parametrizados    |
|                                    |                             | [SV-04] Control de Excepciones     |
|                                    |                             | [SV-05] Informe Técnico Formal     |
|                                    |                             | [SV-06] Guión y Presentación Oral  |
+------------------------------------+-----------------------------+------------------------------------+
```

---

## Épicas e Historias de Usuario

### ÉPICA 1: Persistencia y Modelo Relacional de Sonido Vivo
#### Historia de Usuario: `[SV-01]` Modelo de Datos y Carga Inicial
- **Como:** Administrador de base de datos de Sonido Vivo.
- **Quiero:** Un esquema DDL relacional (`CREATE TABLE`) y scripts DML de carga (`INSERT`).
- **Para:** Disponer de una base de datos operativa con categorías, productos, clientes y ventas reales del catálogo.
- **Criterios de Aceptación:**
  1. Definir tablas: `CATEGORIA`, `PRODUCTO`, `CLIENTE`, `VENTA`, `DETALLE_VENTA`, `LIQUIDACION_CLIENTE`, `LOG_ERRORES`.
  2. Implementar constraints (PK, FK, CHECK para stock >= 0 y precios > 0).
  3. Cargar al menos 5 categorías, 10 productos reales (tomados de `catalogo.js`) y 5 transacciones de prueba con múltiples líneas de detalle.
- **Estimación:** 3 Story Points  
- **Prioridad:** Bloqueante / Alta  

---

### ÉPICA 2: Procesamiento Transaccional en PL/SQL (Rúbrica EP1)
#### Historia de Usuario: `[SV-02]` Procesamiento Compuesto con RECORD y VARRAY (IE1.1.1)
- **Como:** Analista de Operaciones Comerciales.
- **Quiero:** Un bloque anónimo PL/SQL que procese ventas aplicando tasas de bonificación en memoria.
- **Para:** Evaluar promociones por volumen y consolidar los montos brutos, descuentos y netos sin saturar I/O.
- **Criterios de Aceptación:**
  1. Declarar un tipo `TYPE t_rec_liquidacion IS RECORD` para contener el resumen de cálculo.
  2. Declarar un tipo colección `TYPE t_arr_tasas IS VARRAY(4) OF NUMBER` para definir las escalas de descuento por tramo de compra.
  3. Ejecutar el procesamiento y poblar la tabla `LIQUIDACION_CLIENTE` mostrando salida vía `DBMS_OUTPUT`.
- **Estimación:** 5 Story Points  
- **Prioridad:** Alta  

#### Historia de Usuario: `[SV-03]` Cursores Explícitos Complejos con Parámetros y Bucles Anidados (IE1.2.1)
- **Como:** Jefe de Finanzas y Ventas.
- **Quiero:** Un bloque anónimo PL/SQL que recorra las ventas de cada cliente mediante cursores anidados coordinados.
- **Para:** Generar el desglose detallado de cada orden y actualizar el estado de procesamiento.
- **Criterios de Aceptación:**
  1. Cursor principal (`c_clientes`) que seleccione clientes con transacciones registradas.
  2. Cursor secundario con parámetros (`c_detalle(p_id_cliente NUMBER)`) que consulte items, cantidades y subtotales.
  3. Anidar los loops (`FOR` o `WHILE` / `LOOP` explícito con `%NOTFOUND`) sincronizando la jerarquía padre-hijo.
  4. Realizar actualización o inserción de totales procesados.
- **Estimación:** 5 Story Points  
- **Prioridad:** Alta  

#### Historia de Usuario: `[SV-04]` Sistema de Gestión de Excepciones Oracle y de Usuario (IE1.3.1)
- **Como:** Ingeniero de Confiabilidad de Datos.
- **Quiero:** Capturar anomalías operativas mediante excepciones predefinidas y personalizadas.
- **Para:** Prevenir inconsistencias en stock o ventas inválidas y auditar los incidentes en `LOG_ERRORES`.
- **Criterios de Aceptación:**
  1. Manejo de excepciones predefinidas de Oracle (`NO_DATA_FOUND`, `ZERO_DIVIDE`).
  2. Declaración y disparo de excepciones de usuario (`e_stock_critico_excedido`, `e_venta_vacia`) usando `RAISE`.
  3. Inserción de incidentes capturados en la tabla `LOG_ERRORES` con `SQLCODE` y `SQLERRM`.
- **Estimación:** 5 Story Points  
- **Prioridad:** Alta  

---

### ÉPICA 3: Documentación Formal y Entrega Académica (Ponderación 100%)
#### Historia de Usuario: `[SV-05]` Elaboración del Informe Técnico Formal (40% de la nota)
- **Como:** Estudiante evaluado en BDY1103.
- **Quiero:** El documento de informe técnico estructurado exactamente según las secciones requeridas en la pauta.
- **Para:** Obtener el 100% de logro en los indicadores IE1.1.1, IE1.2.1, IE1.3.1 e IE1.4.1.
- **Criterios de Aceptación:**
  1. Portada, Introducción, Contexto y Alcance del proyecto Sonido Vivo.
  2. Explicación teórica y técnica con capturas/diagramas de `RECORD` y `VARRAY`.
  3. Explicación y justificación de cursores explícitos con parámetros y loops anidados.
  4. Detalle del control de excepciones predefinidas y definidas por el usuario.
  5. Evaluación prospectiva de `PROCEDURE`, `FUNCTION`, `PACKAGE` y `TRIGGER` en la arquitectura futura.
  6. Conclusiones y Anexo con código SQL/PLSQL completo.
- **Estimación:** 8 Story Points  
- **Prioridad:** Crítica  

#### Historia de Usuario: `[SV-06]` Guión Ejecutivo y Soporte para Presentación (60% de la nota)
- **Como:** Estudiante defendiendo el proyecto.
- **Quiero:** La estructura de presentación ejecutiva y guión de defensa oral.
- **Para:** Responder a cada criterio de evaluación individual con solvencia y precisión técnica.
- **Criterios de Aceptación:**
  1. Estructura diapositiva por diapositiva (Problema, Datos, RECORD/VARRAY, Cursores, Excepciones, Paquetes/Triggers, Conclusión).
  2. Guión con argumentos técnicos clave para justificar el porqué de cada decisión técnica.
- **Estimación:** 5 Story Points  
- **Prioridad:** Crítica  
