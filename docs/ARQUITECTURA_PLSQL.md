# Arquitectura Modular PL/SQL: Sonido Vivo

**Asignatura:** Taller de Base de Datos (BDY1103)  
**Institucion:** Duoc UC  
**Modulo:** Arquitectura Transaccional y Objetos Almacenados (Prueba Parcial 2)

---

## 1. Vision Arquitectonica

La arquitectura de software de base de datos de **Sonido Vivo** evoluciona de bloques anonimos temporales hacia una solucion corporativa de dos capas:

1. **Capa de Logica de Negocio y Transaccionalidad:** Reside internamente en el motor Oracle Database a traves de paquetes (`PACKAGE`), funciones de calculo, procedimientos almacenados y disparadores reactivos (`TRIGGERS`).
2. **Capa de Monitoreo y Administracion:** Reside en un Dashboard Web Local (`prueba parcial 2/dashboard/`), permitiendo al usuario administrador simular ajustes de precios, visualizar el inventario y auditar disparos en tiempo real.

---

## 2. Diagrama de Relaciones y Componentes

```text
+-----------------------------------------------------------------------------------+
|                            DASHBOARD WEB LOCAL (HTML/JS)                          |
|    - Modulo Inventario & Stock Critico                                            |
|    - Modulo Control de Precios (Simulacion de Ajustes)                            |
|    - Consola de Auditoria (Visualizador de LOG_ERRORES y AUDIT_PRECIOS)           |
+-----------------------------------------------------------------------------------+
                                          |
                                          | Invocacion de Servicios
                                          v
+-----------------------------------------------------------------------------------+
|                        PAQUETE MODULAR: PKG_SONIDO_VIVO                           |
+-----------------------------------------------------------------------------------+
| [ESPECIFICACION PUBLICA]                                                          |
|   + c_iva_tasa : NUMBER := 0.19                                                   |
|   + fn_validar_email(p_email) RETURN NUMBER                                       |
|   + fn_calcular_descuento(p_tipo_cliente, p_monto) RETURN NUMBER                  |
|   + sp_reajustar_precios(p_porcentaje, p_filas_afectadas OUT)                     |
|   + sp_liquidar_clientes(p_periodo, p_total_procesados OUT)                       |
+-----------------------------------------------------------------------------------+
| [CUERPO PRIVADO]                                                                  |
|   - sp_registrar_log_interno(codigo, mensaje, origen) [PRAGMA AUTONOMOUS_TRANS]   |
|   - Implementacion ejecutable de funciones y procedimientos publicos              |
+-----------------------------------------------------------------------------------+
       |                                                            |
       | Modifica PRECIO                                            | Inserta en
       v                                                            v
+------------------------+                               +--------------------------+
|        PRODUCTO        |                               |    LIQUIDACION_CLIENTE   |
+------------------------+                               +--------------------------+
       |                                                            ^
       | Dispara UPDATE OF precio                                   | Consulta
       v                                                            |
+-------------------------------------+                  +--------------------------+
| TRIGGER: TRG_AUDIT_PRECIO_PRODUCTO  |                  |          VENTA           |
| (AFTER UPDATE FOR EACH ROW)         |                  +--------------------------+
+-------------------------------------+                             ^
       |                                                            |
       | Inserta :OLD y :NEW                                        | Vincula
       v                                                            |
+-------------------------------------+                  +--------------------------+
|       AUDIT_PRECIOS_PRODUCTO        |                  |      DETALLE_VENTA       |
+-------------------------------------+                  +--------------------------+
                                                                    |
                                                         Dispara    | BEFORE INSERT
                                                                    v
                                                         +--------------------------+
                                                         | TRIGGER:                 |
                                                         | TRG_VALIDA_STOCK_VENTA   |
                                                         | (BEFORE INSERT ROW)      |
                                                         +--------------------------+
                                                                    |
                                                         Valida y   | Si stock < pedido:
                                                         descuenta  | RAISE_APPL_ERROR
                                                                    v
                                                         +--------------------------+
                                                         |   Control Preventivo     |
                                                         |      de Inventario       |
                                                         +--------------------------+
```

---

## 3. Principios Tecnicos Fundamentales

### A. Modularizacion y Encapsulamiento
- **Separacion de Interfaz e Implementacion:** El paquete divide estrictamente lo que es publico (`PACKAGE`) de lo que es privado (`PACKAGE BODY`).
- **Constructores Privados:** El procedimiento `sp_registrar_log_interno` no esta expuesto en la cabecera del paquete. Esto garantiza que ningun actor externo pueda manipular directamente la auditoria de incidencias.

### B. Transacciones Autonomas (`PRAGMA AUTONOMOUS_TRANSACTION`)
- Si un procedimiento masivo falla y entra en la seccion `EXCEPTION`, la regla ACID dicta ejecutar un `ROLLBACK` para evitar la inconsistencia de datos.
- Sin embargo, la directiva `PRAGMA AUTONOMOUS_TRANSACTION` dentro del subprograma de log permite suspender temporalmente la transaccion fallida, abrir una transaccion independiente, registrar la traza en `LOG_ERRORES` y confirmarla con su propio `COMMIT`. Asi, la evidencia del error queda guardada para el equipo de soporte.

### C. Mitigacion del Error de Tabla Mutante (`ORA-04091`)
- Ocurre cuando un trigger a nivel de fila consulta o modifica la tabla sobre la cual esta actuando la sentencia SQL activa.
- **Solucion aplicada:** El trigger `TRG_VALIDA_STOCK_VENTA` se asocia a `DETALLE_VENTA` y efectua la comprobacion y descuento sobre `PRODUCTO`. Al ser tablas distintas, `PRODUCTO` no esta en estado mutante y la transaccion se ejecuta sin error.
