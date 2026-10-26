# Guia para Desarrolladores: Proyecto Sonido Vivo

**Asignatura:** Taller de Base de Datos (BDY1103)  
**Institucion:** Duoc UC  
**Proyecto:** Sonido Vivo — Tienda de Instrumentos Musicales y Audio Profesional (Viña del Mar)

---

## 1. Proposito del Documento

Esta guia proporciona a los desarrolladores e integrantes del equipo las directrices tecnicas, el orden de ejecucion de scripts, los estandares de codificacion y el flujo de trabajo colaborativo para operar sobre el repositorio de base de datos.

---

## 2. Mapa Estructural del Repositorio

El proyecto se encuentra estrictamente desacoplado por etapas de evaluacion academica y documentacion tecnica centralizada:

```text
taller-base-de-datos/
├── README.md                          <- Portada oficial y bienvenida al repositorio
├── .gitignore                         <- Exclusion de artefactos binarios y temporales
├── GEMINI.md                          <- Politicas de calidad y sobriedad de codigo
│
├── docs/                              <- Centro de documentacion tecnica y gestion
│   ├── BACKLOG.md                     <- Tablero Kanban, epicas e historias de usuario
│   ├── PRD.md                         <- Requerimientos de producto y modelo relacional
│   ├── GUIA_DESARROLLADORES.md        <- Este manual de induccion y operacion
│   ├── ARQUITECTURA_PLSQL.md          <- Principios de diseno modular en PL/SQL
│   └── estudio/                       <- Dossier de transicion conceptual y defensa
│       ├── 00 - Indice Material de Estudio Unidad 2.md
│       ├── 01 - Matriz de Transicion de Unidad 1 a Unidad 2.md
│       ├── 02 - Del Bloque RECORD y VARRAY al Package Modular.md
│       ├── 03 - Del Manejo de Excepciones a Triggers y Auditoria Autonoma.md
│       └── 04 - Guia Rapida y Banco de Preguntas para Defensa EP2.md
│
├── prueba parcial 1/                  <- Entregables cerrados de la Evaluacion Parcial 1
│   ├── docs/                          <- Pauta, informes formales, diapositivas y defensa
│   └── scripts/                       <- DDL base, DML y bloques anonimos ejecutables
│
└── prueba parcial 2/                  <- Espacio activo de la Evaluacion Parcial 2
    ├── scripts/                       <- Packages permanentes, triggers y pruebas
    ├── dashboard/                     <- Interfaz web local para administracion y monitoreo
    └── docs/                          <- Informe tecnico y rubrica formal de la EP2
```

---

## 3. Preparacion del Entorno de Base de Datos

### Requisitos Previos
- **Oracle Database:** Version 19c o 21c (Local XE o servidor institucional).
- **Herramienta Cliente:** Oracle SQL Developer v21+ o DBeaver.
- **Usuario/Esquema:** Usuario con privilegios de `CONNECT`, `RESOURCE` y cuota en `USERS`.

### Configuracion de Sesion en SQL Developer
Antes de ejecutar cualquier bloque o script de pruebas, asegurar la visibilidad del buffer de salida:
```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
```

### Orden Obligatorio de Carga de Scripts
1. **Paso 1 (Esquema Base):** Ejecutar `prueba parcial 1/scripts/01_esquema_y_datos.sql`.
   - Crea tablas maestras: `CATEGORIA`, `PRODUCTO`, `CLIENTE`, `VENTA`, `DETALLE_VENTA`, `LIQUIDACION_CLIENTE`, `LOG_ERRORES`.
   - Crea secuencias e inserta los datos iniciales de catalogo y clientes.
2. **Paso 2 (Artefactos de Prueba Parcial 2):** Ejecutar los scripts contenidos en `prueba parcial 2/scripts/`:
   - Creacion de tablas de auditoria (`AUDIT_PRECIOS_PRODUCTO`).
   - Compilacion de especificacion y cuerpo de `PKG_SONIDO_VIVO`.
   - Creacion de triggers de fila (`TRG_VALIDA_STOCK_VENTA`, `TRG_AUDIT_PRECIO_PRODUCTO`) y de sentencia.

---

## 4. Estandares de Desarrollo PL/SQL (Prueba Parcial 2)

Al implementar nuevos artefactos en `prueba parcial 2/scripts/`, respetar las siguientes directrices:

1. **Modularidad en Packages:**
   - Todo calculo reutilizable (validaciones, computo de tasas) debe formularse como `FUNCTION` con retorno unico.
   - Toda operacion transaccional masiva (`UPDATE`, `INSERT`) debe estructurarse como `PROCEDURE` con control de errores.
   - Las rutinas de uso interno (como insercion en tablas de log) deben encapsularse como subprogramas privados dentro del `PACKAGE BODY`.
2. **Manejo de Transacciones Autonomas:**
   - Los registros de fallas hacia `LOG_ERRORES` deben declararse con `PRAGMA AUTONOMOUS_TRANSACTION` para garantizar persistencia ante un `ROLLBACK` de la transaccion principal.
3. **Disparadores (Triggers) e Integridad:**
   - La validacion de stock previo a la venta debe ejecutarse como `BEFORE INSERT ON DETALLE_VENTA FOR EACH ROW`. Si no hay existencias, emitir `RAISE_APPLICATION_ERROR(-20001, '...')`.
   - Toda auditoria de precios debe capturar las pseudocolumnas `:OLD.precio` y `:NEW.precio`.
   - Para prevenir el error de Tabla Mutante (`ORA-04091`), ningun trigger de fila debe consultar ni modificar la tabla que origino el evento.

---

## 5. Politica de Git y Ramas

Para garantizar la integridad del repositorio y permitir el seguimiento automatico:

1. **Regla de Oro:** Prohibido realizar commits directamente sobre `main`.
2. **Ramas de Trabajo:** Derivar ramas a partir de `main` siguiendo la convencion:
   - `feat/<nombre-funcionalidad>` (ej. `feat/package-liquidacion`)
   - `fix/<modulo-corregido>` (ej. `fix/trigger-stock`)
   - `docs/<alcance-documento>` (ej. `docs/informe-ep2`)
3. **Estandar de Mensajes (Conventional Commits):**
   - Formato: `tipo(alcance): descripcion breve en minusculas`
   - Ejemplos:
     - `feat(paquetes): agregar cuerpo del paquete pkg_sonido_vivo`
     - `test(triggers): incorporar pruebas de stock insuficiente`
     - `docs(ep2): estructurar informe tecnico formal`

---

## 6. Preparacion para GitHub Projects Autopilot

Este repositorio esta preparado para operar con el sistema de seguimiento automatico **GitHub Projects Autopilot**, el cual sincroniza las tareas con el codigo en dos modalidades:

### A. Motor Continuo en GitHub Actions (en cada push)
- Monitorea los archivos en `prueba parcial 2/scripts/`, `prueba parcial 2/dashboard/` y `docs/`.
- Cuando detecta que los artefactos cumplen las firmas requeridas (ej. existencia de `PKG_SONIDO_VIVO`, triggers o panel web), cierra automaticamente el Issue correspondiente y mueve la tarjeta a `Done` en el tablero de GitHub Projects.
- Promueve la siguiente tarea pendiente publicando un comentario con la guia tecnica de implementacion.

### B. Asistente Local de Terminal (`progreso.ps1`)
- Permite a cualquier desarrollador verificar su progreso en consola ejecutando:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\progreso.ps1
  ```
- Muestra el porcentaje de avance, las tareas completadas y la instruccion detallada de lo que toca codificar a continuacion.
