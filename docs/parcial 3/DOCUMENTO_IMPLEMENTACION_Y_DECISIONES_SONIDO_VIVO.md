# Documento Técnico y de Defensa: Arquitectura Políglota e Implementación en Sonido Vivo

**Asignatura:** BDY1103 — Taller de Base de Datos  
**Caso de Estudio:** Sonido Vivo (Tienda de Instrumentos Musicales y Audio Profesional — Viña del Mar)  
**Integrantes:** Dylan Sandoval – Víctor Martínez – Danilo Sepúlveda  
**Alcance:** Consolidación de EP2 (Oracle PL/SQL) y EP3 (MongoDB 4.4 NoSQL), comparativa técnica y justificación de decisiones de ingeniería.

---

## 1. Visión General: ¿Por qué usamos SQL y NoSQL juntos?

En **Sonido Vivo** no reemplazamos Oracle con MongoDB; implementamos **Persistencia Políglota**, asignando cada conjunto de datos al motor que mejor resuelve sus requisitos de consistencia, estructura y lectura:

* **Oracle Database (Relacional / ACID):** Gobierna el núcleo transaccional y contable (`CLIENTE`, `VENTA`, `DETALLE_VENTA`, `LIQUIDACION_CLIENTE`, `LOG_ERRORES`, `AUDITORIA_OPERACION`), donde un error en una línea de boleta debe deshacer toda la operación (`ROLLBACK`).
* **MongoDB 4.4 (Documental / BSON):** Gobierna el catálogo web polimórfico (`productos`), los pedidos web autocontenidos (`pedidos`) y las reseñas de clientes (`resenas_clientes`), donde predominan atributos técnicos distintos por familia de instrumento, lecturas completas en un solo acceso a disco y agregaciones analíticas rápidas.
* **Redis (Clave-Valor en RAM, capa de apoyo):** Destinado a estado efímero de baja latencia (sesiones, carrito temporal y *rate limiting*), donde no se requieren consultas por atributos internos.

```text
+-------------------------------------------------------------------------+
|                    APLICACIÓN / BACKEND SONIDO VIVO                     |
+-------------------------------------------------------------------------+
          |                             |                         |
          v                             v                         v
+-------------------+   +-------------------------------+   +-------------------+
| REDIS (RAM)       |   | ORACLE (Core ACID - EP1/EP2)  |   | MONGODB 4.4 (EP3) |
| - Sesiones / JWT  |   | - 7 tablas 3FN + Auditoría    |   | - productos       |
| - Carrito efímero |   | - FN_*, SP_*, PKG_SONIDO_VIVO |   | - pedidos         |
|                   |   | - Triggers Stock & Auditoría  |   | - resenas_clientes|
+-------------------+   +-------------------------------+   +-------------------+
```

---

## 2. Implementación Relacional en SQL y PL/SQL (Oracle — EP2)

**Archivo fuente:** `ep2_sonido_vivo.sql`

### 2.1 Qué se implementó

1. **Modelo Relacional Normalizado (3FN):**
    * **Catálogo:** `CATEGORIA` (6 categorías), `PRODUCTO` (10 productos oficiales `GA001` a `AC002` con `CHECK (precio > 0)`, `CHECK (stock >= 0)` y `stock_critico`).
    * **Clientes y Ventas:** `CLIENTE` (5 clientes con `tipo_cliente IN ('ESTANDAR', 'FRECUENTE', 'PREMIUM')`), `VENTA` (5 ventas iniciales `1001`–`1005` / boletas `5001`–`5005`), `DETALLE_VENTA` (8 líneas).
    * **Cierre y Control:** `LIQUIDACION_CLIENTE`, `LOG_ERRORES`, `AUDITORIA_OPERACION` y 6 secuencias (`SEQ_LOG_ERRORES`, `SEQ_LIQUIDACION_CLIENTE`, `SEQ_VENTA`, `SEQ_DETALLE`, `SEQ_BOLETA`, `SEQ_AUDITORIA`).
2. **Funciones Almacenadas:**
    * `FN_CALCULAR_DESCUENTO(p_total_bruto, p_tipo_cliente)`: retorna tasa en `%` (`< 200.000` -> `0`, `200.000..700.000` -> `5`, `> 700.000` -> `10`, y `+2` puntos si es `PREMIUM`).
    * `FN_TOTAL_PENDIENTE`: retorna la suma total de ventas en estado `PENDIENTE` (`2.507.890`).
3. **Procedimientos Almacenados:**
    * `SP_LIQUIDAR_CLIENTES`: recorre clientes con ventas `PENDIENTE`, invoca `FN_CALCULAR_DESCUENTO` e inserta en `LIQUIDACION_CLIENTE`.
    * `SP_REGISTRAR_VENTA(p_id_cliente, p_codigo_producto, p_cantidad)`: valida cantidad, consulta cliente y producto, inserta cabecera en `VENTA` y línea en `DETALLE_VENTA`. Incluye subprograma local `registrar_error` y captura `-20001` mediante `PRAGMA EXCEPTION_INIT(e_sin_stock, -20001)`.
4. **Package `PKG_SONIDO_VIVO`:**
    * **Especificación (Público):** constante `c_nombre_tienda`, función `fn_stock_producto`, procedimientos `sp_reponer_stock`, `sp_resumen_cliente` y `sp_mostrar_criticos`.
    * **Body (Privado):** constante `c_max_reposicion := 100`, función booleana `fn_existe_producto` y procedimiento `sp_registrar_log` con `PRAGMA AUTONOMOUS_TRANSACTION`.
5. **Triggers:**
    * `TRG_DESCUENTA_STOCK` (`BEFORE INSERT ON DETALLE_VENTA FOR EACH ROW`): bloquea la fila de `PRODUCTO` con `SELECT ... FOR UPDATE`, valida stock disponible (lanza `-20001` si falta) y descuenta el inventario.
    * `TRG_AUDITA_VENTA` (`AFTER INSERT OR UPDATE OR DELETE ON VENTA`, nivel sentencia): registra una fila por operación DML en `AUDITORIA_OPERACION`.

### 2.2 Por qué se diseñó de esta manera en SQL

* **Normalización 3FN y `CHECK` constraints:** Impide que existan líneas de detalle sin cabecera válida o descuentos matemáticamente incoherentes (`total = subtotal - descuento`).
* **Regla de negocio única (`FN_CALCULAR_DESCUENTO`):** Evita duplicar tramos de descuento entre el proceso masivo (`SP_LIQUIDAR_CLIENTES`) y el resumen individual (`PKG_SONIDO_VIVO.sp_resumen_cliente`).
* **Separación entre Procedimiento y Trigger para el stock:** `SP_REGISTRAR_VENTA` no descuenta stock directamente porque `TRG_DESCUENTA_STOCK` lo hace a nivel de fila. Así la regla de "no vender sin stock" se cumple incluso si otra aplicación inserta directamente en `DETALLE_VENTA`, y se evita descontar dos veces.
* **`SELECT ... FOR UPDATE` en el trigger de fila:** Serializa ventas concurrentes sobre el mismo producto para evitar que dos transacciones lean el mismo saldo y dejen stock negativo.
* **`PRAGMA AUTONOMOUS_TRANSACTION` en `sp_registrar_log` y `ROLLBACK` previo en `registrar_error`:** Garantiza que, ante una falla (ej. pedir 5 unidades de `GE002` cuando hay 2), se deshagan la venta y su auditoría, pero el registro del error en `LOG_ERRORES` quede persistido.
* **Encapsulación con Package:** Permite cambiar internamente cómo se valida existencia o cómo se graban logs sin romper a quienes consumen la especificación pública.

---

## 3. Implementación NoSQL Documental (MongoDB 4.4 — EP3)

**Archivos fuente:** `ep3_sonido_vivo.js` (esquema + índices + CRUD + analítica + prueba negativa) y `ep3_crud_sonido_vivo.js` (ciclo CRUD independiente e idempotente).

### 3.1 Qué se implementó

1. **Base de Datos `sonido_vivo` con 3 Colecciones y `$jsonSchema` estricto:**
    * `productos` (10 documentos homologados `GA001`–`AC002` + `TE002` temporal): atributos comunes validados + subdocumento polimórfico `especificaciones` + arreglo `etiquetas`.
    * `pedidos` (5 documentos `PED-2026-5001`–`5005` + `PED-2026-9999` temporal): incrusta el subdocumento `cliente` y el arreglo `items`.
    * `resenas_clientes` (6 documentos): vinculada lógicamente mediante `codigo_producto`.
    * Todas con `validationLevel: "strict"` y `validationAction: "error"` (validando regex `^[A-Z]{2}[0-9]{3}$` y `^PED-[0-9]{4}-[0-9]{4}$`, precios >= 1, stock >= 0, calificaciones 1..5).
2. **6 Índices Estratégicos:**
    * `productos`: `idx_prod_codigo` (Unique), `idx_prod_cat_precio` (`categoria: 1, precio: -1`), `idx_prod_etiquetas_multikey` (`etiquetas: 1`).
    * `pedidos`: `idx_ped_codigo` (Unique), `idx_ped_cliente_fecha` (`"cliente.rut": 1, fecha: -1`).
    * `resenas_clientes`: `idx_res_producto` (`codigo_producto: 1, calificacion: -1`).
3. **Operaciones CRUD (`ep3_crud_sonido_vivo.js`):**
    * **Create:** `insertMany` inicial (10 productos, 5 pedidos, 6 reseñas) e `insertOne` (`TE002`).
    * **Read:** Dot Notation (`"especificaciones.trastes": 22` o `"especificaciones.patron_polar": "Cardioide"` -> 3 docs), filtros compuestos (`$in` + `$gt` ordenados -> 3 docs), `$elemMatch` sobre `items` (`cantidad >= 2` y `subtotal >= 20000` en el mismo ítem -> 2 pedidos) y consulta sobre índice multikey (`etiquetas` -> 5 docs).
    * **Update:**
        * Descuento atómico con guarda: `{ codigo: "AP001", stock: { $gte: 2 } }` + `{ $inc: { stock: NumberInt(-2) } }` (baja de 12 a 10).
        * `$addToSet` en `GE001` para agregar `"alta-demanda"` sin duplicados.
        * `$push` + `$inc` en `PED-2026-5004` (`PENDIENTE`) para añadir 2 cuerdas `AC001` y actualizar `subtotal` y `total` (`155.970` -> `173.950 CLP`).
        * `updateMany` con `$set` asignando `especificaciones.garantia_meses: 12` en `Audio Profesional` (2 docs).
    * **Delete:** `deleteOne` (`TE002`) y `deleteMany` (`estado: "CANCELADO"` sobre `PED-2026-9999`).
4. **Gobernanza y Analítica (`ep3_sonido_vivo.js`):**
    * **Prueba negativa `$jsonSchema`:** intento de insertar `BAD01` (código fuera de patrón, categoría inválida, precio `-5000`, stock `-1`) rechazado por el motor.
    * **Pipeline 1 (`pedidos`):** `$match` (`COMPLETADO`/`PAGADO`) -> `$unwind` (`$items`) -> `$group` -> `$sort` = 6 productos facturados por `2.351.920 CLP` totales (Top 1: `BA001` con `799.990 CLP`; Top 2: `GE001` con `749.990 CLP`).
    * **Pipeline 2 (`productos` + `resenas_clientes`):** `$lookup` -> `$unwind` -> `$group` -> `$project` (`$round` a 2 decimales) -> `$sort` = 5 productos evaluados (`GE002`, `AP001`, `AP002`: `5.0`; `GE001`: `4.5`; `TE001`: `4.0`).

### 3.2 Por qué elegimos estas decisiones en MongoDB

1. **¿Por qué base Documental y no otra familia NoSQL?**
    * **Clave-Valor (Redis):** No permite consultar o indexar atributos internos del producto (`trastes`, `patron_polar`).
    * **Columnar Ancha (Cassandra):** Optimizada para escritura masiva y series temporales por *partition key*, inadecuada para consultas polimórficas arbitrarias del catálogo.
    * **Grafos (Neo4j):** Diseñada para recorridos profundos entre relaciones (redes sociales, detección de fraude), sobredimensionada para fichas de productos y boletas.
    * **Documental (MongoDB):** Permite documentos polimórficos BSON, índices secundarios y multikey sobre campos anidados, y agregación en el propio servidor.
2. **¿Por qué MongoDB 4.4 y no MongoDB 7.x en el servidor de despliegue?**
    * El contenedor `CT100` (`192.168.3.150`) corre sobre un nodo Proxmox con CPU **Intel Celeron 3855U**, que **no soporta instrucciones `AVX`**. Desde MongoDB 5.0+ (incluido 7.x), los binarios exigen `AVX` y abortan con `SIGILL` (`Illegal instruction`, código `132`). MongoDB 4.4 soporta nativamente `$jsonSchema`, `Decimal128`, `$elemMatch`, `$lookup` y `$round` sin requerir `AVX`.
    * Para administración se utiliza **Mongo Express** (`:8084`), **MongoDB Compass** y **`mongo`/`mongosh`** (`:27017`), dado que CloudBeaver CE (`:8978`) solo incluye drivers SQL/JDBC.
3. **¿Por qué `especificaciones` polimórficas en `productos`?**
    * Una guitarra (`GE001`) requiere `trastes`, `cuerpo` y `configuracion_pastillas`; un piano (`TE001`) requiere `teclas`, `accion_teclado` y `polifonia_notas`; un micrófono (`AP001`) requiere `patron_polar` e `impedancia_ohm`. En SQL esto forzaría decenas de columnas `NULL` o tablas EAV complejas de consultar; en MongoDB cada documento guarda exactamente sus atributos técnicos.
4. **¿Por qué `pedidos` es Embebido y `resenas_clientes` es Referenciado?**
    * **`pedidos` (Embebido, *One-to-Few*):** (a) **Lectura atómica** de la orden completa (cliente + ítems) en 1 solo I/O sin `JOIN`; (b) **Inmutabilidad histórica**: si el precio de `GE001` cambia en `productos`, la boleta histórica mantiene congelado su `precio_unitario` de compra.
    * **`resenas_clientes` (Referenciado, *One-to-Many / Squillions*):** Un instrumento popular puede acumular miles de reseñas. Embeberlas dentro de `productos` generaría crecimiento ilimitado (*Unbounded Growth*) y arriesgaría superar el **límite físico de 16 MB por documento BSON**, además de degradar la caché de *WiredTiger*.
5. **¿Por qué `NumberDecimal` (`Decimal128`) y `NumberInt` (`Int32`)?**
    * `Decimal128` garantiza exactitud financiera en montos CLP (sin errores de redondeo de punto flotante binario) y ambos coinciden con los tipos BSON exigidos por el validador `$jsonSchema`.
6. **¿Por qué `$inc` con filtro de guarda en lugar de leer + `$set`?**
    * Leer stock en la app, restar en memoria y sobrescribir con `$set` produce condiciones de carrera (*Race Conditions*) ante compras simultáneas. Al incluir `stock: { $gte: 2 }` en el filtro junto a `$inc: { stock: -2 }`, MongoDB valida y descuenta atómicamente sobre el documento.
7. **¿Por qué `$elemMatch` en `pedidos.items`?**
    * Evita falsos positivos: sin `$elemMatch`, MongoDB consideraría válido un pedido donde el ítem A cumple `cantidad >= 2` y el ítem B cumple `subtotal >= 20000`. `$elemMatch` exige ambas condiciones en el **mismo subdocumento**.
8. **¿Por qué `$jsonSchema` estricto + 6 índices + separación de `ep3_crud_sonido_vivo.js`?**
    * Flexibilidad de esquema no significa aceptar datos inválidos: `$jsonSchema` (`strict` + `error`) impone contrato mínimo en el motor (y puede evolucionar en vivo con `collMod`).
    * Los 6 índices evitan `COLLSCAN` y aseguran `IXSCAN`.
    * Separar `ep3_crud_sonido_vivo.js` usando `deleteMany({})` al inicio permite re-ejecutar y probar todo el ciclo CRUD sin ejecutar `drop()`, preservando intactos los validadores `$jsonSchema` e índices creados por `ep3_sonido_vivo.js`.

---

## 4. Comparativa Técnica: SQL (Oracle) vs. NoSQL (MongoDB)

| Dimensión | Relacional — Oracle (EP1 / EP2) | Documental — MongoDB 4.4 (EP3) |
| :--- | :--- | :--- |
| **Unidad de almacenamiento** | Tablas bidimensionales normalizadas (3FN) con filas y columnas fijas. | Colecciones de documentos jerárquicos BSON (*Binary JSON*, máx. 16 MB). |
| **Esquema** | *Schema-on-Write* rígido (DDL previo; variaciones generan `NULL` o EAV). | *Schema-on-Read* polimórfico, gobernado selectivamente con `$jsonSchema`. |
| **Consistencia y Transacciones** | **ACID** estricto multi-tabla (`COMMIT` / `ROLLBACK` completo). | **BASE** / atómico a nivel de documento individual. |
| **Teorema CAP / PACELC** | **CA** en nodo único (consistencia y disponibilidad sin partición distribuida). | **CP** en *Replica Set* (sin quórum rechaza escrituras); **PACELC: PC/EC**. |
| **Relaciones y Lecturas** | `FOREIGN KEY` + `JOIN` en tiempo de consulta. | Embebido (1 I/O, datos acotados/inmutables) o Referenciado + `$lookup`. |
| **Control de concurrencia** | Bloqueo pesimista de fila (`SELECT ... FOR UPDATE`) en triggers/SPs. | Mutación atómica por documento (`filtro guarda` + `$inc`). |
| **Escalamiento** | Principalmente vertical (*Scale-up*: mayor CPU y RAM). | Horizontal nativo (*Scale-out* mediante *Sharding* y *Replica Sets*). |
| **Rol en Sonido Vivo** | Clientes, boletas, detalle contable, liquidaciones y log de errores. | Catálogo polimórfico, pedidos web autocontenidos, reseñas y BI rápido. |

---

## 5. Verificación Realizada (Evidencia del Proyecto)

* **Verificación local determinista (`verificar_ep3_mongodb.py` -> `salida_verificacion_ep3.txt`):** Validación sintáctica JS con Node.js y simulación de 30 sentencias con **8/8 checks `[OK]`** (`CHK-01` a `CHK-08`), confirmando rechazo de `BAD01`, stock `AP001` (`12 -> 10`), total `PED-2026-5004` (`173.950 CLP`) y agregaciones (`2.351.920 CLP` y 5 reseñas promediadas).
* **Verificación en servidor real (`CT100`, `192.168.3.150:27017`, MongoDB 4.4.30):** Ejecución completa de `ep3_crud_sonido_vivo.js` con código de salida `0`, validando Fases 1–4 (Create, Read, Update, Delete) sobre los validadores e índices reales de `sonido_vivo`.

---

## 6. Guía Rápida de Preguntas de Defensa Oral

1. **¿MongoDB reemplaza a Oracle en Sonido Vivo?**  
   No. Conviven bajo Persistencia Políglota: Oracle protege integridad transaccional ACID en ventas, liquidaciones y auditoría; MongoDB entrega agilidad para fichas técnicas heterogéneas, pedidos en 1 I/O y reseñas.
2. **¿Por qué embeber `items` en `pedidos` y referenciar `resenas_clientes`?**  
   `pedidos` tiene tamaño acotado y necesita inmutabilidad histórica de precios; `resenas_clientes` puede crecer sin límite y superaría el tope BSON de 16 MB si se incrustara en `productos`.
3. **¿Cómo evitan sobreventa en Oracle y en MongoDB?**  
   En Oracle con `SELECT ... FOR UPDATE` dentro de `TRG_DESCUENTA_STOCK`; en MongoDB con filtro de guarda (`stock: { $gte: 2 }`) combinado con `$inc` atómico.
4. **¿Qué diferencia hay entre `COLLSCAN` e `IXSCAN` y cómo lo comprueban?**  
   `COLLSCAN` recorre toda la colección; `IXSCAN` consulta directamente uno de los 6 índices en memoria (verificado con `.explain("executionStats")`).
5. **¿Por qué MongoDB 4.4 y no 7.x en el laboratorio?**  
   Porque el host Proxmox usa un Intel Celeron 3855U sin instrucciones `AVX`, obligatorias desde MongoDB 5.0+.
