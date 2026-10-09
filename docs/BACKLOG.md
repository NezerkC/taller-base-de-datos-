# Product Backlog & Tablero Kanban

## Proyecto: Sonido Vivo — Motor de Liquidación, Paquetes y Triggers PL/SQL
**Metodología:** Agile / Scrum  
**Sprint Actual:** Sprint 2 — Arquitectura Modular PL/SQL (Packages, Triggers y Oracle APEX)  
**Objetivo del Sprint:** Evolucionar la arquitectura de Sonido Vivo a subprogramas almacenados permanentes en base de datos (`PACKAGE`), implementar reglas de negocio automáticas (`TRIGGERS`) e integrar la capa de presentación con Oracle APEX para la Evaluación Parcial N° 2 (40%).

---

## Tablero Kanban

```text
+------------------------------------+-----------------------------+------------------------------------+
|            TO DO (Por Hacer)       |       IN PROGRESS (En Curso)|          DONE (Finalizado)         |
+------------------------------------+-----------------------------+------------------------------------+
| [SV-08] Triggers Fila & Sentencia  | [SV-07] Package PKG_SONIDO_ | [SV-00] PRD & Requerimientos       |
| [SV-09] Integración Oracle APEX    |         VIVO (Spec & Body)  | [SV-01] Modelo Relacional & DDL/DML|
| [SV-10] Informe Técnico Formal EP2 |                             | [SV-02] Bloque RECORD & VARRAY     |
| [SV-11] Presentación Oral EP2      |                             | [SV-03] Cursores Parametrizados    |
|                                    |                             | [SV-04] Control de Excepciones     |
|                                    |                             | [SV-05] Informe Técnico Formal EP1 |
|                                    |                             | [SV-06] Guión y Presentación EP1   |
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

---

### ÉPICA 4: Modularización Empresarial con Packages (Rúbrica EP2 - IL2.1 & IL2.2)
#### Historia de Usuario: `[SV-07]` Construcción e Integración de PKG_SONIDO_VIVO
- **Como:** Arquitecto de Base de Datos.
- **Quiero:** Un paquete modular con especificación (`PACKAGE`) y cuerpo (`PACKAGE BODY`) que agrupe funciones de cálculo y procedimientos de procesamiento masivo.
- **Para:** Encapsular la lógica de negocio, optimizar el rendimiento en el servidor y permitir su reutilización en sentencias SQL y aplicaciones externas.
- **Criterios de Aceptación:**
  1. **Especificación pública:**
     - Declaración de constantes de negocio (ej. IVA, tasas base).
     - Función `fn_calcular_descuento`: calcula el descuento aplicable según tipo de cliente y monto.
     - Función `fn_validar_email`: valida la consistencia sintáctica de correos electrónicos de clientes.
     - Procedimiento `sp_liquidar_clientes`: procesa y registra masivamente la liquidación de clientes.
     - Procedimiento `sp_reajustar_precios`: actualiza los precios del catálogo según un porcentaje recibido como parámetro.
  2. **Cuerpo e implementación privada:**
     - Implementar todos los subprogramas públicos.
     - Implementar un subprograma privado auxiliar (`sp_log_error_interno`) para registrar anomalías directamente en `LOG_ERRORES` sin exponerlo al consumidor externo.
- **Estimación:** 8 Story Points  
- **Prioridad:** Bloqueante / Alta  

---

### ÉPICA 5: Reglas de Integridad y Auditoría Automática con Triggers (Rúbrica EP2 - IL2.3)
#### Historia de Usuario: `[SV-08]` Implementación de Triggers de Sentencia y Fila
- **Como:** Administrador de Seguridad e Inventario.
- **Quiero:** Disparadores que respondan a eventos DML (`INSERT`, `UPDATE`, `DELETE`) en tablas clave.
- **Para:** Garantizar la consistencia transaccional del stock y auditar variaciones de precios sin intervención manual.
- **Criterios de Aceptación:**
  1. **Trigger de fila en ventas (`TRG_CONTROL_STOCK_VENTA`):**
     - Disparo: `BEFORE INSERT ON DETALLE_VENTA FOR EACH ROW`.
     - Validar que el stock disponible en `PRODUCTO` cubra `:NEW.cantidad`.
     - Si es insuficiente, abortar la transacción con `RAISE_APPLICATION_ERROR(-20001, ...)`.
     - Si es suficiente, descontar automáticamente las unidades de `PRODUCTO`.
  2. **Trigger de fila de auditoría de precios (`TRG_AUDIT_PRECIO_PRODUCTO`):**
     - Disparo: `AFTER UPDATE OF precio ON PRODUCTO FOR EACH ROW`.
     - Registrar en la tabla `HISTORIAL_PRECIO_PRODUCTO`: ID del producto, precio anterior (`:OLD.precio`), precio nuevo (`:NEW.precio`), usuario y fecha.
  3. **Trigger de sentencia (`TRG_AUDIT_VENTAS_SENTENCIA`):**
     - Disparo: `AFTER INSERT OR UPDATE OR DELETE ON VENTA`.
     - Registrar en `AUDITORIA_OPERACIONES_VENTA` el tipo de operación DML, cantidad global y timestamp.
- **Estimación:** 8 Story Points  
- **Prioridad:** Alta  

---

### ÉPICA 6: Integración y Capa de Presentación con Oracle APEX (Rúbrica EP2 - IL2.4)
#### Historia de Usuario: `[SV-09]` Interfaz Interactiva y Enlace con Subprogramas PL/SQL
- **Como:** Administrador Comercial de Sonido Vivo.
- **Quiero:** Una aplicación web en Oracle APEX con reportes y formularios interactivos.
- **Para:** Visualizar el catálogo, administrar clientes y ejecutar procesos de cálculo desde una interfaz web.
- **Criterios de Aceptación:**
  1. Reporte interactivo con formulario para la tabla `CLIENTE` con validación que invoque `PKG_SONIDO_VIVO.fn_validar_email`.
  2. Reporte interactivo con formulario para la tabla `PRODUCTO`.
  3. Página de procesamiento con formulario donde se ingrese un porcentaje y un botón "Procesar" que ejecute `PKG_SONIDO_VIVO.sp_reajustar_precios`.
  4. Visualización de registros de auditoría generados por los disparadores.
- **Estimación:** 8 Story Points  
- **Prioridad:** Alta  

---

### ÉPICA 7: Documentación Formal y Defensa de Código EP2 (Ponderación 40%)
#### Historia de Usuario: `[SV-10]` Informe Técnico de Arquitectura Avanzada PL/SQL
- **Como:** Estudiante evaluado en BDY1103.
- **Quiero:** Un informe técnico estructurado con justificaciones arquitectónicas de packages y triggers.
- **Para:** Cumplir con la pauta de la Evaluación Parcial 2.
- **Criterios de Aceptación:**
  1. Justificación de la arquitectura modular (especificación vs cuerpo, constructores públicos vs privados).
  2. Análisis de triggers a nivel de sentencia versus fila, evitando tablas mutantes (ORA-04091).
  3. Evidencias de ejecución y capturas de integración en Oracle APEX.
- **Estimación:** 5 Story Points  
- **Prioridad:** Crítica  

#### Historia de Usuario: `[SV-11]` Soporte para Presentación Ejecutiva y Defensa Oral EP2
- **Como:** Estudiante defendiendo el proyecto.
- **Quiero:** Guión técnico de defensa oral y diapositivas ejecutivas (máximo 10 slides).
- **Para:** Responder con precisión a las preguntas del docente durante la presentación de 20 minutos.
- **Estimación:** 5 Story Points  
- **Prioridad:** Crítica  
