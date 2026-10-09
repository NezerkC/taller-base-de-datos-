"""Script para generar la Guía de Defensa Oral y Explicación de Código en formato Word (.docx)
con diseño profesional y estructurado.
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

def create_word(filename="docs/Guia_Defensa_SonidoVivo_EP1.docx"):
    doc = docx.Document()
    
    # Configurar márgenes de página
    sections = doc.sections
    for section in sections:
        section.top_margin = Inches(0.8)
        section.bottom_margin = Inches(0.8)
        section.left_margin = Inches(0.8)
        section.right_margin = Inches(0.8)

    # Estilos de fuente base
    style_normal = doc.styles['Normal']
    font = style_normal.font
    font.name = 'Segoe UI'
    font.size = Pt(10)
    font.color.rgb = RGBColor(30, 41, 59) # Slate 800

    # 1. ENCABEZADO Y TÍTULO PRINCIPAL
    p_sub = doc.add_paragraph()
    r_sub = p_sub.add_run("BDY1103 — TALLER DE BASE DE DATOS | DUOC UC (EVALUACIÓN PARCIAL N° 1)")
    r_sub.font.size = Pt(9.5)
    r_sub.font.bold = True
    r_sub.font.color.rgb = RGBColor(37, 99, 235) # Blue 600
    p_sub.paragraph_format.space_after = Pt(2)

    p_title = doc.add_paragraph()
    r_title = p_title.add_run("Guía de Defensa Oral y Explicación de Código")
    r_title.font.size = Pt(18)
    r_title.font.bold = True
    r_title.font.color.rgb = RGBColor(15, 23, 42) # Slate 900
    p_title.paragraph_format.space_after = Pt(8)

    # Tabla de metadatos
    meta_table = doc.add_table(rows=2, cols=2)
    meta_table.alignment = WD_TABLE_ALIGNMENT.CENTER
    meta_table.autofit = False

    data_meta = [
        ("Proyecto: Sonido Vivo (Viña del Mar)", "Docente Evaluador: Josue Oteiza"),
        ("Integrantes: Dylan Sandoval, Victor Martinez, Danilo Sepúlveda", "Estado: Sincronizado en main (Scripts 01 al 05)")
    ]

    for r_idx, row in enumerate(data_meta):
        for c_idx, text in enumerate(row):
            cell = meta_table.cell(r_idx, c_idx)
            cell.width = Inches(3.4)
            set_cell_background(cell, "F8FAFC")
            set_cell_margins(cell, top=80, bottom=80, left=120, right=120)
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            parts = text.split(":", 1)
            r_k = p.add_run(parts[0] + ":")
            r_k.bold = True
            r_k.font.size = Pt(9)
            r_k.font.color.rgb = RGBColor(15, 23, 42)
            if len(parts) > 1:
                r_v = p.add_run(parts[1])
                r_v.font.size = Pt(9)
                r_v.font.color.rgb = RGBColor(71, 85, 105)

    doc.add_paragraph().paragraph_format.space_after = Pt(10)

    # FUNCIÓN AUXILIAR PARA INSERTAR DIAPOSITIVA
    def add_slide_section(num, title, badge, speech_text, code_text=None, line_items=None):
        # Título de diapositiva
        h_table = doc.add_table(rows=1, cols=2)
        h_table.alignment = WD_TABLE_ALIGNMENT.CENTER
        c_left = h_table.cell(0, 0)
        c_right = h_table.cell(0, 1)
        c_left.width = Inches(5.6)
        c_right.width = Inches(1.2)
        
        set_cell_background(c_left, "0F172A")
        set_cell_background(c_right, "0F172A")
        set_cell_margins(c_left, top=90, bottom=90, left=120, right=60)
        set_cell_margins(c_right, top=90, bottom=90, left=60, right=120)

        p_h = c_left.paragraphs[0]
        p_h.paragraph_format.space_after = Pt(0)
        r_h = p_h.add_run(f"DIAPOSITIVA {num}: {title}")
        r_h.font.bold = True
        r_h.font.size = Pt(11)
        r_h.font.color.rgb = RGBColor(248, 250, 252)

        p_b = c_right.paragraphs[0]
        p_b.alignment = WD_ALIGN_PARAGRAPH.RIGHT
        p_b.paragraph_format.space_after = Pt(0)
        r_b = p_b.add_run(badge.upper())
        r_b.font.bold = True
        r_b.font.size = Pt(8.5)
        r_b.font.color.rgb = RGBColor(147, 197, 253)

        doc.add_paragraph().paragraph_format.space_after = Pt(2)

        # Caja de Qué decir
        sp_table = doc.add_table(rows=1, cols=1)
        sp_table.alignment = WD_TABLE_ALIGNMENT.CENTER
        c_sp = sp_table.cell(0, 0)
        c_sp.width = Inches(6.8)
        set_cell_background(c_sp, "EFF6FF")
        set_cell_left_border(c_sp, "2563EB", sz="24")
        set_cell_margins(c_sp, top=100, bottom=100, left=150, right=150)

        p_sp = c_sp.paragraphs[0]
        p_sp.paragraph_format.space_after = Pt(2)
        r_sp_lbl = p_sp.add_run("🎙️ QUÉ DECIR EN LA PRESENTACIÓN:\n")
        r_sp_lbl.bold = True
        r_sp_lbl.font.size = Pt(9)
        r_sp_lbl.font.color.rgb = RGBColor(29, 78, 216)

        r_sp_txt = p_sp.add_run(speech_text)
        r_sp_txt.italic = True
        r_sp_txt.font.size = Pt(9.5)
        r_sp_txt.font.color.rgb = RGBColor(30, 58, 138)

        # Código si existe
        if code_text:
            doc.add_paragraph().paragraph_format.space_after = Pt(2)
            c_table = doc.add_table(rows=1, cols=1)
            c_table.alignment = WD_TABLE_ALIGNMENT.CENTER
            cell_code = c_table.cell(0, 0)
            cell_code.width = Inches(6.8)
            set_cell_background(cell_code, "0F172A")
            set_cell_margins(cell_code, top=100, bottom=100, left=140, right=140)

            p_c = cell_code.paragraphs[0]
            p_c.paragraph_format.space_after = Pt(0)
            r_c_lbl = p_c.add_run("CÓDIGO DEMOSTRATIVO:\n")
            r_c_lbl.bold = True
            r_c_lbl.font.size = Pt(8.5)
            r_c_lbl.font.color.rgb = RGBColor(56, 189, 248)

            r_c_txt = p_c.add_run(code_text)
            r_c_txt.font.name = 'Consolas'
            r_c_txt.font.size = Pt(8.5)
            r_c_txt.font.color.rgb = RGBColor(241, 245, 249)

        # Explicación paso a paso si existe
        if line_items:
            doc.add_paragraph().paragraph_format.space_after = Pt(2)
            l_table = doc.add_table(rows=1, cols=1)
            l_table.alignment = WD_TABLE_ALIGNMENT.CENTER
            cell_line = l_table.cell(0, 0)
            cell_line.width = Inches(6.8)
            set_cell_background(cell_line, "F8FAFC")
            set_cell_left_border(cell_line, "94A3B8", sz="16")
            set_cell_margins(cell_line, top=100, bottom=100, left=140, right=140)

            p_l = cell_line.paragraphs[0]
            p_l.paragraph_format.space_after = Pt(0)
            r_l_lbl = p_l.add_run("EXPLICACIÓN PASO A PASO:\n")
            r_l_lbl.bold = True
            r_l_lbl.font.size = Pt(8.5)
            r_l_lbl.font.color.rgb = RGBColor(71, 85, 105)

            for idx, (k, v) in enumerate(line_items):
                p_item = cell_line.add_paragraph() if idx > 0 else p_l
                p_item.paragraph_format.space_after = Pt(2)
                r_dot = p_item.add_run("• ")
                r_k = p_item.add_run(f"{k}: ")
                r_k.bold = True
                r_k.font.size = Pt(8.5)
                r_k.font.color.rgb = RGBColor(30, 41, 59)
                r_v = p_item.add_run(v)
                r_v.font.size = Pt(8.5)
                r_v.font.color.rgb = RGBColor(71, 85, 105)

        doc.add_paragraph().paragraph_format.space_after = Pt(12)

    # SLIDE 1
    s1_speech = (
        '"Buenas tardes, profesor Josue Oteiza y compañeros. Junto a mi equipo conformado por Dylan Sandoval, '
        'Victor Martinez y Danilo Sepúlveda, venimos a presentar la solución que desarrollamos en base de datos '
        'para la tienda de instrumentos musicales \'Sonido Vivo\', ubicada en Viña del Mar. Nuestro objetivo fue '
        'transformar la gestión manual de la tienda en un sistema seguro, ordenado y automático usando directamente '
        'las capacidades de Oracle."'
    )
    add_slide_section(1, "Portada e Identificación", "Apertura", s1_speech)

    # SLIDE 2
    s2_speech = (
        '"Sonido Vivo vende guitarras, teclados y equipos de audio en Viña del Mar. Llevaban todo a mano en cuadernos '
        'y planillas de cálculo, con dos riesgos gravísimos: vender productos sin stock físico en bodega y la '
        'imposibilidad de aplicar descuentos automáticos por compras grandes. Con nuestra solución en Oracle PL/SQL, '
        'cada venta descuenta stock real y los descuentos se calculan solos en memoria."'
    )
    add_slide_section(2, "Contexto de Negocio y Problemática", "Criterio a", s2_speech)

    # SLIDE 3
    s3_speech = (
        '"Diseñamos la base de datos completamente normalizada: las categorías agrupan productos, los clientes compran '
        'y cada venta se divide en su detalle. Pero lo más potente son los candados que pusimos mediante restricciones '
        'CHECK: es imposible tener precios o stocks negativos, y ninguna boleta se guarda si el total no cuadra '
        'exactamente con subtotal menos descuento."'
    )
    s3_code = (
        "-- Candado matemático en VENTA\n"
        "CONSTRAINT chk_venta_totales CHECK (total = (subtotal - descuento))\n\n"
        "-- Candados físicos y de cálculo en DETALLE_VENTA\n"
        "CONSTRAINT chk_det_cant CHECK (cantidad > 0),\n"
        "CONSTRAINT chk_det_subtotal CHECK (subtotal_linea = cantidad * precio_unitario)"
    )
    s3_lines = [
        ("chk_venta_totales", "Obliga a nivel de kernel a que el total sea matemáticamente exacto; cancela cualquier inserción errónea."),
        ("chk_det_cant", "Prohíbe cantidades nulas o negativas (no se puede comprar 0 o menos guitarras)."),
        ("chk_det_subtotal", "Valida en el motor que subtotal sea cantidad multiplicada por el precio unitario.")
    ]
    add_slide_section(3, "Modelo Entidad-Relación y Reglas", "Script 01", s3_speech, s3_code, s3_lines)

    # SLIDE 4
    s4_speech = (
        '"Por un lado, el sistema recibe el catálogo con sus stocks críticos, los clientes con su nivel de fidelidad '
        'y las boletas emitidas en caja. Y con eso, nuestro motor calcula en memoria las tasas de descuento, consolida '
        'los balances en LIQUIDACION_CLIENTE y audita cualquier incidente en LOG_ERRORES."'
    )
    add_slide_section(4, "Datos que Procesa el Sistema", "Criterio b", s4_speech)

    # SLIDE 5
    s5_speech = (
        '"Para liquidar sin poner lento el servidor, usamos dos herramientas en memoria: un RECORD como cajita donde '
        'agrupamos cliente, total bruto, descuento y neto en una sola variable; y un VARRAY como lista fija con los '
        'descuentos de 0%, 5% y 10%. Al tener los porcentajes a mano en la memoria PGA, no hacemos SELECTs repetitivos '
        'al disco por cada cliente, haciendo el proceso veloz."'
    )
    s5_code = (
        "TYPE t_rec_liquidacion IS RECORD (\n"
        "    id_cliente CLIENTE.id_cliente%TYPE, total_bruto NUMBER(10),\n"
        "    tasa_descuento_pct NUMBER(5,2), total_neto NUMBER(10)\n"
        ");\n"
        "TYPE t_arr_tasas IS VARRAY(3) OF NUMBER(5,2);\n"
        "v_escalas_descuento t_arr_tasas := t_arr_tasas(0.00, 5.00, 10.00);\n\n"
        "IF v_liquidacion.total_bruto < 200000 THEN\n"
        "    v_liquidacion.tasa_descuento_pct := v_escalas_descuento(1); -- 0%\n"
        "ELSIF v_liquidacion.total_bruto BETWEEN 200000 AND 700000 THEN\n"
        "    v_liquidacion.tasa_descuento_pct := v_escalas_descuento(2); -- 5%\n"
        "ELSE\n"
        "    v_liquidacion.tasa_descuento_pct := v_escalas_descuento(3); -- 10%\n"
        "END IF;"
    )
    s5_lines = [
        ("RECORD", "Agrupa atributos heterogéneos actuando como DTO; el %TYPE asegura compatibilidad con la tabla."),
        ("VARRAY(3)", "Colección fija en memoria PGA que almacena las tasas base de descuento."),
        ("v_escalas_descuento(i)", "Recupera la tasa en microsegundos sin hacer consultas a disco ni cambios de contexto.")
    ]
    add_slide_section(5, "Descuentos con RECORD y VARRAY", "Script 02", s5_speech, s5_code, s5_lines)

    # SLIDE 6
    s6_speech = (
        '"Para revisar las compras usamos dos cursores en equipo: el cursor padre busca a los clientes con compras '
        'activas; y por cada uno, llama al cursor hijo pasándole el ID del cliente como parámetro. El cursor hijo '
        'consulta únicamente las compras de esa persona, evitando mezclar datos y mostrando un reporte ordenado boleta por boleta."'
    )
    s6_code = (
        "-- Cursor Padre: Clientes con ventas\n"
        "CURSOR c_clientes IS\n"
        "    SELECT id_cliente, nombres || ' ' || apellidos AS cliente_nombre\n"
        "    FROM CLIENTE c WHERE EXISTS (SELECT 1 FROM VENTA v WHERE v.id_cliente = c.id_cliente);\n\n"
        "-- Cursor Hijo Parametrizado: Detalle de ese cliente específico\n"
        "CURSOR c_ventas_cliente (p_id_cli CLIENTE.id_cliente%TYPE) IS\n"
        "    SELECT v.nro_boleta, p.nombre, d.cantidad, d.subtotal_linea\n"
        "    FROM VENTA v JOIN DETALLE_VENTA d ON v.id_venta = d.id_venta\n"
        "    JOIN PRODUCTO p ON d.id_producto = p.id_producto\n"
        "    WHERE v.id_cliente = p_id_cli;"
    )
    s6_lines = [
        ("WHERE EXISTS", "Optimiza la búsqueda deteniendo el escaneo apenas confirma la primera compra en el índice."),
        ("(p_id_cli ...)", "Parámetro formal que recibe el ID del cliente actual del bucle padre."),
        ("WHERE v.id_cliente = p_id_cli", "El optimizador filtra en la fuente usando índices, sin cargar productos cartesianos.")
    ]
    add_slide_section(6, "Cursores Explícitos y Bucles Anidados", "Script 03", s6_speech, s6_code, s6_lines)

    # SLIDE 7
    s7_speech = (
        '"El control de errores es el freno de mano. Atajamos errores de Oracle como NO_DATA_FOUND si un producto no '
        'existe, y errores propios de negocio como e_stock_insuficiente si piden más de lo que queda en bodega. Ante '
        'una falla, el sistema aplica un ROLLBACK para deshacer la venta a medias y anota el incidente en LOG_ERRORES '
        'para no interrumpir la operación."'
    )
    s7_code = (
        "IF v_cantidad_solicitada > v_stock_actual THEN\n"
        "    RAISE e_stock_insuficiente; -- Freno de mano\n"
        "END IF;\n"
        "...\n"
        "EXCEPTION\n"
        "    WHEN e_stock_insuficiente THEN\n"
        "        ROLLBACK; -- Deshace para no corromper la BD\n"
        "        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, usuario_bd, fecha_registro)\n"
        "        VALUES (SEQ_LOG_ERRORES.NEXTVAL, 'USR-001', 'Stock insuficiente para ' || v_nombre_prod, USER, SYSDATE);\n"
        "        COMMIT;"
    )
    s7_lines = [
        ("RAISE e_stock_insuficiente", "Interrumpe el flujo normal y salta inmediatamente a la sección EXCEPTION."),
        ("ROLLBACK", "Garantiza atomicidad ACID anulando cualquier modificación transaccional incompleta."),
        ("SEQ_LOG_ERRORES.NEXTVAL", "Genera la clave primaria de auditoría de forma atómica en memoria compartida (SGA).")
    ]
    add_slide_section(7, "Control de Excepciones y Auditoría", "Script 04", s7_speech, s7_code, s7_lines)

    # SLIDE 8 (Enfoque previsor)
    s8_speech = (
        '"Pensando en la siguiente etapa y en cómo este motor se va a conectar con la página web de Fullstack II, '
        'la rúbrica nos pedía plantear la arquitectura futura. Nosotros no quisimos dejarlo solamente como una idea '
        'en el papel: ya dejamos prevista, diseñada y construida de antemano la lógica de los triggers en el script '
        '05 del repositorio, dejándolos listos para cuando el negocio pase a producción: Primero, el trigger '
        'TRG_DESCUENTA_STOCK, para que al entrar una venta el stock en bodega baje automáticamente; y segundo, el '
        'trigger TRG_AUDITA_STOCK_CRITICO, que vigila la bodega y, si un producto queda en 3 unidades o menos, registra '
        'de inmediato una alerta en LOG_ERRORES. Además, están diseñados sobre tablas separadas para evitar el clásico '
        'error de tabla mutante (ORA-04091)."'
    )
    s8_code = (
        "-- Trigger 1 previsto: Rebaja automática al vender\n"
        "CREATE OR REPLACE TRIGGER TRG_DESCUENTA_STOCK\n"
        "AFTER INSERT ON DETALLE_VENTA\n"
        "FOR EACH ROW\n"
        "BEGIN\n"
        "    UPDATE PRODUCTO SET stock = stock - :NEW.cantidad WHERE id_producto = :NEW.id_producto;\n"
        "END;\n"
        "/\n\n"
        "-- Trigger 2 previsto: Alerta preventiva de bodega\n"
        "CREATE OR REPLACE TRIGGER TRG_AUDITA_STOCK_CRITICO\n"
        "AFTER UPDATE OF stock ON PRODUCTO FOR EACH ROW\n"
        "WHEN (NEW.stock <= NEW.stock_critico)\n"
        "BEGIN\n"
        "    INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error, usuario_bd, fecha_registro)\n"
        "    VALUES (SEQ_LOG_ERRORES.NEXTVAL, 'WARN-STOCK-CRITICO', 'ALERTA REPOSICIÓN: ' || :NEW.codigo, USER, SYSDATE);\n"
        "END;\n"
        "/"
    )
    s8_lines = [
        ("AFTER INSERT ON DETALLE_VENTA", "Descuenta el stock físico tras la confirmación atómica de cada producto."),
        ("WHEN (NEW.stock <= NEW.stock_critico)", "Filtro inteligente; solo alerta si el stock cae en zona de peligro."),
        ("Mitigación ORA-04091", "DETALLE_VENTA modifica la tabla externa PRODUCTO; no hay riesgo de mutación de tabla.")
    ]
    add_slide_section(8, "Arquitectura Futura: Triggers Previstos", "Script 05", s8_speech, s8_code, s8_lines)

    # SLIDE 9
    s9_speech = (
        '"En conclusión, profesor: cumplimos al 100% con los bloques anónimos de liquidación, cursores y excepciones '
        'que pedía la evaluación, y además dejamos la evolución futura totalmente planificada, con los triggers ya '
        'preparados de antemano en el repositorio para cuando conectemos la base de datos con la plataforma web. '
        'Muchas gracias por su tiempo, quedamos atentos a sus preguntas."'
    )
    add_slide_section(9, "Conclusiones y Ronda de Preguntas", "Cierre", s9_speech)

    # SECCIÓN Q&A
    doc.add_page_break()
    p_qa_h = doc.add_paragraph()
    r_qa_h = p_qa_h.add_run("Banco de Preguntas Frecuentes del Docente (Q&A de Emergencia)")
    r_qa_h.font.size = Pt(14)
    r_qa_h.font.bold = True
    r_qa_h.font.color.rgb = RGBColor(6, 95, 70) # Emerald 800
    p_qa_h.paragraph_format.space_after = Pt(8)

    qas = [
        ("P1: ¿Por qué usaron un VARRAY y no una tabla anidada (Nested Table)?",
         '"Elegimos VARRAY porque las escalas de descuento son una colección fija, acotada (3 tramos) y de orden estricto conocido de antemano. El VARRAY es más compacto y se aloja contiguamente en la memoria rápida (PGA)."'),
        ("P2: ¿Por qué parametrizar el cursor hijo y no hacer un solo JOIN masivo?",
         '"Porque necesitábamos mostrar un reporte jerárquico ordenado por cliente. Parametrizar permite que el motor de Oracle filtre en cada vuelta usando el índice del cliente, manteniendo el uso de memoria bajo control."'),
        ("P3: En LIQUIDACION_CLIENTE guardan nombre_completo, ¿eso no viola la 3FN respecto a CLIENTE?",
         '"Técnicamente sí, pero se aplica deliberadamente el patrón de Snapshot Histórico (Cierre Contable): una liquidación es un balance inmutable en el tiempo. Si el cliente cambia su apellido en el futuro, no debemos alterar el balance contable histórico."'),
        ("P4: ¿Por qué usan secuencias (SEQUENCE) y no MAX(id) + 1?",
         '"Porque MAX(id) + 1 falla si dos ventas ocurren al mismo tiempo (colisión de clave primaria). Las secuencias de Oracle entregan identificadores de forma atómica en memoria compartida sin bloqueos."'),
        ("P5: ¿Qué es una tabla mutante (ORA-04091) y cómo la previenen?",
         '"Ocurre cuando un trigger intenta consultar o modificar la misma tabla que lo disparó. En nuestros triggers lo evitamos porque el trigger se dispara en DETALLE_VENTA y modifica la tabla externa PRODUCTO."'),
        ("P6: ¿Tenemos triggers en esta entrega? (Respuesta con el encuadre previsor):",
         '"En esta entrega la pauta pedía bloques anónimos. Pero nosotros dejamos prevista, diseñada y construida de antemano la lógica de los triggers en el script 05, para que cuando la tienda pase a producción, los disparadores ya estén listos para funcionar."')
    ]

    for q, a in qas:
        qa_table = doc.add_table(rows=1, cols=1)
        qa_table.alignment = WD_TABLE_ALIGNMENT.CENTER
        cell_qa = qa_table.cell(0, 0)
        cell_qa.width = Inches(6.8)
        set_cell_background(cell_qa, "F0FDF4")
        set_cell_left_border(cell_qa, "10B981", sz="20")
        set_cell_margins(cell_qa, top=80, bottom=80, left=120, right=120)

        p = cell_qa.paragraphs[0]
        p.paragraph_format.space_after = Pt(2)
        rq = p.add_run(q + "\n")
        rq.bold = True
        rq.font.size = Pt(9.5)
        rq.font.color.rgb = RGBColor(6, 95, 70)

        ra_lbl = p.add_run("Respuesta: ")
        ra_lbl.bold = True
        ra_lbl.font.size = Pt(9)
        ra_lbl.font.color.rgb = RGBColor(4, 120, 87)

        ra = p.add_run(a)
        ra.font.size = Pt(9)
        ra.font.color.rgb = RGBColor(4, 120, 87)

        doc.add_paragraph().paragraph_format.space_after = Pt(4)

    doc.save(filename)
    print(f"Word generado exitosamente en: {filename}")

if __name__ == "__main__":
    create_word()
