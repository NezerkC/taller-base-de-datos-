"""Script para generar el documento de Explicación Paso a Paso de los Bloques de Código PL/SQL
en formato Word (.docx) con lenguaje amigable y diseño profesional.
"""

import docx
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement, parse_xml
from docx.oxml.ns import nsdecls, qn

def set_cell_background(cell, hex_color):
    shading_elm = parse_xml(f'<w:shd {nsdecls("w")} w:fill="{hex_color}"/>')
    cell._tc.get_or_add_tcPr().append(shading_elm)

def set_cell_margins(cell, top=100, bottom=100, left=150, right=150):
    tcPr = cell._tc.get_or_add_tcPr()
    tcMar = OxmlElement('w:tcMar')
    for m, val in [('w:top', top), ('w:bottom', bottom), ('w:left', left), ('w:right', right)]:
        node = OxmlElement(m)
        node.set(qn('w:w'), str(val))
        node.set(qn('w:type'), 'dxa')
        tcMar.append(node)
    tcPr.append(tcMar)

def set_cell_left_border(cell, hex_color="2563EB", sz="36"):
    tcPr = cell._tc.get_or_add_tcPr()
    tcBorders = parse_xml(f'''
        <w:tcBorders {nsdecls("w")}>
            <w:top w:val="none"/>
            <w:left w:val="single" w:sz="{sz}" w:space="0" w:color="{hex_color}"/>
            <w:bottom w:val="none"/>
            <w:right w:val="none"/>
        </w:tcBorders>
    ''')
    tcPr.append(tcBorders)

def add_callout(doc, text_lines, title="Idea Clave (En palabras simples):"):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    cell = table.cell(0, 0)
    cell.width = Inches(6.8)
    set_cell_background(cell, "EFF6FF") # Light Blue
    set_cell_left_border(cell, "2563EB", sz="36")
    set_cell_margins(cell, top=120, bottom=120, left=180, right=180)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(4)
    r_t = p.add_run(title)
    r_t.bold = True
    r_t.font.name = 'Segoe UI'
    r_t.font.size = Pt(10.5)
    r_t.font.color.rgb = RGBColor(30, 64, 175) # Dark Blue
    
    for line in text_lines:
        p2 = cell.add_paragraph()
        p2.paragraph_format.space_after = Pt(3)
        r = p2.add_run(line)
        r.font.name = 'Segoe UI'
        r.font.size = Pt(9.5)
        r.font.color.rgb = RGBColor(30, 41, 59)
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

def add_code_block(doc, code_str):
    table = doc.add_table(rows=1, cols=1)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    cell = table.cell(0, 0)
    cell.width = Inches(6.8)
    set_cell_background(cell, "0F172A") # Slate 900
    set_cell_margins(cell, top=100, bottom=100, left=140, right=140)
    
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    r = p.add_run(code_str.strip())
    r.font.name = 'Consolas'
    r.font.size = Pt(8.5)
    r.font.color.rgb = RGBColor(241, 245, 249) # Slate 100
    doc.add_paragraph().paragraph_format.space_after = Pt(6)

def add_breakdown_table(doc, rows_data):
    table = doc.add_table(rows=len(rows_data)+1, cols=3)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    
    widths = [Inches(0.9), Inches(2.2), Inches(3.7)]
    headers = ["Líneas", "Código Clave", "Explicación Paso a Paso"]
    
    hdr_cells = table.rows[0].cells
    for i, title in enumerate(headers):
        hdr_cells[i].width = widths[i]
        set_cell_background(hdr_cells[i], "1E293B")
        set_cell_margins(hdr_cells[i], top=80, bottom=80, left=100, right=100)
        p = hdr_cells[i].paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(title)
        r.bold = True
        r.font.name = 'Segoe UI'
        r.font.size = Pt(9)
        r.font.color.rgb = RGBColor(255, 255, 255)
        
    for r_idx, (lines, code_snip, expl) in enumerate(rows_data):
        row_cells = table.rows[r_idx+1].cells
        bg_col = "F8FAFC" if r_idx % 2 == 0 else "FFFFFF"
        for i, val in enumerate([lines, code_snip, expl]):
            row_cells[i].width = widths[i]
            set_cell_background(row_cells[i], bg_col)
            set_cell_margins(row_cells[i], top=60, bottom=60, left=100, right=100)
            p = row_cells[i].paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            r = p.add_run(val)
            r.font.name = 'Segoe UI'
            r.font.size = Pt(8.5)
            if i == 0:
                r.bold = True
                r.font.color.rgb = RGBColor(37, 99, 235)
            elif i == 1:
                r.font.name = 'Consolas'
                r.font.size = Pt(8)
                r.font.color.rgb = RGBColor(15, 23, 42)
            else:
                r.font.color.rgb = RGBColor(51, 65, 85)
    doc.add_paragraph().paragraph_format.space_after = Pt(12)

def generate():
    doc = docx.Document()
    
    for section in doc.sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)
        
    style_normal = doc.styles['Normal']
    font = style_normal.font
    font.name = 'Segoe UI'
    font.size = Pt(10)
    font.color.rgb = RGBColor(30, 41, 59)
    
    # Encabezado
    p_sub = doc.add_paragraph()
    r_sub = p_sub.add_run("TALLER DE BASE DE DATOS (BDY1103) — CASO SONIDO VIVO")
    r_sub.font.size = Pt(9.5)
    r_sub.font.bold = True
    r_sub.font.color.rgb = RGBColor(37, 99, 235)
    p_sub.paragraph_format.space_after = Pt(2)
    
    p_title = doc.add_paragraph()
    r_title = p_title.add_run("Explicación de Bloques de Código Paso a Paso")
    r_title.font.size = Pt(18)
    r_title.font.bold = True
    r_title.font.color.rgb = RGBColor(15, 23, 42)
    p_title.paragraph_format.space_after = Pt(6)
    
    p_intro = doc.add_paragraph()
    p_intro.add_run(
        "Este documento explica de forma clara, amigable y línea por línea el funcionamiento de cada "
        "bloque de código PL/SQL desarrollado para Sonido Vivo. Pensado para entender la lógica de negocio "
        "sin rodeos ni tecnicismos oscuros."
    )
    p_intro.paragraph_format.space_after = Pt(14)
    
    # =========================================================================
    # BLOQUE 1
    # =========================================================================
    h1 = doc.add_paragraph()
    r1 = h1.add_run("1. Bloque 1: RECORD y VARRAY — Motor de Liquidaciones")
    r1.font.size = Pt(13)
    r1.bold = True
    r1.font.color.rgb = RGBColor(37, 99, 235)
    h1.paragraph_format.space_after = Pt(4)
    
    add_callout(doc, [
        "• El RECORD es como una ficha o formulario en papel: agrupa en una sola variable todos los datos del cliente (nombre, total bruto, descuento, neto).",
        "• El VARRAY es como una regleta de 3 casillas fijas pegada en el escritorio: guarda las tasas 0%, 5% y 10%. Así no tenemos que consultar la base de datos a cada rato.",
        "• Objetivo: Recorrer a los clientes con compras pendientes, calcular su descuento por tramo de compra (y +2% si es Premium), e insertar el resultado en LIQUIDACION_CLIENTE."
    ], title="¿Qué hace este bloque en palabras sencillas?")
    
    code_b1 = """DECLARE
    TYPE t_rec_liquidacion IS RECORD (
        id_cliente CLIENTE.id_cliente%TYPE,
        nombre_completo VARCHAR2(120),
        tipo_cliente CLIENTE.tipo_cliente%TYPE,
        total_bruto NUMBER(10),
        tasa_descuento_pct NUMBER(5,2),
        monto_descuento NUMBER(10),
        total_neto NUMBER(10),
        cantidad_ordenes NUMBER(4),
        observacion VARCHAR2(200)
    );
    TYPE t_arr_tasas IS VARRAY(3) OF NUMBER(5,2);

    v_liquidacion t_rec_liquidacion;
    v_escalas_descuento t_arr_tasas := t_arr_tasas(0.00, 5.00, 10.00);
    v_contador_liq NUMBER(8) := 0;
BEGIN
    DELETE FROM LIQUIDACION_CLIENTE;

    FOR reg_cli IN (
        SELECT c.id_cliente, c.nombres || ' ' || c.apellidos AS nombre_completo,
               c.tipo_cliente, COUNT(v.id_venta) AS cant_compras, NVL(SUM(v.total), 0) AS monto_acumulado
        FROM CLIENTE c JOIN VENTA v ON c.id_cliente = v.id_cliente
        WHERE v.estado_venta = 'PENDIENTE'
        GROUP BY c.id_cliente, c.nombres, c.apellidos, c.tipo_cliente
        ORDER BY c.id_cliente
    ) LOOP
        v_liquidacion.id_cliente := reg_cli.id_cliente;
        v_liquidacion.nombre_completo := reg_cli.nombre_completo;
        v_liquidacion.tipo_cliente := reg_cli.tipo_cliente;
        v_liquidacion.total_bruto := reg_cli.monto_acumulado;
        v_liquidacion.cantidad_ordenes := reg_cli.cant_compras;

        IF v_liquidacion.total_bruto < 200000 THEN
            v_liquidacion.tasa_descuento_pct := v_escalas_descuento(1); -- 0%
        ELSIF v_liquidacion.total_bruto BETWEEN 200000 AND 700000 THEN
            v_liquidacion.tasa_descuento_pct := v_escalas_descuento(2); -- 5%
        ELSE
            v_liquidacion.tasa_descuento_pct := v_escalas_descuento(3); -- 10%
        END IF;

        IF v_liquidacion.tipo_cliente = 'PREMIUM' THEN
            v_liquidacion.tasa_descuento_pct := v_liquidacion.tasa_descuento_pct + 2.00;
        END IF;

        v_liquidacion.monto_descuento := ROUND(v_liquidacion.total_bruto * (v_liquidacion.tasa_descuento_pct / 100));
        v_liquidacion.total_neto := v_liquidacion.total_bruto - v_liquidacion.monto_descuento;

        INSERT INTO LIQUIDACION_CLIENTE VALUES (
            SEQ_LIQUIDACION_CLIENTE.NEXTVAL, v_liquidacion.id_cliente, v_liquidacion.nombre_completo,
            v_liquidacion.total_bruto, v_liquidacion.tasa_descuento_pct, v_liquidacion.monto_descuento,
            v_liquidacion.total_neto, v_liquidacion.cantidad_ordenes, SYSDATE, v_liquidacion.observacion
        );
        v_contador_liq := v_contador_liq + 1;
    END LOOP;
    COMMIT;
END;"""
    add_code_block(doc, code_b1)
    
    rows_b1 = [
        ("16-26", "TYPE t_rec_liquidacion IS RECORD (...)", "Crea el molde de nuestra ficha. Usa %TYPE para anclar tipos a la tabla CLIENTE y evitar fallos si cambian las columnas."),
        ("32", "TYPE t_arr_tasas IS VARRAY(3) OF NUMBER(5,2)", "Crea el molde del arreglo fijo en memoria con 3 casillas para guardar las tasas de descuento."),
        ("37-38", "v_escalas_descuento t_arr_tasas := t_arr_tasas(0.00, 5.00, 10.00)", "Crea la variable e inicializa de inmediato las 3 posiciones: (1)=0%, (2)=5%, (3)=10%."),
        ("47", "DELETE FROM LIQUIDACION_CLIENTE;", "Limpia la tabla de destino para que el proceso sea idempotente (se pueda ejecutar varias veces sin duplicar)."),
        ("50-61", "FOR reg_cli IN (SELECT ... WHERE estado_venta = 'PENDIENTE') LOOP", "Abre un cursor automático que consulta a los clientes con compras pendientes y los itera fila por fila."),
        ("64-68", "v_liquidacion.campo := reg_cli.campo", "Pasa los datos del cursor a los campos individuales de nuestra ficha RECORD en memoria."),
        ("71-80", "IF ... v_escalas_descuento(1) ... ELSIF ...", "Evalúa el monto total del cliente y rescata la tasa desde la casilla correspondiente del VARRAY."),
        ("83-86", "IF tipo_cliente = 'PREMIUM' THEN + 2.00", "Aplica un beneficio adicional del +2% si el cliente es categoría PREMIUM."),
        ("89-90", "ROUND(...) y total_neto := total_bruto - monto_descuento", "Calcula el descuento en pesos y obtiene el neto a cobrar."),
        ("93-115", "INSERT INTO LIQUIDACION_CLIENTE VALUES (SEQ_LIQUIDACION_CLIENTE.NEXTVAL, ...)", "Inserta la fila usando una SECUENCIA para garantizar un ID correlativo único y seguro en concurrencia."),
        ("127", "COMMIT;", "Confirma definitivamente todas las inserciones en la base de datos.")
    ]
    add_breakdown_table(doc, rows_b1)
    
    # =========================================================================
    # BLOQUE 2
    # =========================================================================
    h2 = doc.add_paragraph()
    r2 = h2.add_run("2. Bloque 2: Cursores Explícitos y Anidados — Reporte de Compras")
    r2.font.size = Pt(13)
    r2.bold = True
    r2.font.color.rgb = RGBColor(37, 99, 235)
    h2.paragraph_format.space_after = Pt(4)
    
    add_callout(doc, [
        "• Cursor Padre (c_clientes): Abre la lista de clientes que compraron algo (usa WHERE EXISTS para no revisar clientes sin ventas).",
        "• Cursor Hijo (c_ventas_cliente): Recibe como parámetro el ID del cliente actual (p_id_cli) y trae todas sus boletas con el detalle de instrumentos comprados.",
        "• Corte de Control: Si el número de boleta cambia, imprime el título de la boleta una sola vez. Al final de cada cliente muestra su resumen total."
    ], title="¿Qué hace este bloque en palabras sencillas?")
    
    code_b2 = """DECLARE
    CURSOR c_clientes IS
        SELECT c.id_cliente, c.rut, c.nombres || ' ' || c.apellidos AS cliente_nombre, c.comuna, c.tipo_cliente
        FROM CLIENTE c
        WHERE EXISTS (SELECT 1 FROM VENTA v WHERE v.id_cliente = c.id_cliente)
        ORDER BY c.id_cliente;

    CURSOR c_ventas_cliente (p_id_cli CLIENTE.id_cliente%TYPE) IS
        SELECT v.nro_boleta, v.fecha_venta, p.codigo AS codigo_prod, p.nombre AS nombre_prod,
               cat.nombre_categoria, d.cantidad, d.precio_unitario, d.subtotal_linea
        FROM VENTA v
        JOIN DETALLE_VENTA d ON v.id_venta = d.id_venta
        JOIN PRODUCTO p      ON d.id_producto = p.id_producto
        JOIN CATEGORIA cat   ON p.id_categoria = cat.id_categoria
        WHERE v.id_cliente = p_id_cli
        ORDER BY v.nro_boleta, d.id_detalle;

    v_total_cliente NUMBER(10);
    v_total_unidades NUMBER(6);
    v_boleta_actual NUMBER(8);
BEGIN
    FOR reg_cli IN c_clientes LOOP
        v_total_cliente := 0; v_total_unidades := 0; v_boleta_actual := 0;
        DBMS_OUTPUT.PUT_LINE('CLIENTE [' || reg_cli.id_cliente || '] ' || UPPER(reg_cli.cliente_nombre));

        FOR reg_det IN c_ventas_cliente(reg_cli.id_cliente) LOOP
            IF v_boleta_actual <> reg_det.nro_boleta THEN
                v_boleta_actual := reg_det.nro_boleta;
                DBMS_OUTPUT.PUT_LINE('  >> Boleta N° ' || v_boleta_actual || ':');
            END IF;

            DBMS_OUTPUT.PUT_LINE('     * [' || reg_det.codigo_prod || '] ' || reg_det.nombre_prod || 
                                 ' | Cant: ' || reg_det.cantidad || ' x $' || reg_det.precio_unitario);
            v_total_cliente := v_total_cliente + reg_det.subtotal_linea;
            v_total_unidades := v_total_unidades + reg_det.cantidad;
        END LOOP;

        DBMS_OUTPUT.PUT_LINE('  --> TOTAL CLIENTE: ' || v_total_unidades || ' unid | $' || v_total_cliente);
    END LOOP;
END;"""
    add_code_block(doc, code_b2)
    
    rows_b2 = [
        ("16-28", "CURSOR c_clientes IS ... WHERE EXISTS (...)", "Cursor Padre. Trae clientes con ventas. El EXISTS es muy rápido porque para apenas encuentra una venta."),
        ("32-46", "CURSOR c_ventas_cliente (p_id_cli ...) IS ...", "Cursor Hijo parametrizado. Une 4 tablas (VENTA, DETALLE, PRODUCTO, CATEGORIA) filtrando por el cliente indicado."),
        ("62", "FOR reg_cli IN c_clientes LOOP", "Bucle Externo: Oracle abre el cursor padre y recorre a los clientes uno por uno."),
        ("64-66", "v_total_cliente := 0; v_total_unidades := 0;", "Reinicio de acumuladores: obligatorio en cada cliente para no arrastrar las sumas del anterior."),
        ("78", "FOR reg_det IN c_ventas_cliente(reg_cli.id_cliente) LOOP", "Bucle Interno: Le pasamos el ID del cliente actual al cursor hijo para obtener únicamente sus compras."),
        ("81-84", "IF v_boleta_actual <> reg_det.nro_boleta THEN ...", "Corte de Control: Si cambió la boleta, imprime el título de la boleta solo una vez."),
        ("87-92", "DBMS_OUTPUT.PUT_LINE(' * [' || ...)", "Imprime el producto, categoría, precio y subtotal formateado con espacios alineados (RPAD/LPAD)."),
        ("95-96", "v_total_cliente := v_total_cliente + ...", "Acumula el dinero gastado y las unidades físicas adquiridas."),
        ("101-102", "DBMS_OUTPUT.PUT_LINE(' --> RESUMEN CLIENTE ...')", "Muestra el consolidado del cliente antes de cerrar su carpeta y pasar al siguiente.")
    ]
    add_breakdown_table(doc, rows_b2)
    
    # =========================================================================
    # BLOQUE 3
    # =========================================================================
    h3 = doc.add_paragraph()
    r3 = h3.add_run("3. Bloque 3: Control de Excepciones — Simulador de Ventas")
    r3.font.size = Pt(13)
    r3.bold = True
    r3.font.color.rgb = RGBColor(37, 99, 235)
    h3.paragraph_format.space_after = Pt(4)
    
    add_callout(doc, [
        "• El objetivo es garantizar transacciones seguras (ACID): no permitir vender si el cliente no existe, si la cantidad es <= 0, o si no hay stock suficiente en la bodega.",
        "• Si algo falla: se ejecuta ROLLBACK (cancela cualquier cambio a medias) y se inserta un registro con el error en la tabla LOG_ERRORES.",
        "• Maneja tanto errores nativos de Oracle (NO_DATA_FOUND, TOO_MANY_ROWS) como reglas de negocio nuestras (e_stock_insuficiente, e_cantidad_invalida)."
    ], title="¿Qué hace este bloque en palabras sencillas?")
    
    code_b3 = """DECLARE
    e_stock_insuficiente EXCEPTION;
    e_cantidad_invalida  EXCEPTION;

    v_id_cliente_solicitado  NUMBER := 1;
    v_codigo_prod_solicitado VARCHAR2(10) := 'GE002';
    v_cantidad_solicitada    NUMBER := 5; -- Stock actual es 2 -> gatillará excepción

    v_id_producto PRODUCTO.id_producto%TYPE;
    v_nombre_prod PRODUCTO.nombre%TYPE;
    v_stock_actual PRODUCTO.stock%TYPE;
    v_secuencia_log NUMBER(8);
BEGIN
    -- 1. Validar cliente (Gatilla NO_DATA_FOUND si no existe)
    SELECT nombres INTO v_nombre_prod FROM CLIENTE WHERE id_cliente = v_id_cliente_solicitado;

    -- 2. Validar cantidad positiva
    IF v_cantidad_solicitada <= 0 THEN RAISE e_cantidad_invalida; END IF;

    -- 3. Validar producto y stock (Gatilla NO_DATA_FOUND si código no existe)
    SELECT id_producto, nombre, stock INTO v_id_producto, v_nombre_prod, v_stock_actual
    FROM PRODUCTO WHERE codigo = v_codigo_prod_solicitado;

    -- 4. Validar disponibilidad
    IF v_cantidad_solicitada > v_stock_actual THEN RAISE e_stock_insuficiente; END IF;

    -- Si todo está OK: Descuenta e impacta
    UPDATE PRODUCTO SET stock = stock - v_cantidad_solicitada WHERE id_producto = v_id_producto;
    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        INSERT INTO LOG_ERRORES VALUES (SEQ_LOG_ERRORES.NEXTVAL, 'ORA-01403', 'Cliente o Producto inexistente', 'CHECKOUT', USER, SYSDATE);
        COMMIT;
    WHEN e_stock_insuficiente THEN
        ROLLBACK;
        INSERT INTO LOG_ERRORES VALUES (SEQ_LOG_ERRORES.NEXTVAL, 'USR-001', 'Stock insuficiente para la venta', 'VENTAS_STOCK', USER, SYSDATE);
        COMMIT;
    WHEN e_cantidad_invalida THEN
        ROLLBACK;
        INSERT INTO LOG_ERRORES VALUES (SEQ_LOG_ERRORES.NEXTVAL, 'USR-002', 'Cantidad pedida debe ser mayor a cero', 'PARAMETROS', USER, SYSDATE);
        COMMIT;
    WHEN OTHERS THEN
        ROLLBACK;
        INSERT INTO LOG_ERRORES VALUES (SEQ_LOG_ERRORES.NEXTVAL, 'ORA-'||SQLCODE, SUBSTR(SQLERRM, 1, 380), 'GENERAL', USER, SYSDATE);
        COMMIT;
END;"""
    add_code_block(doc, code_b3)
    
    rows_b3 = [
        ("14-15", "e_stock_insuficiente EXCEPTION;", "Declara excepciones personalizadas con la palabra clave EXCEPTION."),
        ("44-47", "SELECT ... INTO ... FROM CLIENTE ...", "Busca al cliente. Si el ID no existe en la tabla, Oracle salta automáticamente a WHEN NO_DATA_FOUND."),
        ("54-56", "IF v_cantidad_solicitada <= 0 THEN RAISE ...", "Control de parámetros. Si piden 0 o negativo, ejecutamos RAISE e_cantidad_invalida."),
        ("61-64", "SELECT ... INTO ... FROM PRODUCTO ...", "Busca el producto y su stock. Si no existe, gatilla NO_DATA_FOUND."),
        ("73-75", "IF v_cantidad_solicitada > v_stock_actual THEN RAISE ...", "Regla de inventario: si no alcanzan las unidades en bodega, forzamos RAISE e_stock_insuficiente."),
        ("80-87", "UPDATE PRODUCTO ... COMMIT;", "Si todo fue exitoso, resta las unidades vendidas y confirma la transacción de forma permanente con COMMIT."),
        ("93-106", "WHEN NO_DATA_FOUND THEN ROLLBACK; ...", "Captura cliente o producto no encontrado, deshace cambios con ROLLBACK y registra el incidente en LOG_ERRORES."),
        ("123-136", "WHEN e_stock_insuficiente THEN ...", "Captura la falta de inventario, graba con código USR-001 y detalla la cantidad pedida vs disponible."),
        ("137-149", "WHEN e_cantidad_invalida THEN ...", "Captura errores de cantidad <= 0 con código USR-002."),
        ("153-165", "WHEN OTHERS THEN ... SQLCODE ... SQLERRM", "Capturador universal de seguridad. SQLCODE da el código y SQLERRM el mensaje del error imprevisto.")
    ]
    add_breakdown_table(doc, rows_b3)
    
    # =========================================================================
    # BLOQUE 4
    # =========================================================================
    h4 = doc.add_paragraph()
    r4 = h4.add_run("4. Bloque 4 (Bonus): Triggers — Descuento y Alerta de Stock")
    r4.font.size = Pt(13)
    r4.bold = True
    r4.font.color.rgb = RGBColor(37, 99, 235)
    h4.paragraph_format.space_after = Pt(4)
    
    add_callout(doc, [
        "• TRG_DESCUENTA_STOCK: Se dispara AFTER INSERT en DETALLE_VENTA. Resta automáticamente las unidades en la tabla PRODUCTO usando :NEW.cantidad.",
        "• TRG_AUDITA_STOCK_CRITICO: Se dispara AFTER UPDATE en PRODUCTO solo si el stock cae por debajo del umbral crítico (cláusula WHEN). Graba una alerta preventiva en LOG_ERRORES.",
        "• Cero Error Mutante (ORA-04091): Como el primer trigger está en DETALLE_VENTA y actualiza PRODUCTO, nunca muta la misma tabla en la que está escuchando."
    ], title="¿Qué hace este bloque en palabras sencillas?")
    
    code_b4 = """-- Trigger 1: Descuenta Stock automáticamente tras una venta
CREATE OR REPLACE TRIGGER TRG_DESCUENTA_STOCK
AFTER INSERT ON DETALLE_VENTA
FOR EACH ROW
BEGIN
    UPDATE PRODUCTO
    SET stock = stock - :NEW.cantidad
    WHERE id_producto = :NEW.id_producto;
END;
/

-- Trigger 2: Alerta cuando el producto entra en nivel crítico
CREATE OR REPLACE TRIGGER TRG_AUDITA_STOCK_CRITICO
AFTER UPDATE OF stock ON PRODUCTO
FOR EACH ROW
WHEN (NEW.stock <= NEW.stock_critico)
BEGIN
    INSERT INTO LOG_ERRORES VALUES (
        SEQ_LOG_ERRORES.NEXTVAL, 'ALERTA-STOCK-CRITICO',
        'ATENCIÓN: Producto ID ' || :NEW.id_producto || ' alcanzó nivel crítico. Stock: ' || :NEW.stock,
        'TRIGGER_AUDITA_STOCK_CRITICO', USER, SYSDATE
    );
END;
/"""
    add_code_block(doc, code_b4)
    
    rows_b4 = [
        ("17-19", "AFTER INSERT ON DETALLE_VENTA FOR EACH ROW", "Dispara el trigger inmediatamente después de cada ítem insertado en la boleta."),
        ("21-23", "UPDATE PRODUCTO SET stock = stock - :NEW.cantidad ...", "Usa :NEW para tomar la cantidad vendida y restársela al producto. No causa error mutante porque son tablas distintas."),
        ("34-36", "AFTER UPDATE OF stock ON PRODUCTO ... WHEN (NEW.stock <= NEW.stock_critico)", "Optimización: solo se dispara cuando se actualiza la columna stock y si el valor resultante cae a nivel crítico."),
        ("38-54", "INSERT INTO LOG_ERRORES VALUES (...)", "Graba la advertencia para que bodega gestione el reabastecimiento antes de que se agote.")
    ]
    add_breakdown_table(doc, rows_b4)
    
    # Guardar
    output_path = "docs/entregables/Explicacion_Paso_a_Paso_Bloques_PLSQL.docx"
    doc.save(output_path)
    print(f"Documento generado exitosamente en: {output_path}")

if __name__ == "__main__":
    generate()
