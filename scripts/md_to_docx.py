#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Convierte TravelReady_DOCUMENTATION.md a un documento .docx formateado.
"""

import re
import sys
from pathlib import Path

try:
    from docx import Document
    from docx.shared import Inches, Pt, RGBColor
    from docx.enum.text import WD_ALIGN_PARAGRAPH
    from docx.enum.style import WD_STYLE_TYPE
    from docx.oxml.ns import qn
    from docx.oxml import OxmlElement
except ImportError:
    print("ERROR: python-docx no está instalado. Ejecuta: pip install python-docx")
    sys.exit(1)


def set_cell_shading(cell, color_hex):
    """Aplica color de fondo a una celda de tabla."""
    shading_elm = OxmlElement('w:shd')
    shading_elm.set(qn('w:fill'), color_hex)
    cell._tc.get_or_add_tcPr().append(shading_elm)


def add_hyperlink(paragraph, url, text):
    """Añade un hipervínculo a un párrafo."""
    part = paragraph.part
    r_id = part.relate_to(
        url,
        'http://schemas.openxmlformats.org/officeDocument/2006/relationships/hyperlink',
        is_external=True
    )
    hyperlink = OxmlElement('w:hyperlink')
    hyperlink.set(qn('r:id'), r_id)
    new_run = OxmlElement('w:r')
    rPr = OxmlElement('w:rPr')
    color = OxmlElement('w:color')
    color.set(qn('w:val'), '0563C1')
    rPr.append(color)
    u = OxmlElement('w:u')
    u.set(qn('w:val'), 'single')
    rPr.append(u)
    new_run.append(rPr)
    new_run.text = text
    hyperlink.append(new_run)
    paragraph._p.append(hyperlink)
    return hyperlink


def parse_markdown_table(lines, start_idx):
    """Parsea una tabla markdown y devuelve (filas, índice_final)."""
    rows = []
    i = start_idx
    while i < len(lines) and lines[i].strip().startswith('|'):
        # Ignorar la línea separadora (|-----|-----|)
        if re.match(r'^\|[\s\-:]+\|', lines[i].strip()):
            i += 1
            continue
        cells = [c.strip() for c in lines[i].strip().split('|')[1:-1]]
        if cells:
            rows.append(cells)
        i += 1
    return rows, i - 1


def process_bold_inline(text):
    """Procesa **bold** en texto."""
    parts = []
    pattern = r'\*\*(.*?)\*\*'
    last = 0
    for m in re.finditer(pattern, text):
        if m.start() > last:
            parts.append(('text', text[last:m.start()]))
        parts.append(('bold', m.group(1)))
        last = m.end()
    if last < len(text):
        parts.append(('text', text[last:]))
    return parts


def add_styled_paragraph(doc, text, style='Normal', bold=False, italic=False, font_size=None):
    """Añade un párrafo con estilo, procesando bold inline."""
    p = doc.add_paragraph(style=style)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.space_before = Pt(3)

    parts = process_bold_inline(text)
    for kind, content in parts:
        run = p.add_run(content)
        if kind == 'bold' or bold:
            run.bold = True
        run.italic = italic
        if font_size:
            run.font.size = Pt(font_size)

    return p


def main():
    project_dir = Path(__file__).parent.parent
    md_path = project_dir / 'TravelReady_DOCUMENTATION.md'
    docx_path = project_dir / 'TravelReady_DOCUMENTACION.docx'

    if not md_path.exists():
        print(f"ERROR: No se encontró {md_path}")
        sys.exit(1)

    doc = Document()

    # ── Configurar estilos ────────────────────────────────────────────────
    style = doc.styles['Normal']
    font = style.font
    font.name = 'Calibri'
    font.size = Pt(11)

    # Heading 1
    h1 = doc.styles['Heading 1']
    h1.font.name = 'Calibri'
    h1.font.size = Pt(20)
    h1.font.bold = True
    h1.font.color.rgb = RGBColor(0x0B, 0x3D, 0x45)

    # Heading 2
    h2 = doc.styles['Heading 2']
    h2.font.name = 'Calibri'
    h2.font.size = Pt(16)
    h2.font.bold = True
    h2.font.color.rgb = RGBColor(0x00, 0x65, 0x71)

    # Heading 3
    h3 = doc.styles['Heading 3']
    h3.font.name = 'Calibri'
    h3.font.size = Pt(13)
    h3.font.bold = True
    h3.font.color.rgb = RGBColor(0x33, 0x33, 0x33)

    # ── Leer markdown ─────────────────────────────────────────────────────
    content = md_path.read_text(encoding='utf-8')
    lines = content.splitlines()

    i = 0
    in_code_block = False
    code_lines = []

    while i < len(lines):
        line = lines[i]

        # Bloques de código
        if line.strip().startswith('```'):
            if in_code_block:
                # Fin de bloque de código
                p = doc.add_paragraph(style='Normal')
                p.paragraph_format.left_indent = Inches(0.3)
                p.paragraph_format.space_after = Pt(6)
                run = p.add_run('\n'.join(code_lines))
                run.font.name = 'Consolas'
                run.font.size = Pt(9)
                run.font.color.rgb = RGBColor(0x33, 0x33, 0x33)
                code_lines = []
                in_code_block = False
            else:
                in_code_block = True
            i += 1
            continue

        if in_code_block:
            code_lines.append(line)
            i += 1
            continue

        # Saltear líneas de separación
        if line.strip() == '---':
            i += 1
            continue

        # Saltear índice (links a anclas)
        if re.match(r'^\d+\.\s*\[.*\]\(#.*\)$', line.strip()):
            i += 1
            continue

        # Título H1
        if line.startswith('# '):
            text = line[2:].strip()
            doc.add_heading(text, level=1)
            i += 1
            continue

        # Título H2
        if line.startswith('## '):
            text = line[3:].strip()
            doc.add_heading(text, level=2)
            i += 1
            continue

        # Título H3
        if line.startswith('### '):
            text = line[4:].strip()
            doc.add_heading(text, level=3)
            i += 1
            continue

        # Imagen (ignorar por ahora)
        if line.strip().startswith('!['):
            i += 1
            continue

        # Tabla
        if line.strip().startswith('|'):
            rows, i = parse_markdown_table(lines, i)
            if rows:
                # Determinar número de columnas
                num_cols = max(len(r) for r in rows)
                table = doc.add_table(rows=len(rows), cols=num_cols)
                table.style = 'Table Grid'

                # Cabecera con color
                for r_idx, row in enumerate(rows):
                    for c_idx, cell_text in enumerate(row):
                        cell = table.rows[r_idx].cells[c_idx]
                        cell.text = cell_text
                        # Color de fondo para cabecera
                        if r_idx == 0:
                            set_cell_shading(cell, '0B3D45')
                            for para in cell.paragraphs:
                                for run in para.runs:
                                    run.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF)
                                    run.font.bold = True
                                    run.font.size = Pt(10)
                        else:
                            for para in cell.paragraphs:
                                for run in para.runs:
                                    run.font.size = Pt(10)
            i += 1
            continue

        # Lista numerada
        num_list_match = re.match(r'^(\d+)\.\s+(.*)', line)
        if num_list_match:
            text = num_list_match.group(2)
            p = doc.add_paragraph(style='List Number')
            p.paragraph_format.space_after = Pt(3)
            p.paragraph_format.left_indent = Inches(0.25)
            parts = process_bold_inline(text)
            for kind, content in parts:
                run = p.add_run(content)
                if kind == 'bold':
                    run.bold = True
            i += 1
            continue

        # Lista con viñetas
        bullet_match = re.match(r'^[-*]\s+(.*)', line)
        if bullet_match:
            text = bullet_match.group(1)
            # Checkbox
            if text.startswith('[x]') or text.startswith('[ ]'):
                checked = text.startswith('[x]')
                text = text[3:].strip()
                p = doc.add_paragraph(style='List Bullet')
                p.paragraph_format.space_after = Pt(2)
                p.paragraph_format.left_indent = Inches(0.25)
                checkbox = '☑ ' if checked else '☐ '
                run = p.add_run(checkbox + text)
            else:
                p = doc.add_paragraph(style='List Bullet')
                p.paragraph_format.space_after = Pt(2)
                p.paragraph_format.left_indent = Inches(0.25)
                parts = process_bold_inline(text)
                for kind, content in parts:
                    run = p.add_run(content)
                    if kind == 'bold':
                        run.bold = True
            i += 1
            continue

        # Línea en blanco
        if not line.strip():
            i += 1
            continue

        # Texto normal / párrafo
        # Detectar si es un "sub-elemento" indentado de una lista
        add_styled_paragraph(doc, line.strip())
        i += 1

    # ── Pie de página con fecha ──────────────────────────────────────────
    doc.add_paragraph()  # Espacio
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = p.add_run('Documentación generada para presentación del TravelReady - /2025')
    run.font.size = Pt(9)
    run.font.color.rgb = RGBColor(0x66, 0x66, 0x66)
    run.italic = True

    # ── Guardar ───────────────────────────────────────────────────────────
    doc.save(str(docx_path))
    print(f'✅ Documento creado: {docx_path}')
    print(f'   Ubicación: {docx_path.resolve()}')


if __name__ == '__main__':
    main()
