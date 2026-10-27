# Sonido Vivo — Taller de Base de Datos (BDY1103)

Repositorio oficial del proyecto de base de datos para la tienda de instrumentos musicales y audio profesional **Sonido Vivo** (Viña del Mar), correspondiente a la asignatura **Taller de Base de Datos (BDY1103)** en Duoc UC.

---

## 1. Descripcion General y Contexto

El sistema implementa el modelo relacional, la logica de negocio transaccional y la arquitectura avanzada en **Oracle PL/SQL** para gestionar las operaciones de Sonido Vivo: gestion de clientes, categorias, catalogo de productos con control de stock, ventas, liquidaciones comerciales y auditoria de errores/precios.

El repositorio se encuentra estructurado en carpetas independientes para cada hito de evaluacion, con una carpeta central de documentacion tecnica en formato Markdown para soporte integral a los desarrolladores del equipo:

- **`prueba parcial 1/`:** Todo el material, scripts DDL/DML, bloques anonimos y entregables correspondientes a la Evaluacion Parcial 1.
- **`prueba parcial 2/`:** Directorios de desarrollo activo (scripts de paquetes, triggers y dashboard web local) correspondientes a la Evaluacion Parcial 2.
- **`docs/`:** Centro neurlogico de documentacion Markdown (`.md`) para el equipo de desarrolladores (manuales, arquitectura, transicion de unidades, backlog agil y PRD).

---

## 2. Estructura del Repositorio

```text
taller-base-de-datos/
├── README.md                          <- Portada oficial y bienvenida al repositorio
├── .gitignore                         <- Exclusion de artefactos binarios y temporales
├── GEMINI.md                          <- Politicas de calidad y sobriedad de codigo
│
├── docs/                              <- Documentacion tecnica Markdown para desarrolladores
│   ├── BACKLOG.md                     <- Tablero Kanban, epicas e historias de usuario
│   ├── PRD.md                         <- Requerimientos de producto y modelo relacional
│   ├── GUIA_DESARROLLADORES.md        <- Manual de inicio rapido y flujo de desarrollo
│   ├── ARQUITECTURA_PLSQL.md          <- Diseno tecnico (Packages, Triggers, ORA-04091)
│   ├── CASOS_NEGOCIO_ADICIONALES_PROPUESTOS.md <- Reglas de negocio desacopladas
│   └── estudio/                       <- Dossier teorico-practico y banco de preguntas EP2
│       ├── 00 - Indice Material de Estudio Unidad 2.md
│       ├── 01 - Matriz de Transicion de Unidad 1 a Unidad 2.md
│       ├── 02 - Del Bloque RECORD y VARRAY al Package Modular.md
│       ├── 03 - Del Manejo de Excepciones a Triggers y Auditoria Autonoma.md
│       └── 04 - Guia Rapida y Banco de Preguntas para Defensa EP2.md
│
├── prueba parcial 1/                  <- Evaluacion Parcial 1 (EP1 - Finalizada)
│   ├── docs/                          <- Documentacion tecnica fuente (Markdown)
│   │   ├── INFORME_TECNICO_EP1.md                 <- Informe academico formal (Markdown)
│   │   ├── PRESENTACION_EJECUTIVA_EP1.md          <- Estructura de diapositivas para la defensa
│   │   ├── EXPLICACION_BLOQUES_CODIGO.md          <- Desglose tecnico de cada bloque PL/SQL
│   │   ├── pauta/                                 <- Documentos oficiales Duoc UC
│   │   │   └── BDY1103_Evaluacion_Parcial_1_EE_EP_Estudiante.pdf
│   │   └── entregables/                           <- Archivos finales compilados (Word, PDF, PPTX, HTML)
│   │       ├── Informe_EvaluacionParcial1_BDY1103_SonidoVivo.docx
│   │       ├── Presentacion_EP1_BDY1103_SonidoVivo.pptx
│   │       ├── Guia_Defensa_SonidoVivo_EP1.pdf
│   │       ├── Guia_Defensa_SonidoVivo_EP1.docx
│   │       ├── Guia_Defensa_SonidoVivo_EP1.html
│   │       └── Explicacion_Paso_a_Paso_Bloques_PLSQL.docx
│   └── scripts/                                   <- Scripts y bloques PL/SQL ejecutables
│       ├── 01_esquema_y_datos.sql                 <- DDL (tablas/secuencias) y DML (datos iniciales)
│       ├── 02_bloque_record_varray.sql            <- Bloque anonimo con RECORD y VARRAY (IE1.1.1)
│       ├── 03_bloque_cursores_anidados.sql        <- Bloque anonimo con cursores anidados (IE1.2.1)
│       ├── 04_bloque_excepciones.sql              <- Control de excepciones Oracle y usuario (IE1.3.1)
│       ├── 05_triggers_propuestos.sql             <- Disparadores base preliminares
│       ├── sonido_vivo_completo.sql               <- Script maestro de instalacion total EP1
│       ├── tools/                                 <- Generadores Python de reportes y documentacion
│       │   ├── generate_code_blocks_doc.py
│       │   ├── generate_pdf_guide.py
│       │   └── generate_word_guide.py
│       └── archivados/                            <- Versiones preliminares y borradores historicos
│           └── parcial_1.sql                      <- Borrador inicial previo a modularizacion
│
└── prueba parcial 2/                  <- Evaluacion Parcial 2 (EP2 - En Desarrollo)
    ├── docs/                                      <- Pautas, informe tecnico formal y rubrica EP2
    │   ├── INFORME_EVALUACION_PARCIAL_2.md
    │   └── GUIA_DEFENSA_PRESENTACION_EP2.md
    ├── scripts/                                   <- Packages modulares, suite de triggers y pruebas
    │   └── 01_paquetes_y_triggers_ep2.sql
    └── dashboard/                                 <- Panel web local de administracion y monitoreo
        └── .gitkeep
```

---

## 3. Guia de Orientacion y Ejecucion para el Equipo

Para ejecutar, probar o colaborar en el proyecto dentro de **Oracle SQL Developer** o **SQL*Plus**, sigue estos pasos en orden:

### Paso 1: Configurar la Conexion a Oracle
1. Abrir **Oracle SQL Developer**.
2. Conectarse al esquema de trabajo asignado (ej. `SONIDO_VIVO`).
3. Habilitar la salida en consola:
   ```sql
   SET SERVEROUTPUT ON SIZE UNLIMITED;
   ```

### Paso 2: Cargar el Esquema Base (DDL y DML)
Antes de probar cualquier logica PL/SQL, es obligatorio cargar las tablas y los registros de prueba:
- Archivo: `prueba parcial 1/scripts/01_esquema_y_datos.sql`
- Este script crea las tablas:
  - `CATEGORIA`
  - `PRODUCTO` (con control de stock y stock critico)
  - `CLIENTE` (con segmentacion de clientes)
  - `VENTA` y `DETALLE_VENTA`
  - `LIQUIDACION_CLIENTE`
  - `LOG_ERRORES`
- Ademas, crea las secuencias requeridas e inserta los datos iniciales de prueba.

### Paso 3: Revisar la Documentacion de Apoyo
Antes de codificar, consulta la carpeta `docs/`:
- [GUIA_DESARROLLADORES.md](file:///c:/Users/NezerkC/OneDrive/Escritorio/instituto/taller%20base%20de%20datos/docs/GUIA_DESARROLLADORES.md): Detalle operativo paso a paso.
- [ARQUITECTURA_PLSQL.md](file:///c:/Users/NezerkC/OneDrive/Escritorio/instituto/taller%20base%20de%20datos/docs/ARQUITECTURA_PLSQL.md): Diagrama y reglas del paquete y los disparadores.
- `docs/estudio/`: Explicacion de como se refactoriza cada bloque de la EP1 a la EP2.

---

## 4. Alcance y Objetivos de la Prueba Parcial 2 (Sprint Activo)

En la Prueba Parcial 2 evolucionamos la base de datos hacia **subprogramas almacenados permanentes** y **automatizaciones reactivas**:

1. **Package Modular (`PKG_SONIDO_VIVO`):**
   - **Especificacion (`PACKAGE`):** Define los servicios publicos:
     - Constantes de negocio (tasas de descuento e IVA).
     - Funcion `fn_validar_email`: Validador sintactico de correos electronicos.
     - Funcion `fn_calcular_descuento`: Calculo automatico segun segmento de cliente y monto.
     - Procedimiento `sp_reajustar_precios`: Actualizacion porcentual masiva del catalogo.
     - Procedimiento `sp_liquidar_clientes`: Cierre mensual de liquidaciones y registro historico.
   - **Cuerpo (`PACKAGE BODY`):** Implementacion de las funciones y procedimientos, encapsulando el procedimiento privado `sp_registrar_log_interno` con `PRAGMA AUTONOMOUS_TRANSACTION`.

2. **Suite de Triggers (Reglas de Negocio en Base de Datos):**
   - **Trigger de fila (`BEFORE INSERT ON DETALLE_VENTA`):** Valida si hay stock suficiente antes de registrar una compra; si no hay stock, aborta la operacion con `RAISE_APPLICATION_ERROR`.
   - **Trigger de fila (`AFTER UPDATE OF precio ON PRODUCTO`):** Registra cualquier variacion de precios en la tabla historica `AUDIT_PRECIOS_PRODUCTO` capturando `:OLD` y `:NEW`.
   - **Trigger de sentencia:** Control operacional de modificaciones en lote.

3. **Dashboard Web Local (Panel de Administracion):**
   - Ubicado en `prueba parcial 2/dashboard/`.
   - Autocontenido (HTML/CSS/JS), sin dependencias pesadas de APEX.
   - Permite visualizar en tiempo real el inventario, los historicos de precios, las liquidaciones y la consola de auditoria.

---

## 5. Protocolo de Trabajo en Git y Colaboracion

1. **Prohibido hacer commits directamente en `main`:**
   - La rama `main` almacena unicamente versiones estables y entregadas.
   - Todo trabajo se realiza en ramas secundarias derivadas (`feat/`, `fix/`, `docs/`).
2. **Estandar de Mensajes (Conventional Commits):**
   - Formato: `tipo(alcance): descripcion breve en minusculas`
   - Ejemplos:
     - `feat(paquetes): implementar cuerpo de pkg_sonido_vivo`
     - `feat(triggers): agregar auditoria en audit_precios_producto`
     - `docs(guia): actualizar guia de desarrolladores`
3. **Ubicacion de Archivos:**
   - Todo nuevo script de base de datos de la EP2 debe residir en `prueba parcial 2/scripts/`.
   - Toda interfaz o componente del dashboard debe guardarse en `prueba parcial 2/dashboard/`.
   - Toda documentacion tecnica Markdown debe agregarse en `docs/`.

---

## 6. Automatizacion con GitHub Projects Autopilot

Este repositorio esta disenado para integrarse con el skill **GitHub Projects Autopilot**, que proporciona:
- **Sincronizacion continua en GitHub Actions:** Escanea el codigo fuente en cada push a `main`, verifica los criterios de aceptacion de cada tarea y cierra/promueve los Issues automaticamente en el tablero de GitHub Projects.
- **Asistente local de progreso (`progreso.ps1`):** Script de consola para verificar en cualquier momento el estado de avance y la siguiente tarea recomendada por la IA.
