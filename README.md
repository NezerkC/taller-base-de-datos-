# Sonido Vivo — Taller de Base de Datos (BDY1103)

Repositorio oficial del proyecto de base de datos para la tienda de instrumentos musicales y audio profesional **Sonido Vivo** (Viña del Mar), correspondiente a la asignatura **Taller de Base de Datos (BDY1103)** en Duoc UC.

---

## 1. Descripcion General y Contexto

El sistema implementa el modelo relacional, la logica de negocio transaccional y la arquitectura avanzada en **Oracle PL/SQL** para gestionar las operaciones de Sonido Vivo: gestion de clientes, categorias, catalogo de productos con control de stock, ventas, liquidaciones comerciales y auditoria de errores/precios.

El repositorio se encuentra estructurado en carpetas independientes por cada unidad academica, garantizando que los artefactos de la **Unidad 1** (Evaluacion Parcial 1) y los de la **Unidad 2** (Evaluacion Parcial 2) esten claramente separados y no colisionen.

---

## 2. Estructura del Repositorio

```text
taller-base-de-datos/
├── docs/                                          <- Gestion agil y especificaciones generales
│   ├── BACKLOG.md                                 <- Tablero Kanban y gestion de historias de usuario
│   └── PRD.md                                     <- Requerimientos de producto y modelo relacional
│
├── unidad 1/                                      <- Evaluacion Parcial 1 (EP1 - Finalizada)
│   ├── docs/                                      <- Informes tecnicos, presentaciones y pautas
│   │   ├── BDY1103 Evaluación Parcial 1...pdf     <- Pauta oficial del encargo EP1
│   │   ├── INFORME_TECNICO_EP1.md                 <- Informe academico formal (Markdown)
│   │   ├── Informe_EvaluacionParcial1...docx      <- Informe formateado para entrega (.docx)
│   │   ├── PRESENTACION_EJECUTIVA_EP1.md          <- Estructura de diapositivas para la defensa
│   │   ├── Presentacion_EP1...pptx                <- Presentacion visual (.pptx)
│   │   ├── Guia_Defensa_SonidoVivo_EP1.*          <- Banco de preguntas y respuestas orales
│   │   └── EXPLICACION_BLOQUES_CODIGO.md          <- Desglose tecnico de cada bloque PL/SQL
│   └── scripts/                                   <- Scripts y bloques anonimos ejecutables
│       ├── 01_esquema_y_datos.sql                 <- DDL (tablas/secuencias) y DML (datos iniciales)
│       ├── 02_bloque_record_varray.sql            <- Bloque anonimo con RECORD y VARRAY (IE1.1.1)
│       ├── 03_bloque_cursores_anidados.sql        <- Bloque anonimo con cursores anidados (IE1.2.1)
│       ├── 04_bloque_excepciones.sql              <- Control de excepciones Oracle y usuario (IE1.3.1)
│       ├── 05_triggers_propuestos.sql             <- Disparadores base preliminares
│       ├── parcial_1.sql                          <- Script unificado de entrega EP1
│       ├── sonido_vivo_completo.sql               <- Script maestro de instalacion total EP1
│       └── generate_*.py                          <- Utilidades para compilacion de informes
│
└── unidad 2/                                      <- Evaluacion Parcial 2 (EP2 - En Desarrollo)
    ├── docs/                                      <- Pautas, informe tecnico formal y guias EP2
    ├── scripts/                                   <- Packages modulares, suite de triggers y pruebas
    └── dashboard/                                 <- Panel web local de administracion y monitoreo
```

---

## 3. Guia de Orientacion y Ejecucion para el Equipo

Para ejecutar, probar o colaborar en el proyecto dentro de **Oracle SQL Developer** o **SQL*Plus**, sigue estos pasos en orden:

### Paso 1: Configurar la Conexion a Oracle
1. Abrir **Oracle SQL Developer**.
2. Crear o conectarse con un usuario/esquema dedicado (ej. `SONIDO_VIVO` o el usuario asignado por el docente).
3. Asegurarse de tener habilitada la salida de consola ejecutando:
   ```sql
   SET SERVEROUTPUT ON SIZE UNLIMITED;
   ```

### Paso 2: Cargar el Esquema Base (DDL y DML)
Antes de probar cualquier logica PL/SQL, es obligatorio cargar las tablas y los registros de prueba:
- Archivo: `unidad 1/scripts/01_esquema_y_datos.sql`
- Este script crea las tablas:
  - `CATEGORIA`
  - `PRODUCTO` (con control de stock y stock critico)
  - `CLIENTE` (con segmentacion de clientes)
  - `VENTA` y `DETALLE_VENTA`
  - `LIQUIDACION_CLIENTE`
  - `LOG_ERRORES`
- Ademas, crea las secuencias requeridas e inserta los datos iniciales de prueba.

### Paso 3: Trabajo en la Unidad 1 (Consulta y Repaso)
Los scripts dentro de `unidad 1/scripts/` son bloques anonimos ejecutables de forma independiente:
- `02_bloque_record_varray.sql`: Procesa liquidaciones calculando tasas en memoria sin I/O excesivo.
- `03_bloque_cursores_anidados.sql`: Muestra el recorrido jerarquico de clientes y sus compras correspondientes.
- `04_bloque_excepciones.sql`: Demuestra como capturar `NO_DATA_FOUND` y disparar excepciones de usuario (`RAISE`) guardando la traza en `LOG_ERRORES`.

---

## 4. Alcance y Objetivos de la Unidad 2 (Sprint Activo)

En la Unidad 2 dejamos atras los bloques anonimos y evolucionamos la base de datos a **subprogramas almacenados permanentes** y **automatizaciones reactivas**:

1. **Package Modular (`PKG_SONIDO_VIVO`):**
   - **Especificacion (`PACKAGE`):** Define los servicios publicos:
     - Constantes de negocio (tasas de descuento e IVA).
     - Funcion `fn_validar_email`: Validador de formato de correos electronicos.
     - Funcion `fn_calcular_descuento`: Calculo automatico segun segmento de cliente y monto.
     - Procedimiento `sp_reajustar_precios`: Actualizacion porcentual masiva del catalogo de instrumentos.
     - Procedimiento `sp_liquidar_clientes`: Cierre mensual de liquidaciones y registro historico.
   - **Cuerpo (`PACKAGE BODY`):** Implementacion de las funciones y procedimientos, encapsulando el procedimiento privado `sp_registrar_log_interno` con `PRAGMA AUTONOMOUS_TRANSACTION` para auditoria blindada.

2. **Suite de Triggers (Reglas de Negocio en Base de Datos):**
   - **Trigger a nivel de fila (`BEFORE INSERT ON DETALLE_VENTA`):** Valida si hay stock suficiente antes de registrar una compra; si no hay stock, aborta la operacion con `RAISE_APPLICATION_ERROR`.
   - **Trigger a nivel de fila (`AFTER UPDATE OF precio ON PRODUCTO`):** Registra cualquier variacion de precios en la tabla historica `AUDIT_PRECIOS_PRODUCTO` capturando `:OLD` y `:NEW`.
   - **Trigger a nivel de sentencia:** Control operacional de modificaciones en lote.

3. **Dashboard Web Local (Panel de Administracion):**
   - Ubicado en `unidad 2/dashboard/`.
   - No depende de Oracle APEX ni de configuraciones de nube.
   - Permite visualizar en tiempo real el inventario, el historico de precios, las liquidaciones y la consola de auditoria de disparos de triggers.

---

## 5. Protocolo de Trabajo en Git y Colaboracion

Para mantener el repositorio limpio y evitar conflictos entre companeros:

1. **Prohibido hacer commits directamente en `main`:**
   - La rama `main` almacena unicamente versiones estables y entregadas.
   - Actualmente estamos trabajando en la rama: `feat/unidad-2-packages-triggers-apex`.

2. **Creacion de Ramas de Trabajo:**
   - Cada tarea debe realizarse en una rama derivada:
     ```bash
     git switch -c feat/nombre-tarea
     ```
   - Tipos de rama recomendados:
     - `feat/` : Nuevos scripts SQL, paquetes o componentes del dashboard.
     - `fix/` : Correccion de errores en consultas o sintaxis PL/SQL.
     - `docs/` : Actualizaciones en informes tecnicos o pautas.

3. **Estandar de Mensajes de Commit (Conventional Commits):**
   - Formato: `tipo(alcance): descripcion breve en minusculas`
   - Ejemplos:
     - `feat(unidad-2): agregar especificacion y cuerpo de pkg_sonido_vivo`
     - `feat(triggers): implementar auditoria de precios en audit_precios_producto`
     - `docs(unidad-2): estructurar informe tecnico formal ep2`

4. **Regla de Ubicacion de Archivos:**
   - Todo nuevo script, reporte o archivo relacionado con la Evaluacion Parcial 2 debe guardarse obligatoriamente dentro del directorio `unidad 2/`.
   - No guardar archivos sueltos en la raiz del proyecto.
