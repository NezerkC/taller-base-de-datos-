# Product Requirements Document (PRD)

## Proyecto: Sonido Vivo — Motor de Liquidación y Auditoría PL/SQL
**Asignatura:** BDY1103 - Taller de Base de Datos  
**Instancia de Evaluación:** Evaluación Parcial N° 1 (Ponderación 30%)  
**Dominio de Negocio:** E-commerce de Instrumentos Musicales y Audio Profesional ("Sonido Vivo")  
**Versión:** 1.0.0  
**Estado:** Aprobado  

---

## 1. Visión General del Producto y Contexto de Negocio

### 1.1 Contexto de la Empresa
**Sonido Vivo** es una tienda dedicada a la venta de instrumentos musicales y accesorios, ubicada en **Viña del Mar**. Su catálogo abarca instrumentos de cuerda, viento y percusión, además de accesorios complementarios como cuerdas, baquetas y estuches, orientados tanto a músicos aficionados como profesionales.

### 1.2 Problemática Actual
Actualmente la tienda gestiona sus ventas y su stock de manera manual, lo que dificulta:
- Llevar un control preciso de la disponibilidad de productos en bodega y vitrina.
- Generar boletas y órdenes de compra de forma ordenada.
- Hacer seguimiento del historial de compras y fidelización de cada cliente.

Ante el crecimiento del negocio, esta modalidad manual se vuelve poco escalable y eleva drásticamente el riesgo de inconsistencias graves, como la venta de productos sin stock disponible o la pérdida de registros históricos.

### 1.3 Propuesta de Solución en Oracle PL/SQL
Se desarrolla un sistema de base de datos en Oracle que permite registrar productos, clientes y ventas, automatizando tareas clave del negocio:
- Descuento y auditoría de stock al concretar una venta.
- Cálculo consolidado de totales, subtotales y beneficios comerciales.
- Control estricto de excepciones ante operaciones no válidas (por ejemplo, intentar vender más unidades de las disponibles en inventario).
- Sentar las bases transaccionales sólidas para su futura integración con la plataforma web del proyecto de **Fullstack II**.

---

## 2. Alcance y Entregables

### 2.1 En Alcance (In Scope)
1. **Modelo de Datos Relacional:**
   - Creación de tablas base (`CATEGORIA`, `PRODUCTO`, `CLIENTE`, `VENTA`, `DETALLE_VENTA`, `HISTORIAL_LIQUIDACION`, `LOG_ERRORES`).
   - Carga de datos iniciales basada en el catálogo real de Sonido Vivo.
2. **Procesamiento con Tipos de Datos Compuestos (IE1.1.1):**
   - Implementación de `RECORD` para agrupar atributos heterogéneos de liquidación (código cliente, total bruto, descuento, total neto).
   - Implementación de `VARRAY` para almacenar y aplicar porcentajes de bonificación/descuento escalonados por categoría en memoria.
3. **Cursores Explícitos Complejos y Bucles Anidados (IE1.2.1):**
   - Cursor principal (padre) que itera clientes con ventas pendientes de liquidación.
   - Cursor secundario con parámetros (hijo) que procesa el detalle de compras de cada cliente.
   - Procesamiento eficiente en bucles coordinados (`LOOP` anidados).
4. **Control Integral de Excepciones (IE1.3.1):**
   - Manejo de excepciones predefinidas de Oracle (`NO_DATA_FOUND`, `ZERO_DIVIDE`, etc.).
   - Definición y lanzamiento de excepciones personalizadas de negocio (`e_stock_insuficiente`, `e_monto_invalido`, `e_cliente_sin_compras`).
5. **Estrategia de Arquitectura Futura (IE1.4.1):**
   - Diseño evaluativo de Procedimientos Almacenados, Funciones, Paquetes y Triggers para la evolución a producción.
6. **Documentación Formal:**
   - Informe técnico formal conforme a la estructura de la pauta.
   - Presentación ejecutiva estructurada para la defensa oral (Situación Evaluativa 2).

### 2.2 Fuera de Alcance (Out of Scope)
- Integración directa vía API REST o middleware con la interfaz web (se valida directamente en motor Oracle SQL Developer / LiveSQL).
- Replicación distribuida de bases de datos.

---

## 3. Requerimientos Funcionales

| ID | Requerimiento | Descripción | Indicador Rúbrica |
|---|---|---|---|
| **RF01** | Modelo Transaccional | Esquema DDL normalizado en 3FN con claves primarias, foráneas y restricciones de dominio. | Base |
| **RF02** | Procesamiento Compuesto | Bloque PL/SQL anónimo que utilice tipos `RECORD` y colecciones `VARRAY` para consolidar datos en memoria. | IE1.1.1 (5%) |
| **RF03** | Cursores Anidados con Parámetros | Bloque PL/SQL anónimo con cursor explícito parametrizado que trabaje en bucles anidados para cruzar cabeceras y detalles de ventas. | IE1.2.1 (10%) |
| **RF04** | Gestión de Errores y Excepciones | Detección de anomalías con excepciones Oracle y de usuario, registrando auditoría en tabla de incidentes sin abortar el procesamiento global. | IE1.3.1 (10%) |
| **RF05** | Informe de Arquitectura y Subprogramas | Análisis formal justificando el uso de `PROCEDURE`, `FUNCTION`, `PACKAGE` y `TRIGGER` en la evolución del sistema. | IE1.4.1 (15%) |
| **RF06** | Material de Defensa Ejecutiva | Guión estructurado y diapositivas de defensa oral que justifiquen las decisiones técnicas tomadas. | IE1.1.2 a IE1.4.2 (60%) |

---

## 4. Requerimientos No Funcionales

1. **Rendimiento:** Minimizar cambios de contexto (Context Switches) entre el motor SQL y el motor PL/SQL mediante el uso de estructuras en memoria.
2. **Robustez:** Toda transacción debe garantizar integridad ACID; ante errores de negocio se debe registrar el incidente y continuar o revertir de manera predecible.
3. **Mantenibilidad:** Código modular, comentado con estándares técnicos y nombres representativos en español neutro profesional.

---

## 5. Criterios de Aceptación y Evaluación

1. **Ejecución 100% limpia:** Los scripts SQL y bloques anónimos PL/SQL se ejecutan sin errores de sintaxis en Oracle 19c/21c.
2. **Cumplimiento estricto de rúbrica:** Cada indicador de logro de la pauta de Duoc UC cuenta con evidencia ejecutable directa en código y justificación en informe.
3. **Consistencia de dominio:** Los datos de prueba corresponden al negocio Sonido Vivo (guitarras, bajos, consolas, cables, clientes reales).
