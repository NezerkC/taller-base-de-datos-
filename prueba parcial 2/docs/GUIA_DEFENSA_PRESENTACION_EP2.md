# Guia Estrategica de Defensa Oral y Presentacion Ejecutiva (EP2)

**Asignatura:** Taller de Base de Datos (BDY1103)  
**Evaluacion:** Evaluacion Parcial N° 2 (Situacion Evaluativa 2 - Presentacion Ejecutiva)  
**Ponderacion:** 60% de la nota de la Evaluacion Parcial 2 (40% de la nota final del semestre)  
**Caso de Negocio:** Sonido Vivo — Gestion de Instrumentos Musicales y Audio (Viña del Mar)  

---

## 1. Estructura Sugerida de Diapositivas (Slide by Slide)

Para asegurar una presentacion concisa, profesional y de alto impacto visual sin sobrecargar texto, se recomienda una presentacion de 6 diapositivas:

### Diapositiva 1: Portada y Contexto del Problema (Letra a de la Pauta)
- **Titulo:** Optimizacion Transaccional y Reglas de Negocio en Oracle PL/SQL para Sonido Vivo.
- **Subtitulo:** Evaluacion Parcial 2 - BDY1103.
- **Contenido Clave (Viñetas):**
  - **Empresa:** Sonido Vivo (Viña del Mar), venta minorista y mayorista de instrumentos y audio.
  - **Problema de Negocio:**
    1. Sobreventas y quiebres de bodega por falta de validacion atomica concurrente.
    2. Proceso manual y propenso a errores en el calculo de descuentos por volumen y categorias de clientes.
    3. Falta de trazabilidad y auditoria cuando los precios de catálogo eran alterados.
  - **Solucion de Arquitectura:** Trasladar la logica de negocio desde aplicaciones perifericas hacia el nucleo transaccional de Oracle mediante programas almacenados y triggers.

### Diapositiva 2: Procedimientos y Funciones Almacenadas (Letra b de la Pauta)
- **Titulo:** Procedimientos y Funciones: Procesamiento Masivo y Calculo Determinista.
- **Contenido Clave (Grafico / Comparativa):**
  - **Procedimientos (Transaccionales y Masivos):**
    - `sp_reajustar_precios(p_porcentaje, p_id_categoria, OUT p_filas)`: Actualizacion masiva con parametro de salida.
    - `sp_liquidar_clientes(p_periodo, OUT p_filas)`: Cursor explicito para cierre mensual contable.
    - `sp_actualizar_estadisticas_inventario`: Procedimiento sin parametros para consolidacion nocturna.
  - **Funciones (Reusabilidad y SQL Puro):**
    - `fn_calcular_descuento(p_total, p_tipo_cliente)`: Funcion con parametros que respeta normas WNDS; puede invocarse directamente dentro de un `SELECT`.
    - `fn_obtener_umbral_descuento()`: Funcion sin parametros que centraliza el valor base ($200.000).
- **Justificacion Tecnica:** Se evita el trafico innecesario de red (I/O). El calculo ocurre donde residen los datos.

### Diapositiva 3: Arquitectura Modular con Packages (Letra c de la Pauta)
- **Titulo:** Package PKG_SONIDO_VIVO: Modularidad, Seguridad y Rendimiento.
- **Contenido Clave (Diagrama de Encapsulamiento):**
  - **Interfaz Publica (Specification):** Publica unicamente las funciones y procedimientos que la aplicacion necesita consumir.
  - **Implementacion y Miembro Privado (Body):**
    - Constructor privado `sp_registrar_log_interno`: Encapsulado, inaccesible desde el exterior.
    - Implementa `PRAGMA AUTONOMOUS_TRANSACTION`: Si la transaccion del usuario falla y hace `ROLLBACK`, el registro de error en `LOG_ERRORES` se persiste intacto con su propio `COMMIT`.
- **Justificacion Tecnica:**
  - *Rendimiento:* Carga en bloque en la `Shared Pool` (SGA) en la primera invocacion.
  - *Seguridad:* Los usuarios reciben privilegios `EXECUTE` sobre el paquete, nunca acceso directo a modificar las tablas criticas.

### Diapositiva 4: Triggers Reactivos y Prevencion de Quiebres (Letra d de la Pauta)
- **Titulo:** Triggers: Integridad Inquebrantable de Bodega y Auditoria Forense.
- **Contenido Clave:**
  - **Nivel de Fila (`FOR EACH ROW`):**
    - `TRG_VALIDA_Y_DESCUENTA_STOCK`: Disparador `BEFORE INSERT ON DETALLE_VENTA`. Si `:NEW.cantidad > stock`, lanza `RAISE_APPLICATION_ERROR(-20001)` y bloquea la orden antes de que toque la tabla. Si hay stock, lo descuenta de inmediato.
    - `TRG_AUDITA_PRECIO_PRODUCTO`: Disparador `AFTER UPDATE OF precio ON PRODUCTO`. Utiliza la clausula `WHEN (NEW.precio <> OLD.precio)` para evitar registros nulos e inserta el historico en `AUDIT_PRECIOS_PRODUCTO`.
  - **Nivel de Sentencia (sin `FOR EACH ROW`):**
    - `TRG_CONTROL_OPERACION_VENTAS`: Disparador `AFTER INSERT OR UPDATE OR DELETE ON VENTA`. Audita la ejecucion masiva global en `CONTROL_OPERACION_VENTAS`.
- **Justificacion Tecnica:** Los triggers son automaticos e invisibles; ninguna aplicacion o usuario puede evadirlos, garantizando la consistencia ACID de la base de datos.

### Diapositiva 5: Demostracion de Resultados y Validacion en Vivo
- **Titulo:** Evidencia de Ejecucion y Auditoria.
- **Contenido Clave (Capturas / Resultados SQL):**
  - Salida de la consulta `SELECT` demostrando el uso de `fn_calcular_descuento` en SQL.
  - Salida de `AUDIT_PRECIOS_PRODUCTO` mostrando el precio previo y nuevo tras ejecutar `sp_reajustar_precios`.
  - Captura del error `-20001` al intentar vender mas instrumentos de los que existen en stock.

### Diapositiva 6: Conclusiones e Impacto (Letra e de la Pauta)
- **Titulo:** Conclusiones y Extension a Aplicaciones Reales.
- **Contenido Clave:**
  - **Impacto:** Sonido Vivo opera ahora con cero sobreventas en bodega, trazabilidad completa de cambios de valor y liquidaciones automaticas de clientes.
  - **Interoperabilidad:** El paquete `PKG_SONIDO_VIVO` fue disenado para ser consumido por un backend REST autohospedado (FastAPI) y administrado visualmente desde el panel React (`sonido-vivo-react`).

---

## 2. Guion de Discurso para la Exposicion Individual

### Apertura (1 minuto)
> "Buenas tardes profesor. Hoy presento la solucion de ingenieria de base de datos para la empresa Sonido Vivo de Viña del Mar correspondiente a la Evaluacion Parcial 2. En la etapa anterior modelamos el esquema relacional, pero el negocio enfrentaba un grave problema: desactualizaciones de precios dispersas, sobreventas de instrumentos musicales en bodega por falta de validacion simultanea, y calculos manuales y lentos en las liquidaciones mensuales. Para solucionar esto de raiz, trasladamos las reglas de negocio al corazon de Oracle mediante una arquitectura modular en PL/SQL."

### Defensa de Procedimientos y Funciones (1.5 minutos)
> "Implementamos subprogramas con y sin parametros segun la naturaleza de la operacion. Para calculos comerciales disenamos funciones como `fn_calcular_descuento`, la cual es una funcion pura que puede ser invocada de manera nativa dentro de sentencias `SELECT` de SQL, eliminando la duplicacion de formulas. Por otra parte, para el procesamiento masivo desarrollamos procedimientos como `sp_reajustar_precios` —que reajusta catalogos enteros y retorna la cantidad de filas impactadas mediante un parametro `OUT`— y `sp_actualizar_estadisticas_inventario`, un procedimiento sin parametros que barre de forma autonoma las existencias criticas y actualiza el historial de bodega."

### Defensa del Package y Transacciones Autonomas (1.5 minutos)
> "Para organizar este ecosistema creamos el paquete `PKG_SONIDO_VIVO`. Esto nos otorga dos ventajas tecnicas criticas: primero, rendimiento, ya que Oracle carga el paquete completo en la memoria compartida (Shared Pool) al primer llamado, reduciendo drasticamente la latencia de disco. Segundo, encapsulamiento real: separamos los constructores publicos en la especificacion, pero ocultamos en el cuerpo el constructor privado `sp_registrar_log_interno`. Este procedimiento privado utiliza la directiva `PRAGMA AUTONOMOUS_TRANSACTION`. Esto significa que si un proceso comercial falla y emite un `ROLLBACK`, el registro del fallo en nuestra tabla `LOG_ERRORES` se confirma con su propio `COMMIT` independiente, garantizando que jamas perdamos la trazabilidad de un error en el sistema."

### Defensa de Triggers: Fila vs Sentencia (1.5 minutos)
> "Finalmente, aseguramos la integridad mediante disparadores. Implementamos triggers a nivel de fila como `TRG_VALIDA_Y_DESCUENTA_STOCK`, que antes de permitir una insercion en el detalle de la venta comprueba las existencias y, si no hay stock, detiene la operacion con `RAISE_APPLICATION_ERROR(-20001)`. Tambien implementamos `TRG_AUDITA_PRECIO_PRODUCTO`, que utiliza la clausula `WHEN` para auditar solo cuando el precio efectivamente cambia. Y para cumplir con el control global, creamos un trigger a nivel de sentencia sobre la tabla `VENTA`, que se ejecuta una unica vez por sentencia para registrar las operaciones masivas del dia."

### Cierre (30 segundos)
> "En conclusion, logramos una arquitectura transaccional solida, modular y eficiente, lista no solo para SQL Developer, sino preparada para integrarse con capas de servicios web externas. Quedo a su entera disposicion para responder sus consultas tecnicas."

---

## 3. Banco de Preguntas Tecnicas del Docente y Respuestas Blindadas

### Pregunta 1: ¿Por que no hiciste el descuento de stock desde la aplicacion web en vez de usar un trigger?
**Respuesta:** Porque delegar la validacion de inventario exclusivamente a la aplicacion web abre vulnerabilidades criticas de condicion de carrera (*race condition*). Si dos cajeros o dos clientes web intentan comprar la ultima guitarra al mismo tiempo, ambos veran stock disponible en la pantalla. Al colocar el trigger `BEFORE INSERT` con `FOR EACH ROW` y `RAISE_APPLICATION_ERROR` dentro del motor Oracle, la base de datos bloquea la fila mediante serializacion transaccional ACID, haciendo fisicamente imposible la sobreventa, sin importar desde donde se emita la compra.

### Pregunta 2: ¿Que es una transaccion autonoma y por que es indispensable en tu paquete?
**Respuesta:** Por defecto en Oracle, todas las sentencias DML pertenecen a la misma transaccion de la sesion. Si un procedimiento falla y ejecuta un `ROLLBACK`, cualquier insercion previa —incluyendo el mensaje de error que quisimos guardar en `LOG_ERRORES`— se borra de la base de datos. Al aplicar `PRAGMA AUTONOMOUS_TRANSACTION` a nuestro procedimiento privado `sp_registrar_log_interno`, Oracle suspende temporalmente la transaccion principal, abre una transaccion paralela e independiente, inserta el log, ejecuta un `COMMIT` propio y regresa a la transaccion original. De esta forma, el log queda grabado de forma permanente en el disco aunque la operacion de venta sea cancelada.

### Pregunta 3: ¿Cual es la diferencia en ejecucion entre tu trigger de fila y tu trigger de sentencia?
**Respuesta:** La diferencia radica en la granularidad y la clausula `FOR EACH ROW`. Si emitimos una sentencia `UPDATE PRODUCTO SET precio = precio * 1.05 WHERE id_categoria = 1` y esa categoria tiene 50 guitarras, el trigger de fila `TRG_AUDITA_PRECIO_PRODUCTO` se disparara exactamente 50 veces, una por cada registro modificado, accediendo a `:OLD.precio` y `:NEW.precio`. En cambio, el trigger de sentencia `TRG_CONTROL_OPERACION_VENTAS` sobre `VENTA` no lleva `FOR EACH ROW`, por lo que si una sentencia modifica 10.000 ventas, el trigger se dispara una unica vez al terminar la sentencia, permitiendo auditorias de lotes sin sobrecargar el procesador con iteraciones innecesarias.

### Pregunta 4: ¿Como evitaste el error de Tabla Mutante (ORA-04091)?
**Respuesta:** El error `ORA-04091` ocurre cuando un trigger a nivel de fila intenta realizar una consulta `SELECT` o una modificacion sobre la misma tabla que esta en proceso de cambio (tabla mutante). En nuestro diseno evitamos este error de raiz:
1. En el trigger `TRG_VALIDA_Y_DESCUENTA_STOCK`, el evento ocurre sobre `DETALLE_VENTA`, mientras que la consulta y actualizacion de existencias se realizan sobre la tabla `PRODUCTO`. Como son tablas distintas, no existe condicion de mutacion.
2. En el trigger `TRG_AUDITA_PRECIO_PRODUCTO`, no realizamos ningun `SELECT` sobre `PRODUCTO`; simplemente leemos las pseudocolumnas en memoria `:OLD.precio` y `:NEW.precio` y escribimos en una tabla externa (`AUDIT_PRECIOS_PRODUCTO`).
