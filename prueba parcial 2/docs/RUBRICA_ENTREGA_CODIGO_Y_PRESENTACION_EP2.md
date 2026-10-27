# Rubrica Oficial y Pauta de Evaluacion Parcial 2 (EP2)

**Institucion:** Duoc UC  
**Escuela:** Escuela de Informatica y Telecomunicaciones  
**Asignatura:** Taller de Base de Datos (BDY1103)  
**Ponderacion Asignatura:** 40% de la nota final  
**Unidad de Aprendizaje:** Experiencia de Aprendizaje 2 (EA2) - Implementacion de programas PL/SQL en una base de datos  
**Documento Oficial de Origen:** [BDY1103_Evaluacion_Parcial_2_EE_EP_Estudiante.pdf](file:///c:/Users/NezerkC/OneDrive/Escritorio/instituto/taller%20base%20de%20datos/prueba%20parcial%202/docs/pauta/BDY1103_Evaluacion_Parcial_2_EE_EP_Estudiante.pdf)

---

## 1. Estructura General de la Evaluacion

La Evaluacion Parcial 2 se compone de dos situaciones evaluativas complementarias:

| Situacion Evaluativa | Modalidad | Ponderacion Interna | Entregable Asociado en Repositorio |
| :--- | :--- | :--- | :--- |
| **Situacion Evaluativa 1** | Entrega de Encargo (Informe Tecnico + Codigo Fuente PL/SQL) | 40% de EP2 | [INFORME_EVALUACION_PARCIAL_2.md](file:///c:/Users/NezerkC/OneDrive/Escritorio/instituto/taller%20base%20de%20datos/prueba%20parcial%202/docs/INFORME_EVALUACION_PARCIAL_2.md) y [01_paquetes_y_triggers_ep2.sql](file:///c:/Users/NezerkC/OneDrive/Escritorio/instituto/taller%20base%20de%20datos/prueba%20parcial%202/scripts/01_paquetes_y_triggers_ep2.sql) |
| **Situacion Evaluativa 2** | Presentacion Ejecutiva y Defensa Oral Individual | 60% de EP2 | [GUIA_DEFENSA_PRESENTACION_EP2.md](file:///c:/Users/NezerkC/OneDrive/Escritorio/instituto/taller%20base%20de%20datos/prueba%20parcial%202/docs/GUIA_DEFENSA_PRESENTACION_EP2.md) |

---

## 2. Requerimientos de la Situacion Evaluativa 1: Entrega de Encargo (Codigo e Informe)

El encargo consiste en el desarrollo formal de la solucion en base de datos para el caso de negocio **Sonido Vivo**, acompanado de un informe tecnico que debe respetar obligatoriamente la siguiente estructura:

### Estructura Obligatoria del Informe Tecnico
1. **Introduccion:**
   - **Descripcion del Proyecto:** Breve descripcion del proyecto Sonido Vivo, su objetivo y como los distintos objetos PL/SQL se utilizaran para cumplir dicho objetivo.
   - **Alcance:** Definicion del alcance y los componentes del negocio que se veran beneficiados (gestion comercial, inventario, auditoria de listas de precios y liquidaciones masivas).
   - **Tecnologias Utilizadas:** Oracle Database 19c/21c, PL/SQL Developer / SQL Developer, backend REST en Python/FastAPI y frontend en React.
2. **Desarrollo de Procedimientos y Funciones:**
   - Definicion, caracteristicas, ventajas y desventajas de cada uno.
   - Proposito especifico en el contexto de Sonido Vivo.
   - Demostracion practica de procedimientos con y sin parametros (`sp_reajustar_precios`, `sp_liquidar_clientes`, `sp_actualizar_estadisticas_inventario`).
3. **Desarrollo de Packages:**
   - Definicion, caracteristicas y ventajas al organizar el codigo modularmente.
   - Relacion de los packages con procedimientos y funciones (especificacion publica vs cuerpo privado).
   - Demostracion del package `PKG_SONIDO_VIVO`, destacando el encapsulamiento del procedimiento privado de bitacora autonoma `sp_registrar_log_interno`.
4. **Desarrollo de Triggers:**
   - Definicion, caracteristicas, ventajas y riesgos (analisis de tablas mutantes y sobrecosto por fila).
   - Proposito en el negocio: validacion de existencias, auditoria forense y bitacora de operaciones.
   - Demostracion de triggers a nivel de fila (`TRG_VALIDA_Y_DESCUENTA_STOCK`, `TRG_AUDITA_PRECIO_PRODUCTO`) y a nivel de sentencia (`TRG_CONTROL_OPERACION_VENTAS`).
5. **Conclusion:**
   - Resumen de los puntos principales.
   - Impacto del proyecto en la consistencia de datos y rendimiento.
   - Recomendaciones de extension futura (conectores REST, orquestacion de microservicios).
6. **Anexos:**
   - Script SQL completo reproducible.
   - Diagrama Entidad-Relacion (ERD) y flujos logicos en formato Mermaid.

---

## 3. Requerimientos de la Situacion Evaluativa 2: Presentacion y Defensa Oral

Durante la defensa individual ante la comision evaluadora, cada estudiante debe:
1. **Inicio de Presentacion:** Explicar el problema de negocio abordado (perdidas operacionales por ventas sin inventario, desfase de precios en mostrador y demoras en liquidacion de comisiones a clientes mayoristas), demostrando entendimiento profundo y estructurado.
2. **Justificacion de Procedimientos y Funciones:** Argumentar por que una operacion se diseno como procedimiento y otra como funcion pura, justificando su interoperabilidad en sentencias `SELECT`.
3. **Justificacion de Packages:** Argumentar la encapsulacion, separacion de interfaz y beneficios en la memoria compartida (*Shared Pool* de Oracle).
4. **Justificacion de Triggers:** Explicar el disparo reactivo a nivel de fila frente a nivel de sentencia, prevencion de mutacion de tablas (`ORA-04091`) y uso de `RAISE_APPLICATION_ERROR`.
5. **Cierre:** Conclusiones ejecutivas y respuesta a interrogantes tecnicas del docente.

---

## 4. Matriz Completa de la Rubrica Oficial (Escala de Calificacion)

### Criterios Generales de Nivel de Logro
- **Muy buen desempeno (100%):** Demuestra desempeno destacado, evidenciando el logro exhaustivo de todos los aspectos evaluados.
- **Buen desempeno (80%):** Demuestra alto desempeno con pequenas omisiones o dificultades menores.
- **Desempeno aceptable (60%):** Demuestra desempeno competente con elementos basicos, pero con omisiones o errores identificables.
- **Desempeno incipiente (30%):** Presenta importantes omisiones o fallas que impiden considerarlo competente.
- **Desempeno no logrado (0%):** Presenta ausencia total o desarrollo incorrecto.

---

### Tabla Desglosada de Indicadores de Evaluacion

| Indicador | Ambito | Ponderacion | Muy Buen Desempeno (100%) | Buen Desempeno (80%) | Desempeno Aceptable (60%) | Desempeno Incipiente (30%) | No Logrado (0%) |
| :--- | :--- | :---: | :--- | :--- | :--- | :--- | :--- |
| **IE2.1.1** | **SE1 (Encargo):** Construccion de Procedimientos | **10%** | Construye correctamente procedimientos con y sin parametros para procesar informacion masiva en PL/SQL y SQL. | Construye procedimientos con y sin parametros, pero con pequenas omisiones o errores menores. | Construye procedimientos con y sin parametros, pero con omisiones o dificultades notorias. | Construye procedimientos con importantes fallas que no evidencian las bases del indicador. | No construye procedimientos o lo realiza de forma incorrecta. |
| **IE2.1.2** | **SE1 (Encargo):** Justificacion de Procedimientos | **15%** | Justifica correctamente la implementacion de procedimientos con y sin parametros para procesar informacion masiva en PL/SQL y SQL. | Justifica la implementacion de procedimientos, pero con pequenas omisiones o dificultades menores. | Justifica la implementacion de procedimientos, pero con omisiones o imprecisiones notorias. | Justifica con importantes deficiencias que no permiten validar el fundamento tecnico. | No justifica la implementacion de procedimientos o lo realiza de forma incorrecta. |
| **IE2.2.1** | **SE1 (Encargo):** Construccion de Packages | **10%** | Construye correctamente packages con constructores publicos y privados en la base de datos para una solucion integral o consumo externo. | Construye packages con constructores publicos y privados, pero con pequenas omisiones o errores menores. | Construye packages con constructores publicos y privados, pero con omisiones o dificultades notorias. | Construye packages con importantes fallas estructurales o sin distincion publico/privado. | No construye packages con constructores publicos y privados o lo hace incorrectamente. |
| **IE2.3.1** | **SE1 (Encargo):** Construccion de Triggers | **10%** | Construye correctamente triggers asociados a tablas que controlan acciones a nivel de sentencia y de fila para una solucion integral. | Construye triggers de sentencia y fila, pero con pequenas omisiones o dificultades menores. | Construye triggers de sentencia y fila, pero con omisiones o errores en los eventos de disparo. | Construye triggers con fallas graves que impiden el control transaccional adecuado. | No construye triggers de sentencia y fila o lo realiza de forma incorrecta. |
| **IE2.1.3** | **SE2 (Presentacion):** Construccion de Funciones | **10%** | Construye y expone correctamente funciones almacenadas con y sin parametros para procesar informacion y ser usadas en PL/SQL y `SELECT` SQL. | Construye y expone funciones con y sin parametros, pero presentando pequenas omisiones. | Construye y expone funciones con y sin parametros, pero con omisiones o errores en su uso en SQL. | Presenta funciones con importantes fallas que no demuestran su aplicabilidad practica. | No construye ni demuestra funciones almacenadas o lo realiza incorrectamente. |
| **IE2.1.4** | **SE2 (Presentacion):** Justificacion de Funciones | **15%** | Justifica correctamente la implementacion de funciones con y sin parametros para procesar informacion masiva y ser usadas en PL/SQL y SQL. | Justifica la implementacion de funciones, pero presentando pequenas omisiones tecnicas. | Justifica la implementacion de funciones, pero con omisiones o argumentos debiles. | Justifica con importantes deficiencias conceptuales sobre el uso de funciones frente a procedimientos. | No justifica la implementacion de funciones almacenadas o lo realiza de forma incorrecta. |
| **IE2.2.2** | **SE2 (Presentacion):** Justificacion de Packages | **15%** | Justifica correctamente la implementacion de packages con constructores publicos y privados para una solucion integral de procesamiento. | Justifica la implementacion de packages modulares, pero presentando pequenas omisiones. | Justifica la implementacion de packages, pero con omisiones en la distincion publico/privado o memoria. | Justifica con importantes omisiones tecnicas sobre modularidad y encapsulamiento. | No justifica la implementacion de packages o lo realiza de forma incorrecta. |
| **IE2.3.2** | **SE2 (Presentacion):** Justificacion de Triggers | **15%** | Justifica correctamente la implementacion de triggers de sentencia y de fila para control de negocio y auditoria de informacion. | Justifica la implementacion de triggers, pero presentando pequenas omisiones tecnicas. | Justifica la implementacion de triggers, pero con omisiones sobre el ambito (fila vs sentencia). | Justifica con importantes errores conceptuales sobre eventos y consecuencias transaccionales. | No justifica la implementacion de triggers o lo realiza de forma incorrecta. |
| **TOTAL** | **Calificacion Final EP2** | **100%** | **Nota 7.0 (Cumplimiento sobresaliente en Encargo Escrito y Defensa Oral)** | **Nota 5.6 - 6.0** | **Nota 4.0 - 5.0** | **Nota 2.0 - 3.5** | **Nota 1.0** |

---

## 5. Mapeo de Cumplimiento en el Proyecto Sonido Vivo

| Indicador Oficial | Objeto PL/SQL Implementado | Evidencia en Codigo | Evidencia en Documentacion |
| :--- | :--- | :--- | :--- |
| **IE2.1.1** (Proc. con/sin params) | `sp_reajustar_precios` (con params), `sp_liquidar_clientes` (con params), `sp_actualizar_estadisticas_inventario` (sin params) | Lineas 85-170 de `01_paquetes_y_triggers_ep2.sql` | Seccion 2 de `INFORME_EVALUACION_PARCIAL_2.md` |
| **IE2.1.2** (Justificacion Proc.) | Procedimientos masivos con gestion de transacciones y cursores explicitos | Bloque de pruebas 2 de `01_paquetes_y_triggers_ep2.sql` | Seccion 2.3 de `INFORME_EVALUACION_PARCIAL_2.md` |
| **IE2.2.1** (Packages pub/priv) | `PKG_SONIDO_VIVO` con constructor privado `sp_registrar_log_interno` (`PRAGMA AUTONOMOUS_TRANSACTION`) | Lineas 40-75 (Spec) y 80-280 (Body) de `01_paquetes_y_triggers_ep2.sql` | Seccion 3 de `INFORME_EVALUACION_PARCIAL_2.md` |
| **IE2.3.1** (Triggers fila/sentencia) | `TRG_VALIDA_Y_DESCUENTA_STOCK` (fila), `TRG_AUDITA_PRECIO_PRODUCTO` (fila), `TRG_CONTROL_OPERACION_VENTAS` (sentencia) | Lineas 285-410 de `01_paquetes_y_triggers_ep2.sql` | Seccion 4 de `INFORME_EVALUACION_PARCIAL_2.md` |
| **IE2.1.3** (Funciones con/sin params) | `fn_calcular_descuento` (con params), `fn_obtener_umbral_descuento` (sin params) utilizables en `SELECT` | Lineas 175-235 de `01_paquetes_y_triggers_ep2.sql` y Bloque de pruebas 1 | Seccion 2.2 de `INFORME_EVALUACION_PARCIAL_2.md` y Slide 2 de `GUIA_DEFENSA_PRESENTACION_EP2.md` |
| **IE2.1.4** (Justificacion Funciones) | Pureza de funciones sin efectos laterales DDL/DML para consultas agregadas SQL | Consultas `SELECT PKG_SONIDO_VIVO.fn_calcular_descuento(...) FROM PRODUCTO` | Slide 2 y Banco de Preguntas en `GUIA_DEFENSA_PRESENTACION_EP2.md` |
| **IE2.2.2** (Justificacion Packages) | Carga unica en memoria (*Shared Pool*), modularidad, ocultamiento de detalles sensibles | Encapsulamiento del procedimiento de auditoria interna | Slide 3 y Banco de Preguntas en `GUIA_DEFENSA_PRESENTACION_EP2.md` |
| **IE2.3.2** (Justificacion Triggers) | Prevencion de tablas mutantes, validacion atomica con `RAISE_APPLICATION_ERROR` | Manejo de excepciones -20001 y auditoria de precios sin sobrecosto | Slide 4 y Banco de Preguntas en `GUIA_DEFENSA_PRESENTACION_EP2.md` |
