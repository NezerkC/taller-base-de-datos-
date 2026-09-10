# PRESENTACIÓN EJECUTIVA — DEFENSA EVALUACIÓN PARCIAL N° 1
## Caso de Negocio: Sonido Vivo (Viña del Mar)

**Asignatura:** BDY1103 — Taller de Base de Datos  
**Ponderación:** 60% de la Evaluación Parcial N° 1  
**Modalidad:** Presentación Ejecutiva y Defensa Técnica Individual  
**Audiencia:** Docente Evaluador — Duoc UC  

---

## Estructura de Diapositivas y Guión de Defensa Oral

---

### DIAPOSITIVA 1: Portada e Identificación
- **Título:** Optimización Transaccional y Procesamiento de Ventas en Oracle PL/SQL
- **Subtítulo:** Caso de Aplicación Real: Sonido Vivo (Viña del Mar)
- **Asignatura:** Taller de Base de Datos (BDY1103)
- **Integrantes:** [Nombre de los estudiantes]
- **Docente:** [Nombre del docente]
- **Fecha:** Septiembre 2026

> **GUION VERBAL (Qué decir):**  
> *"Buenas tardes, profesor. Hoy presentamos la solución transaccional desarrollada en Oracle PL/SQL para la tienda 'Sonido Vivo'. Nuestro objetivo fue transformar un negocio con control manual y riesgo de quiebre de stock en un sistema robusto, que automatiza liquidaciones, auditoría y reglas de negocio directamente en el motor de base de datos."*

---

### DIAPOSITIVA 2: Contexto de Negocio y Problemática (Criterio a)
- **Contexto:** Tienda especializada en instrumentos musicales (cuerdas, viento, percusión) y audio profesional en Viña del Mar.
- **Problemática Actual:**
  - Gestión manual en cuadernos/planillas: falta de trazabilidad.
  - Quiebres de stock ciego: riesgo de vender productos sin existencia física en bodega.
  - Imposibilidad de aplicar descuentos dinámicos por volumen de compra y fidelidad de clientes.
- **Objetivo de la Solución:** Centralizar la lógica de negocio en Oracle PL/SQL para asegurar consistencia ACID y preparar la arquitectura para la futura integración con la plataforma web de Fullstack II.

> **GUION VERBAL (Qué decir):**  
> *"Sonido Vivo atiende tanto a músicos aficionados como a profesionales en Viña del Mar. Hasta hoy, la tienda operaba de forma manual. Esto generaba dos problemas críticos: desorden en la emisión de boletas y el riesgo latente de vender instrumentos sin stock disponible en bodega. Frente a esto, diseñamos una base de datos en Oracle que no solo persiste la información, sino que utiliza PL/SQL para automatizar el cálculo de totales, descontar existencias y blindar el sistema ante operaciones no válidas."*

---

### DIAPOSITIVA 3: Datos a Procesar e Información Relevante (Criterio b)
- **Datos de Entrada (Procesamiento):**
  - Catálogo de productos: código, marca, modelo, precio, stock actual y stock crítico.
  - Clientes: RUT, datos demográficos (Viña del Mar, Valparaíso, Concón) y categoría (`ESTANDAR`, `FRECUENTE`, `PREMIUM`).
  - Transacciones: cabeceras de boleta y líneas de detalle con cantidades y precios unitarios.
- **Información Generada (Salida de Valor):**
  - Montos brutos acumulados por cliente y volumen transaccional.
  - Tasas de descuento y bonificaciones escalonadas calculadas en memoria.
  - Liquidaciones comerciales netas consolidadas en `LIQUIDACION_CLIENTE`.
  - Registro de incidentes operacionales en `LOG_ERRORES`.

> **GUION VERBAL (Qué decir):**  
> *"Los datos que procesamos provienen del catálogo real y el flujo de ventas de la tienda: precios, unidades vendidas, stock en bodega y tipos de cliente. A partir de estos datos, el sistema genera información estratégica: consolida el historial de compras por cliente, aplica descuentos comerciales según volumen y tipo de fidelidad, y genera reportes de auditoría de incidentes."*

---

### DIAPOSITIVA 4: Justificación de Tipos Compuestos: RECORD y VARRAY (Criterio c)
- **RECORD (`t_rec_liquidacion`):**
  - *¿Por qué se usa?* Unifica en una sola estructura lógica datos heterogéneos (números, cadenas, porcentajes) que representan una liquidación.
  - *Beneficio:* Funciona como un DTO (*Data Transfer Object*) en memoria; simplifica el código y evita declarar 8 variables escalares independientes.
- **VARRAY (`t_arr_tasas`):**
  - *¿Por qué se usa?* Colección de tamaño fijo indexada en memoria PGA con las escalas de descuento (0%, 5%, 10%).
  - *Beneficio de Eficiencia:* Evita consultas `SELECT` recurrentes a disco para obtener parámetros estables, reduciendo drásticamente el costo de I/O en procesamientos por lotes.

> **GUION VERBAL (Qué decir):**  
> *"Para optimizar el procesamiento en memoria implementamos dos tipos compuestos. Primero, un `RECORD`, que nos permite encapsular todos los campos de una liquidación (cliente, montos, descuentos y observaciones) en una sola variable lógica. Segundo, un `VARRAY` de tamaño fijo que almacena en la memoria del proceso (PGA) los porcentajes de descuento por tramo. Esto es clave: evitamos tener que consultar tablas de parámetros en disco por cada fila procesada, ganando velocidad y eficiencia en el procesamiento de lotes."*

---

### DIAPOSITIVA 5: Justificación de Cursores Explícitos y Bucles Anidados (Criterio d)
- **Cursor Padre (`c_clientes`):** Recorre de manera explícita y ordenada a los clientes que poseen transacciones registradas.
- **Cursor Hijo con Parámetros (`c_ventas_cliente(p_id_cli)`):**
  - Recibe dinámicamente el `id_cliente` del bucle externo.
  - Ejecuta un `JOIN` optimizado entre ventas, líneas de detalle, productos y categorías.
- **Manejo de Bucles Anidados:**
  - *Bucle Externo:* Controla la agregación a nivel de cliente.
  - *Bucle Interno:* Procesa línea por línea cada producto adquirido, acumulando unidades y subtotales.
  - *Ventaja:* El paso de parámetros delega el filtrado al optimizador de Oracle (CBO), procesando únicamente las filas hijas pertinentes sin cargar productos cartesianos en memoria.

> **GUION VERBAL (Qué decir):**  
> *"Para resolver la relación jerárquica entre un cliente y sus múltiples compras, utilizamos bucles anidados con cursores explícitos. El cursor padre selecciona a los clientes, y por cada uno de ellos, abrimos un cursor secundario complejo parametrizado. Este cursor hijo recibe el ID del cliente y realiza un JOIN entre ventas, productos y categorías. Al estar parametrizado, el motor de Oracle aplica los índices correspondientes en la fuente, garantizando que el bucle interno procese exactamente los registros correspondientes con el menor costo de cómputo posible."*

---

### DIAPOSITIVA 6: Justificación del Control de Excepciones (Criterio e)
- **Excepciones Predefinidas de Oracle:**
  - `NO_DATA_FOUND` (ORA-01403): Captura consultas de clientes o códigos de producto inexistentes en catálogo.
  - `TOO_MANY_ROWS` (ORA-01422): Previene inconsistencias de unicidad.
- **Excepciones Definidas por el Usuario:**
  - `e_stock_insuficiente`: Se dispara con `RAISE` si la cantidad solicitada supera el stock físico disponible en bodega (`cantidad > stock`).
  - `e_cantidad_invalida`: Valida que la cantidad sea un entero estrictamente positivo.
- **Estrategia de Auditoría:**
  - Ante una excepción, se ejecuta `ROLLBACK` para evitar transacciones incompletas.
  - Se registra el incidente en `LOG_ERRORES` (`SQLCODE`, `SQLERRM`, módulo, usuario, fecha) para no detener la operación global y permitir soporte forense.

> **GUION VERBAL (Qué decir):**  
> *"El control de excepciones es el escudo que garantiza la integridad de los datos. Manejamos dos tipos: las predefinidas por Oracle, como `NO_DATA_FOUND`, para cuando se busca un producto o cliente inexistente; y las definidas por el usuario mediante `RAISE`, como `e_stock_insuficiente`, que impide materializar una venta si el stock en bodega no alcanza. Además, ante cualquier fallo, ejecutamos un `ROLLBACK` y guardamos el error con su código y mensaje en la tabla `LOG_ERRORES`, asegurando trazabilidad total sin abortar el sistema."*

---

### DIAPOSITIVA 7: Arquitectura Futura: Procedimientos, Funciones, Paquetes y Triggers (Criterio f)
- **Paquete (`PKG_VENTAS_SONIDO_VIVO`):** Agrupa y encapsula la lógica comercial. Modulariza el código y permite modificar la implementación interna sin romper dependencias externas.
- **Funciones Almacenadas (`FN_CALCULAR_DESCUENTO`):** Subprogramas de cálculo reutilizables directamente en consultas SQL (`SELECT`) o dentro de procedimientos.
- **Procedimientos Almacenados (`SP_REGISTRAR_VENTA`):** Automatizan operaciones transaccionales repetitivas de cabecera y detalle.
- **Triggers de Auditoría y Control (`TRG_DESCUENTA_STOCK` / `TRG_AUDITA_STOCK_CRITICO`):**
  - Descuentan automáticamente el stock tras cada venta (`AFTER INSERT ON DETALLE_VENTA`).
  - Disparan alertas preventivas si el inventario cae bajo el umbral de `stock_critico`.
- **Riesgos y Mitigación:** Cuidado con el error de tabla mutante (`ORA-04091`) en triggers y sobrecarga de memoria PGA; se mitiga usando triggers compuestos (*Compound Triggers*) y parámetros `NOCOPY`.

> **GUION VERBAL (Qué decir):**  
> *"De cara a producción y a la integración con la web de Fullstack II, evaluamos la arquitectura en subprogramas. Diseñamos el paquete `PKG_VENTAS_SONIDO_VIVO` para encapsular la lógica del negocio. Las funciones se encargarán de calcular descuentos reutilizables en SQL, los procedimientos orquestarán las transacciones complejas, y los triggers automatizarán la rebaja de stock y las alertas de stock crítico. Para mitigar riesgos como tablas mutantes o lentitud en operaciones masivas, los triggers se restringen estrictamente a tareas atómicas de auditoría y stock."*

---

### DIAPOSITIVA 8: Conclusiones y Preguntas (Criterio g)
- **Logros Alcanzados:**
  - Modelo relacional normalizado y operativo con datos reales de Sonido Vivo.
  - Automatización del motor de cálculo de descuentos mediante `RECORD` y `VARRAY`.
  - Trazabilidad y consistencia garantizadas por cursores anidados y control de excepciones.
  - Plan de integración claro para conectar la base de datos con la plataforma web.
- **Cierre:** Espacio abierto para preguntas del docente.

> **GUION VERBAL (Qué decir):**  
> *"En conclusión, la solución desarrollada en PL/SQL no solo resuelve la problemática operativa de Sonido Vivo en Viña del Mar eliminando los quiebres de stock ciego y ordenando las ventas, sino que sienta las bases técnicas para escalar hacia la plataforma web completa de Fullstack II. Muchas gracias, quedamos atentos a sus preguntas."*

---

## Banco de Preguntas Frecuentes del Docente (Q&A)

### P1: ¿Por qué usaron un VARRAY y no una tabla anidada (Nested Table)?
> **Respuesta:** *"Elegimos `VARRAY` porque las escalas de descuento representan una estructura fija y conocida de antemano (3 tramos: 0%, 5% y 10%) con orden secuencial estricto. El `VARRAY` mantiene el límite máximo y preserva el orden en memoria de forma más compacta que una tabla anidada."*

### P2: ¿Por qué parametrizar el cursor hijo y no hacer un solo cursor con un GROUP BY o JOIN masivo?
> **Respuesta:** *"Porque el requerimiento del negocio exige una auditoría jerárquica donde se debe procesar la cabecera del cliente y, dentro de ese contexto, iterar sus líneas de compra para acumular variables y generar subtotales formateados. Parametrizar el cursor hijo permite que el optimizador de Oracle filtre en cada iteración usando el índice del cliente (`id_cliente`), manteniendo la memoria PGA bajo control."*

### P3: ¿Qué pasa si ocurre una excepción dentro de su bloque PL/SQL? ¿Se pierden los datos?
> **Respuesta:** *"No. En el bloque de excepciones implementamos un `ROLLBACK` que revierte las modificaciones de la transacción fallida para evitar datos huérfanos o stock inconsistente, seguido de un `INSERT` autónomo en la tabla `LOG_ERRORES` con el `SQLCODE` y `SQLERRM` para que los administradores puedan auditar exactamente qué ocurrió."*

### P4: ¿Cuál es el riesgo de usar Triggers para actualizar tablas y cómo se soluciona?
> **Respuesta:** *"El mayor riesgo en Oracle es el error `ORA-04091: table is mutating`, que ocurre cuando un trigger de fila (`FOR EACH ROW`) intenta consultar o modificar la misma tabla que disparó el evento. En nuestra arquitectura, el trigger sobre `DETALLE_VENTA` modifica una tabla externa (`PRODUCTO`), evitando la mutación. En casos donde se deba interactuar con la misma tabla, la solución arquitectónica estándar de Oracle es utilizar un Trigger Compuesto (*Compound Trigger*)."*
