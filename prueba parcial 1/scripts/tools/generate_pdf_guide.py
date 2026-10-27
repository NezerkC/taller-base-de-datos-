"""Script para compilar la Guía de Defensa Oral y Explicación de Código a formato PDF profesional usando ReportLab.
"""

from reportlab.lib import colors
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import inch
from reportlab.platypus import (
    HRFlowable,
    KeepTogether,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


def create_pdf(filename="docs/entregables/Guia_Defensa_SonidoVivo_EP1.pdf"):
  doc = SimpleDocTemplate(
      filename,
      pagesize=letter,
      leftMargin=36,
      rightMargin=36,
      topMargin=36,
      bottomMargin=36,
  )

  styles = getSampleStyleSheet()

  # Estilos personalizados
  c_primary = colors.HexColor("#0f172a")  # Slate 900
  c_accent = colors.HexColor("#2563eb")  # Blue 600
  c_speech_bg = colors.HexColor("#eff6ff")  # Blue 50
  c_code_bg = colors.HexColor("#0f172a")  # Dark code bg
  c_card_border = colors.HexColor("#cbd5e1")
  c_meta_bg = colors.HexColor("#f8fafc")
  c_qa_bg = colors.HexColor("#f0fdf4")  # Emerald 50
  c_qa_border = colors.HexColor("#10b981")

  style_title = ParagraphStyle(
      "DocTitle",
      parent=styles["Normal"],
      fontName="Helvetica-Bold",
      fontSize=18,
      leading=22,
      textColor=c_primary,
      spaceAfter=4,
  )

  style_subtitle = ParagraphStyle(
      "DocSubtitle",
      parent=styles["Normal"],
      fontName="Helvetica-Bold",
      fontSize=11,
      leading=15,
      textColor=c_accent,
      spaceAfter=8,
  )

  style_meta = ParagraphStyle(
      "DocMeta",
      parent=styles["Normal"],
      fontName="Helvetica",
      fontSize=8.5,
      leading=12,
      textColor=colors.HexColor("#334155"),
  )

  style_slide_title = ParagraphStyle(
      "SlideTitle",
      parent=styles["Normal"],
      fontName="Helvetica-Bold",
      fontSize=11,
      leading=14,
      textColor=colors.white,
  )

  style_speech_label = ParagraphStyle(
      "SpeechLabel",
      parent=styles["Normal"],
      fontName="Helvetica-Bold",
      fontSize=8.5,
      leading=11,
      textColor=c_accent,
  )

  style_speech = ParagraphStyle(
      "SpeechText",
      parent=styles["Normal"],
      fontName="Helvetica-Oblique",
      fontSize=9,
      leading=13,
      textColor=colors.HexColor("#1e3a8a"),
  )

  style_code = ParagraphStyle(
      "CodeText",
      parent=styles["Normal"],
      fontName="Courier",
      fontSize=7.5,
      leading=10.5,
      textColor=colors.HexColor("#f1f5f9"),
  )

  style_line_label = ParagraphStyle(
      "LineLabel",
      parent=styles["Normal"],
      fontName="Helvetica-Bold",
      fontSize=8,
      leading=11,
      textColor=colors.HexColor("#475569"),
  )

  style_line_text = ParagraphStyle(
      "LineText",
      parent=styles["Normal"],
      fontName="Helvetica",
      fontSize=8,
      leading=11,
      textColor=colors.HexColor("#334155"),
  )

  style_qa_q = ParagraphStyle(
      "QAQuestion",
      parent=styles["Normal"],
      fontName="Helvetica-Bold",
      fontSize=9,
      leading=12,
      textColor=colors.HexColor("#065f46"),
  )

  style_qa_a = ParagraphStyle(
      "QAAnswer",
      parent=styles["Normal"],
      fontName="Helvetica",
      fontSize=8.5,
      leading=12,
      textColor=colors.HexColor("#047857"),
  )

  elements = []

  # Encabezado principal
  elements.append(
      Paragraph(
          "BDY1103 — TALLER DE BASE DE DATOS | DUOC UC (EVALUACIÓN PARCIAL N°"
          " 1)",
          style_subtitle,
      )
  )
  elements.append(
      Paragraph(
          "Guía de Defensa Oral y Explicación de Código — Sonido Vivo",
          style_title,
      )
  )

  meta_data = [
      [
          Paragraph("<b>Proyecto:</b> Sonido Vivo (Viña del Mar)", style_meta),
          Paragraph("<b>Docente Evaluador:</b> Josue Oteiza", style_meta),
      ],
      [
          Paragraph(
              "<b>Integrantes:</b> Dylan Sandoval, Victor Martinez, Danilo"
              " Sepúlveda",
              style_meta,
          ),
          Paragraph(
              "<b>Estado del Repo:</b> Sincronizado en <code>main</code> (Scripts"
              " 01 al 05)",
              style_meta,
          ),
      ],
  ]
  meta_table = Table(meta_data, colWidths=[270, 270])
  meta_table.setStyle(
      TableStyle([
          ("BACKGROUND", (0, 0), (-1, -1), c_meta_bg),
          ("BOX", (0, 0), (-1, -1), 1, c_card_border),
          ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
          ("PADDING", (0, 0), (-1, -1), 5),
      ])
  )
  elements.append(meta_table)
  elements.append(Spacer(1, 12))

  def make_slide(
      slide_num, title, badge, speech_text, code_text=None, line_items=None
  ):
    flowables = []

    # Barra de título de Diapositiva
    header_data = [[
        Paragraph(f"DIAPOSITIVA {slide_num}: {title}", style_slide_title),
        Paragraph(
            f"<b>{badge.upper()}</b>",
            ParagraphStyle(
                "Badge",
                parent=style_slide_title,
                alignment=2,
                fontSize=8,
                textColor=colors.HexColor("#93c5fd"),
            ),
        ),
    ]]
    t_header = Table(header_data, colWidths=[440, 100])
    t_header.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), c_primary),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("PADDING", (0, 0), (-1, -1), 6),
        ])
    )
    flowables.append(t_header)

    # Caja de Voz (Qué decir)
    speech_data = [[Paragraph(
        "<b>🎙️ QUÉ DECIR EN LA PRESENTACIÓN:</b><br/>" + speech_text,
        style_speech,
    )]]
    t_speech = Table(speech_data, colWidths=[540])
    t_speech.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), c_speech_bg),
            ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#bfdbfe")),
            ("LINEBEFORE", (0, 0), (0, 0), 4, c_accent),
            ("PADDING", (0, 0), (-1, -1), 7),
        ])
    )
    flowables.append(t_speech)

    # Código si aplica
    if code_text:
      code_data = [[
          Paragraph(
              "<b>CÓDIGO DEMOSTRATIVO:</b><br/>" + code_text.replace("\n", "<br/>").replace(" ", "&nbsp;"),
              style_code,
          )
      ]]
      t_code = Table(code_data, colWidths=[540])
      t_code.setStyle(
          TableStyle([
              ("BACKGROUND", (0, 0), (-1, -1), c_code_bg),
              ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#334155")),
              ("PADDING", (0, 0), (-1, -1), 6),
          ])
      )
      flowables.append(t_code)

    # Explicación paso a paso si aplica
    if line_items:
      items_html = "<br/>".join([f"• <b>{k}:</b> {v}" for k, v in line_items])
      lines_data = [[
          Paragraph("<b>EXPLICACIÓN PASO A PASO:</b><br/>" + items_html, style_line_text)
      ]]
      t_lines = Table(lines_data, colWidths=[540])
      t_lines.setStyle(
          TableStyle([
              ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#f8fafc")),
              ("BOX", (0, 0), (-1, -1), 1, c_card_border),
              ("PADDING", (0, 0), (-1, -1), 6),
          ])
      )
      flowables.append(t_lines)

    flowables.append(Spacer(1, 10))
    return KeepTogether(flowables)

  # SLIDE 1
  s1_speech = (
      '"Buenas tardes, profesor Josue Oteiza y compañeros. Junto a mi equipo'
      " conformado por Dylan Sandoval, Victor Martinez y Danilo Sepúlveda,"
      " venimos a presentar la solución que desarrollamos en base de datos para"
      " la tienda de instrumentos musicales 'Sonido Vivo', ubicada en Viña del"
      " Mar. Nuestro objetivo fue transformar la gestión manual de la tienda en"
      " un sistema seguro, ordenado y automático usando directamente las"
      ' capacidades de Oracle."'
  )
  elements.append(
      make_slide(
          1,
          "Portada e Identificación",
          "Apertura",
          s1_speech,
      )
  )

  # SLIDE 2
  s2_speech = (
      '"Sonido Vivo vende guitarras, teclados y equipos de audio en Viña del'
      " Mar. Llevaban todo a mano en cuadernos y planillas, con dos riesgos"
      " gravísimos: vender productos sin stock físico en bodega y la"
      " imposibilidad de aplicar descuentos automáticos por compras grandes. Con"
      " nuestra solución en Oracle PL/SQL, cada venta descuenta stock real y los"
      ' descuentos se calculan solos en memoria."'
  )
  elements.append(
      make_slide(
          2,
          "Contexto de Negocio y Problemática",
          "Criterio a",
          s2_speech,
      )
  )

  # SLIDE 3
  s3_speech = (
      '"Diseñamos la base de datos completamente normalizada: las categorías'
      " agrupan productos, los clientes compran y cada venta se divide en su"
      " detalle. Pero lo más potente son los candados que pusimos mediante"
      " restricciones CHECK: es imposible tener precios o stocks negativos, y"
      " ninguna boleta se guarda si el total no cuadra exactamente con subtotal"
      ' menos descuento."'
  )
  s3_code = (
      "-- Candado matemático en VENTA\n"
      "CONSTRAINT chk_venta_totales CHECK (total = (subtotal - descuento))\n\n"
      "-- Candados físicos y de cálculo en DETALLE_VENTA\n"
      "CONSTRAINT chk_det_cant CHECK (cantidad > 0),\n"
      "CONSTRAINT chk_det_subtotal CHECK (subtotal_linea = cantidad *"
      " precio_unitario)"
  )
  s3_lines = [
      (
          "chk_venta_totales",
          (
              "Obliga a nivel de kernel a que el total sea matemáticamente"
              " exacto; cancela cualquier inserción errónea."
          ),
      ),
      (
          "chk_det_cant",
          (
              "Prohíbe cantidades nulas o negativas (no se puede comprar 0 o"
              " menos guitarras)."
          ),
      ),
      (
          "chk_det_subtotal",
          (
              "Valida en el motor que subtotal sea cantidad multiplicada por el"
              " precio unitario."
          ),
      ),
  ]
  elements.append(
      make_slide(
          3,
          "Modelo Entidad-Relación y Reglas",
          "Script 01",
          s3_speech,
          s3_code,
          s3_lines,
      )
  )

  # SLIDE 4
  s4_speech = (
      '"Por un lado, el sistema recibe el catálogo con sus stocks críticos, los'
      " clientes con su nivel de fidelidad y las boletas emitidas en caja. Y con"
      " eso, nuestro motor calcula en memoria las tasas de descuento, consolida"
      " los balances en LIQUIDACION_CLIENTE y audita cualquier incidente en"
      ' LOG_ERRORES."'
  )
  elements.append(
      make_slide(
          4,
          "Datos que Procesa el Sistema",
          "Criterio b",
          s4_speech,
      )
  )

  # SLIDE 5
  s5_speech = (
      '"Para liquidar sin poner lento el servidor, usamos dos herramientas en'
      " memoria: un RECORD como cajita donde agrupamos cliente, total bruto,"
      " descuento y neto en una sola variable; y un VARRAY como lista fija con"
      " los descuentos de 0%, 5% y 10%. Al tener los porcentajes a mano en la"
      " memoria PGA, no hacemos SELECTs repetitivos al disco por cada cliente,"
      ' haciendo el proceso veloz."'
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
      (
          "RECORD",
          (
              "Agrupa atributos heterogéneos actuando como DTO; el %TYPE"
              " asegura compatibilidad con la tabla."
          ),
      ),
      (
          "VARRAY(3)",
          (
              "Colección fija en memoria PGA que almacena las tasas base de"
              " descuento."
          ),
      ),
      (
          "v_escalas_descuento(i)",
          (
              "Recupera la tasa en microsegundos sin hacer consultas a disco ni"
              " cambios de contexto SQL/PLSQL."
          ),
      ),
  ]
  elements.append(
      make_slide(
          5,
          "Descuentos con RECORD y VARRAY",
          "Script 02",
          s5_speech,
          s5_code,
          s5_lines,
      )
  )

  # SLIDE 6
  s6_speech = (
      '"Para revisar las compras usamos dos cursores en equipo: el cursor padre'
      " busca a los clientes con compras activas; y por cada uno, llama al"
      " cursor hijo pasándole el ID del cliente como parámetro. El cursor hijo"
      " consulta únicamente las compras de esa persona, evitando mezclar datos y"
      ' mostrando un reporte ordenado boleta por boleta."'
  )
  s6_code = (
      "-- Cursor Padre: Clientes con ventas\n"
      "CURSOR c_clientes IS\n"
      "    SELECT id_cliente, nombres || ' ' || apellidos AS cliente_nombre\n"
      "    FROM CLIENTE c WHERE EXISTS (SELECT 1 FROM VENTA v WHERE"
      " v.id_cliente = c.id_cliente);\n\n"
      "-- Cursor Hijo Parametrizado: Detalle de ese cliente específico\n"
      "CURSOR c_ventas_cliente (p_id_cli CLIENTE.id_cliente%TYPE) IS\n"
      "    SELECT v.nro_boleta, p.nombre, d.cantidad, d.subtotal_linea\n"
      "    FROM VENTA v JOIN DETALLE_VENTA d ON v.id_venta = d.id_venta\n"
      "    JOIN PRODUCTO p ON d.id_producto = p.id_producto\n"
      "    WHERE v.id_cliente = p_id_cli;"
  )
  s6_lines = [
      (
          "WHERE EXISTS",
          (
              "Optimiza la búsqueda deteniendo el escaneo apenas confirma la"
              " primera compra en el índice."
          ),
      ),
      (
          "(p_id_cli ...)",
          "Parámetro formal que recibe el ID del cliente actual del bucle padre.",
      ),
      (
          "WHERE v.id_cliente = p_id_cli",
          (
              "El optimizador filtra en la fuente usando índices, sin cargar"
              " productos cartesianos en memoria."
          ),
      ),
  ]
  elements.append(
      make_slide(
          6,
          "Cursores Explícitos y Bucles Anidados",
          "Script 03",
          s6_speech,
          s6_code,
          s6_lines,
      )
  )

  # SLIDE 7
  s7_speech = (
      '"El control de errores es el freno de mano. Atajamos errores de Oracle'
      " como NO_DATA_FOUND si un producto no existe, y errores propios de"
      " negocio como e_stock_insuficiente si piden más de lo que queda en"
      " bodega. Ante una falla, el sistema aplica un ROLLBACK para deshacer la"
      " venta a medias y anota el incidente en LOG_ERRORES para no interrumpir"
      ' la operación."'
  )
  s7_code = (
      "IF v_cantidad_solicitada > v_stock_actual THEN\n"
      "    RAISE e_stock_insuficiente; -- Freno de mano\n"
      "END IF;\n"
      "...\n"
      "EXCEPTION\n"
      "    WHEN e_stock_insuficiente THEN\n"
      "        ROLLBACK; -- Deshace para no corromper la BD\n"
      "        INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error,"
      " usuario_bd, fecha_registro)\n"
      "        VALUES (SEQ_LOG_ERRORES.NEXTVAL, 'USR-001', 'Stock insuficiente"
      " para ' || v_nombre_prod, USER, SYSDATE);\n"
      "        COMMIT;"
  )
  s7_lines = [
      (
          "RAISE e_stock_insuficiente",
          (
              "Interrumpe el flujo normal y salta inmediatamente a la sección"
              " EXCEPTION."
          ),
      ),
      (
          "ROLLBACK",
          (
              "Garantiza atomicidad ACID anulando cualquier modificación"
              " transaccional incompleta."
          ),
      ),
      (
          "SEQ_LOG_ERRORES.NEXTVAL",
          (
              "Genera la clave primaria de auditoría de forma atómica en"
              " memoria compartida (SGA)."
          ),
      ),
  ]
  elements.append(
      make_slide(
          7,
          "Control de Excepciones y Auditoría",
          "Script 04",
          s7_speech,
          s7_code,
          s7_lines,
      )
  )

  # SLIDE 8 (Enfoque previsor solicitado por el usuario)
  s8_speech = (
      '"Pensando en la siguiente etapa y en cómo este motor se va a conectar'
      " con la página web de Fullstack II, la rúbrica nos pedía plantear la"
      " arquitectura futura. Nosotros no quisimos dejarlo solamente como una"
      " idea en el papel: ya dejamos prevista, diseñada y construida de"
      " antemano la lógica de los triggers en el script 05 del repositorio,"
      " dejándolos listos para cuando el negocio pase a producción: Primero, el"
      " trigger TRG_DESCUENTA_STOCK, para que al entrar una venta el stock en"
      " bodega baje automáticamente; y segundo, el trigger"
      " TRG_AUDITA_STOCK_CRITICO, que vigila la bodega y, si un producto queda"
      " en 3 unidades o menos, registra de inmediato una alerta en LOG_ERRORES."
      " Además, están diseñados sobre tablas separadas para evitar el clásico"
      ' error de tabla mutante (ORA-04091)."'
  )
  s8_code = (
      "-- Trigger 1 previsto: Rebaja automática al vender\n"
      "CREATE OR REPLACE TRIGGER TRG_DESCUENTA_STOCK\n"
      "AFTER INSERT ON DETALLE_VENTA\n"
      "FOR EACH ROW\n"
      "BEGIN\n"
      "    UPDATE PRODUCTO SET stock = stock - :NEW.cantidad WHERE id_producto"
      " = :NEW.id_producto;\n"
      "END;\n"
      "/\n\n"
      "-- Trigger 2 previsto: Alerta preventiva de bodega\n"
      "CREATE OR REPLACE TRIGGER TRG_AUDITA_STOCK_CRITICO\n"
      "AFTER UPDATE OF stock ON PRODUCTO FOR EACH ROW\n"
      "WHEN (NEW.stock <= NEW.stock_critico)\n"
      "BEGIN\n"
      "    INSERT INTO LOG_ERRORES (id_log, codigo_error, mensaje_error,"
      " usuario_bd, fecha_registro)\n"
      "    VALUES (SEQ_LOG_ERRORES.NEXTVAL, 'WARN-STOCK-CRITICO', 'ALERTA"
      " REPOSICIÓN: ' || :NEW.codigo, USER, SYSDATE);\n"
      "END;\n"
      "/"
  )
  s8_lines = [
      (
          "AFTER INSERT ON DETALLE_VENTA",
          (
              "Descuenta el stock físico tras la confirmación atómica de cada"
              " producto."
          ),
      ),
      (
          "WHEN (NEW.stock <= NEW.stock_critico)",
          (
              "Filtro inteligente; solo alerta si el stock cae en zona de"
              " peligro para reabastecimiento."
          ),
      ),
      (
          "Mitigación ORA-04091",
          (
              "DETALLE_VENTA modifica la tabla externa PRODUCTO; no hay riesgo"
              " de mutación de tabla."
          ),
      ),
  ]
  elements.append(
      make_slide(
          8,
          "Arquitectura Futura: Triggers Previstos",
          "Script 05",
          s8_speech,
          s8_code,
          s8_lines,
      )
  )

  # SLIDE 9
  s9_speech = (
      '"En conclusión, profesor: cumplimos al 100% con los bloques anónimos de'
      " liquidación, cursores y excepciones que pedía la evaluación, y además"
      " dejamos la evolución futura totalmente planificada, con los triggers ya"
      " preparados de antemano en el repositorio para cuando conectemos la base"
      " de datos con la plataforma web. Muchas gracias por su tiempo, quedamos"
      ' atentos a sus preguntas."'
  )
  elements.append(
      make_slide(
          9,
          "Conclusiones y Ronda de Preguntas",
          "Cierre",
          s9_speech,
      )
  )

  # BANCO Q&A
  elements.append(PageBreak())
  elements.append(
      Paragraph(
          "Banco de Preguntas Frecuentes del Docente (Q&A de Emergencia)",
          style_title,
      )
  )
  elements.append(
      HRFlowable(
          width="100%", thickness=1.5, color=c_accent, spaceAfter=12, spaceBefore=4
      )
  )

  qas = [
      (
          "P1: ¿Por qué usaron un VARRAY y no una tabla anidada (Nested Table)?",
          (
              '"Elegimos VARRAY porque las escalas de descuento son una'
              " colección fija, acotada (3 tramos) y de orden estricto conocido"
              " de antemano. El VARRAY es más compacto y se aloja contiguamente"
              ' en la memoria rápida (PGA)."'
          ),
      ),
      (
          (
              "P2: ¿Por qué parametrizar el cursor hijo y no hacer un solo JOIN"
              " masivo?"
          ),
          (
              '"Porque necesitábamos mostrar un reporte jerárquico ordenado por'
              " cliente. Parametrizar permite que el motor de Oracle filtre en"
              " cada vuelta usando el índice del cliente, manteniendo el uso de"
              ' memoria bajo control."'
          ),
      ),
      (
          (
              "P3: En LIQUIDACION_CLIENTE guardan nombre_completo, ¿eso no"
              " viola la 3FN respecto a CLIENTE?"
          ),
          (
              '"Técnicamente sí, pero se aplica deliberadamente el patrón de'
              " Snapshot Histórico (Cierre Contable): una liquidación es un"
              " balance inmutable en el tiempo. Si el cliente cambia su apellido"
              " en el futuro, no debemos alterar el balance contable histórico."
          ),
      ),
      (
          "P4: ¿Por qué usan secuencias (SEQUENCE) y no MAX(id) + 1?",
          (
              '"Porque MAX(id) + 1 falla si dos ventas ocurren al mismo tiempo'
              " (colisión de clave primaria). Las secuencias de Oracle entregan"
              " identificadores de forma atómica en memoria compartida sin"
              ' bloqueos."'
          ),
      ),
      (
          "P5: ¿Qué es una tabla mutante (ORA-04091) y cómo la previenen?",
          (
              '"Ocurre cuando un trigger intenta consultar o modificar la misma'
              " tabla que lo disparó. En nuestros triggers lo evitamos porque"
              " el trigger se dispara en DETALLE_VENTA y modifica la tabla"
              ' externa PRODUCTO."'
          ),
      ),
      (
          (
              "P6: ¿Tenemos triggers en esta entrega? (Respuesta con el encuadre"
              " previsor):"
          ),
          (
              '"En esta entrega la pauta pedía bloques anónimos. Pero nosotros'
              " dejamos prevista, diseñada y construida de antemano la lógica de"
              " los triggers en el script 05, para que cuando la tienda pase a"
              ' producción, los disparadores ya estén listos para funcionar."'
          ),
      ),
  ]

  for q, a in qas:
    t_qa = Table(
        [[
            Paragraph(q, style_qa_q),
        ], [Paragraph("<b>Respuesta:</b> " + a, style_qa_a)]],
        colWidths=[540],
    )
    t_qa.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), c_qa_bg),
            ("BOX", (0, 0), (-1, -1), 1, colors.HexColor("#a7f3d0")),
            ("LINEBEFORE", (0, 0), (0, -1), 4, c_qa_border),
            ("PADDING", (0, 0), (-1, -1), 6),
        ])
    )
    elements.append(t_qa)
    elements.append(Spacer(1, 8))

  doc.build(elements)
  print(f"PDF generado exitosamente en: {filename}")


if __name__ == "__main__":
  create_pdf()
