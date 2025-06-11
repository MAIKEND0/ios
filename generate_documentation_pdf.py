#!/usr/bin/env python3
"""
KSR Cranes App Documentation PDF Generator
Generates a comprehensive PDF from markdown documentation files
"""

import os
from datetime import datetime
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak, Table, TableStyle
from reportlab.platypus import Image, KeepTogether, Indenter
from reportlab.lib import colors
from reportlab.lib.enums import TA_JUSTIFY, TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.pdfgen import canvas
from reportlab.lib.utils import ImageReader
import re

class NumberedCanvas(canvas.Canvas):
    """Custom canvas for page numbering and headers"""
    def __init__(self, *args, **kwargs):
        canvas.Canvas.__init__(self, *args, **kwargs)
        self._saved_page_states = []

    def showPage(self):
        self._saved_page_states.append(dict(self.__dict__))
        self._startPage()

    def save(self):
        """Add page numbers and headers to all pages"""
        num_pages = len(self._saved_page_states)
        for state in self._saved_page_states:
            self.__dict__.update(state)
            self.draw_page_number(num_pages)
            canvas.Canvas.showPage(self)
        canvas.Canvas.save(self)

    def draw_page_number(self, page_count):
        """Draw page number and header"""
        self.saveState()
        
        # Header
        self.setFont("Helvetica-Bold", 10)
        self.drawString(inch, letter[1] - 0.5*inch, "KSR Cranes App - Documentation")
        
        # Page number
        self.setFont("Helvetica", 9)
        page_num = self._pageNumber
        text = f"Page {page_num} of {page_count}"
        self.drawRightString(letter[0] - inch, 0.5*inch, text)
        
        # Footer line
        self.setStrokeColor(colors.grey)
        self.setLineWidth(0.5)
        self.line(inch, 0.75*inch, letter[0] - inch, 0.75*inch)
        
        self.restoreState()

def create_styles():
    """Create custom styles for the PDF"""
    styles = getSampleStyleSheet()
    
    # Title style
    styles.add(ParagraphStyle(
        name='CustomTitle',
        parent=styles['Title'],
        fontSize=24,
        textColor=colors.HexColor('#1a5490'),
        spaceAfter=30,
        alignment=TA_CENTER
    ))
    
    # Heading styles
    styles.add(ParagraphStyle(
        name='CustomHeading1',
        parent=styles['Heading1'],
        fontSize=18,
        textColor=colors.HexColor('#1a5490'),
        spaceBefore=20,
        spaceAfter=12,
        borderWidth=1,
        borderColor=colors.HexColor('#1a5490'),
        borderPadding=5
    ))
    
    styles.add(ParagraphStyle(
        name='CustomHeading2',
        parent=styles['Heading2'],
        fontSize=16,
        textColor=colors.HexColor('#2c5282'),
        spaceBefore=15,
        spaceAfter=10
    ))
    
    styles.add(ParagraphStyle(
        name='CustomHeading3',
        parent=styles['Heading3'],
        fontSize=14,
        textColor=colors.HexColor('#2c5282'),
        spaceBefore=12,
        spaceAfter=8
    ))
    
    # Code style
    styles.add(ParagraphStyle(
        name='CodeBlock',
        parent=styles['Code'],
        fontSize=8,
        fontName='Courier',
        backgroundColor=colors.HexColor('#f5f5f5'),
        borderWidth=1,
        borderColor=colors.grey,
        borderPadding=8,
        spaceBefore=10,
        spaceAfter=10
    ))
    
    # Bullet style
    styles.add(ParagraphStyle(
        name='CustomBullet',
        parent=styles['Normal'],
        leftIndent=20,
        bulletIndent=10
    ))
    
    return styles

def clean_markdown(text):
    """Clean markdown text for PDF rendering"""
    # Remove HTML comments
    text = re.sub(r'<!--.*?-->', '', text, flags=re.DOTALL)
    
    # Convert markdown links to text
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    
    # Convert inline code
    text = re.sub(r'`([^`]+)`', r'<font name="Courier">\1</font>', text)
    
    # Convert bold
    text = re.sub(r'\*\*([^\*]+)\*\*', r'<b>\1</b>', text)
    
    # Convert italic
    text = re.sub(r'\*([^\*]+)\*', r'<i>\1</i>', text)
    
    # Escape special characters
    text = text.replace('&', '&amp;')
    text = text.replace('<', '&lt;').replace('>', '&gt;')
    
    # Restore formatted tags
    text = text.replace('&lt;b&gt;', '<b>').replace('&lt;/b&gt;', '</b>')
    text = text.replace('&lt;i&gt;', '<i>').replace('&lt;/i&gt;', '</i>')
    text = text.replace('&lt;font', '<font').replace('&lt;/font&gt;', '</font>')
    
    return text

def process_markdown_file(file_path, styles):
    """Process a markdown file and convert to reportlab elements"""
    elements = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split into lines for processing
    lines = content.split('\n')
    
    in_code_block = False
    code_block_content = []
    
    for line in lines:
        # Skip empty lines unless in code block
        if not line.strip() and not in_code_block:
            continue
            
        # Handle code blocks
        if line.strip().startswith('```'):
            if in_code_block:
                # End code block
                code_text = '\n'.join(code_block_content)
                if code_text:
                    # Split long code blocks
                    if len(code_text) > 2000:
                        chunks = [code_text[i:i+2000] for i in range(0, len(code_text), 2000)]
                        for chunk in chunks:
                            elements.append(Paragraph(clean_markdown(chunk), styles['CodeBlock']))
                            elements.append(Spacer(1, 6))
                    else:
                        elements.append(Paragraph(clean_markdown(code_text), styles['CodeBlock']))
                code_block_content = []
                in_code_block = False
            else:
                # Start code block
                in_code_block = True
            continue
            
        if in_code_block:
            code_block_content.append(line)
            continue
        
        # Handle headers
        if line.startswith('# '):
            elements.append(PageBreak())
            elements.append(Paragraph(clean_markdown(line[2:]), styles['CustomTitle']))
        elif line.startswith('## '):
            elements.append(Paragraph(clean_markdown(line[3:]), styles['CustomHeading1']))
        elif line.startswith('### '):
            elements.append(Paragraph(clean_markdown(line[4:]), styles['CustomHeading2']))
        elif line.startswith('#### '):
            elements.append(Paragraph(clean_markdown(line[5:]), styles['CustomHeading3']))
        
        # Handle bullet points
        elif line.strip().startswith('- ') or line.strip().startswith('* '):
            bullet_text = '• ' + clean_markdown(line.strip()[2:])
            elements.append(Paragraph(bullet_text, styles['CustomBullet']))
        
        # Handle numbered lists
        elif re.match(r'^\d+\.\s', line.strip()):
            elements.append(Paragraph(clean_markdown(line.strip()), styles['CustomBullet']))
        
        # Handle horizontal rules
        elif line.strip() in ['---', '***', '___']:
            elements.append(Spacer(1, 12))
            elements.append(Table([['']], colWidths=[6.5*inch], style=[
                ('LINEABOVE', (0, 0), (-1, -1), 1, colors.grey)
            ]))
            elements.append(Spacer(1, 12))
        
        # Regular paragraph
        elif line.strip():
            # Check if it's a table row
            if '|' in line and line.count('|') >= 2:
                # Skip table parsing for now - too complex for simple implementation
                continue
            else:
                elements.append(Paragraph(clean_markdown(line), styles['Normal']))
                elements.append(Spacer(1, 6))
    
    return elements

def create_cover_page(styles):
    """Create a cover page for the documentation"""
    elements = []
    
    # Add some spacing
    elements.append(Spacer(1, 2*inch))
    
    # Title
    elements.append(Paragraph("KSR Cranes App", styles['CustomTitle']))
    elements.append(Spacer(1, 0.5*inch))
    
    # Subtitle
    subtitle_style = ParagraphStyle(
        name='Subtitle',
        parent=styles['Normal'],
        fontSize=18,
        alignment=TA_CENTER,
        textColor=colors.HexColor('#2c5282')
    )
    elements.append(Paragraph("Complete Documentation Suite", subtitle_style))
    elements.append(Spacer(1, 2*inch))
    
    # Details
    details_style = ParagraphStyle(
        name='Details',
        parent=styles['Normal'],
        fontSize=12,
        alignment=TA_CENTER
    )
    
    elements.append(Paragraph("Crane Operator Staffing Management System", details_style))
    elements.append(Spacer(1, 0.5*inch))
    elements.append(Paragraph(f"Generated: {datetime.now().strftime('%B %d, %Y')}", details_style))
    elements.append(Spacer(1, 2*inch))
    
    # Table of contents preview
    toc_data = [
        ['Documentation Contents:'],
        ['1. Project Architecture'],
        ['2. API Services Documentation'],
        ['3. Feature Modules Documentation'],
        ['4. Server API Documentation'],
        ['5. Documentation Index']
    ]
    
    toc_table = Table(toc_data, colWidths=[4*inch])
    toc_table.setStyle(TableStyle([
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (0, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, -1), 12),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
    ]))
    
    elements.append(toc_table)
    elements.append(PageBreak())
    
    return elements

def generate_pdf():
    """Generate the complete documentation PDF"""
    output_file = "/Users/maksymilianmarcinowski/Desktop/KSR Cranes App/KSR_Cranes_Complete_Documentation.pdf"
    
    # Create PDF document
    doc = SimpleDocTemplate(
        output_file,
        pagesize=letter,
        rightMargin=inch,
        leftMargin=inch,
        topMargin=inch,
        bottomMargin=inch
    )
    
    # Get styles
    styles = create_styles()
    
    # Build content
    elements = []
    
    # Add cover page
    elements.extend(create_cover_page(styles))
    
    # Documentation files to include
    doc_files = [
        ("DOCUMENTATION_INDEX.md", "Documentation Index"),
        ("PROJECT_ARCHITECTURE.md", "Project Architecture"),
        ("API_SERVICES_DOCUMENTATION.md", "API Services Documentation"),
        ("FEATURE_MODULES_DOCUMENTATION.md", "Feature Modules Documentation"),
        ("SERVER_API_DOCUMENTATION.md", "Server API Documentation")
    ]
    
    # Process each documentation file
    for file_name, title in doc_files:
        file_path = f"/Users/maksymilianmarcinowski/Desktop/KSR Cranes App/{file_name}"
        if os.path.exists(file_path):
            print(f"Processing {file_name}...")
            file_elements = process_markdown_file(file_path, styles)
            elements.extend(file_elements)
        else:
            print(f"Warning: {file_name} not found")
    
    # Build PDF
    try:
        doc.build(elements, canvasmaker=NumberedCanvas)
        print(f"\nPDF successfully generated: {output_file}")
        return output_file
    except Exception as e:
        print(f"Error generating PDF: {e}")
        return None

if __name__ == "__main__":
    generate_pdf()