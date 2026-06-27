import io
import os
from datetime import datetime, timezone

from sqlalchemy.orm import Session

from app.core.config import get_settings, get_app_setting
from app.core.logging import get_logger
from app.domain.models import Invoice, PaymentLog, Transaction, gen_uuid

logger = get_logger(__name__)


class InvoiceService:
    def __init__(self, db: Session):
        self.db = db
        self.settings = get_settings()
        self.coins_per_usd = get_app_setting(db, "coins_per_usd", self.settings.coins_per_usd)

    def generate_invoice_number(self) -> str:
        prefix = "INV"
        seq = self.db.query(Invoice).count() + 1
        return f"{prefix}-{datetime.now(timezone.utc).strftime('%Y%m')}-{seq:05d}"

    def create_invoice(self, user_id: str, items: list[dict],
                       billing_address: dict | None = None,
                       notes: str = "") -> Invoice:
        coins_per_usd = self.coins_per_usd or 100
        total = sum(item.get("amount", 0) for item in items)
        invoice = Invoice(
            id=gen_uuid(),
            user_id=user_id,
            invoice_number=self.generate_invoice_number(),
            amount_usd=round(total, 2),
            amount_coins=int(total * coins_per_usd),
            status="pending",
            items=items,
            billing_address=billing_address,
            tax_amount=0.0,
            total_amount=round(total, 2),
            notes=notes,
        )
        self.db.add(invoice)
        self.db.commit()
        return invoice

    def get_user_invoices(self, user_id: str, limit: int = 50,
                           offset: int = 0) -> list[Invoice]:
        return self.db.query(Invoice).filter(
            Invoice.user_id == user_id,
        ).order_by(Invoice.created_at.desc()).offset(offset).limit(limit).all()

    def get_invoice(self, invoice_id: str) -> Invoice | None:
        return self.db.query(Invoice).filter(Invoice.id == invoice_id).first()

    def mark_paid(self, invoice_id: str, payment_log_id: str = ""):
        invoice = self.get_invoice(invoice_id)
        if not invoice:
            return None
        invoice.status = "paid"
        invoice.paid_at = datetime.now(timezone.utc)
        self.db.commit()
        return invoice

    def cancel_invoice(self, invoice_id: str):
        invoice = self.get_invoice(invoice_id)
        if not invoice:
            return None
        invoice.status = "cancelled"
        self.db.commit()
        return invoice

    def generate_pdf(self, invoice_id: str) -> bytes | None:
        invoice = self.get_invoice(invoice_id)
        if not invoice:
            return None
        try:
            from reportlab.lib.pagesizes import A4
            from reportlab.platypus import (
                SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
            )
            from reportlab.lib.styles import ParagraphStyle
            from reportlab.lib import colors
            from reportlab.lib.units import mm
            from reportlab.lib.enums import TA_CENTER, TA_LEFT
            from reportlab.pdfbase import pdfmetrics
            from reportlab.pdfbase.ttfonts import TTFont

            pdfmetrics.registerFont(TTFont('Vazirmatn', '/usr/share/fonts/vazirmatn-vf-fonts/Vazirmatn[wght].ttf'))

            INK = colors.HexColor('#1A1A2E')
            BODY = colors.HexColor('#666680')
            MUTED = colors.HexColor('#9999A8')
            SUCCESS = colors.HexColor('#22C55E')
            HAIRLINE = colors.HexColor('#E8E8EF')
            WHITE = colors.white
            YELLOW_BG = colors.HexColor('#FEF9E7')
            YELLOW_BORDER = colors.HexColor('#F5A623')

            buf = io.BytesIO()
            doc = SimpleDocTemplate(
                buf, pagesize=A4,
                topMargin=15*mm, bottomMargin=15*mm,
                leftMargin=15*mm, rightMargin=15*mm,
            )

            h1 = ParagraphStyle('h1', fontName='Vazirmatn', fontSize=20, leading=28,
                                alignment=TA_CENTER, textColor=INK, spaceAfter=4)
            h2 = ParagraphStyle('h2', fontName='Vazirmatn', fontSize=10, leading=14,
                                alignment=TA_CENTER, textColor=SUCCESS)
            section = ParagraphStyle('sec', fontName='Vazirmatn', fontSize=12, leading=16,
                                     alignment=TA_LEFT, textColor=INK)
            label = ParagraphStyle('lbl', fontName='Vazirmatn', fontSize=9, leading=13,
                                   alignment=TA_LEFT, textColor=MUTED)
            value = ParagraphStyle('val', fontName='Vazirmatn', fontSize=10, leading=14,
                                   alignment=TA_LEFT, textColor=INK)
            value_bold = ParagraphStyle('valb', fontName='Vazirmatn', fontSize=10, leading=14,
                                        alignment=TA_LEFT, textColor=INK)
            success_val = ParagraphStyle('sv', fontName='Vazirmatn', fontSize=10, leading=14,
                                         alignment=TA_LEFT, textColor=SUCCESS)

            elements = []

            # === HEADER ===
            elements.append(Spacer(1, 10))
            header_data = [[Paragraph('Stroapp — E-Invoice', h1)]]
            ht = Table(header_data, colWidths=[doc.width])
            ht.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), WHITE),
                ('TOPPADDING', (0, 0), (-1, -1), 20),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
                ('LEFTPADDING', (0, 0), (-1, -1), 20),
                ('RIGHTPADDING', (0, 0), (-1, -1), 20),
                ('BOX', (0, 0), (-1, 0), 1, HAIRLINE),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ]))
            elements.append(ht)

            # Status
            st_data = [[Paragraph('Transaction completed successfully', h2)]]
            st = Table(st_data, colWidths=[doc.width])
            st.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), WHITE),
                ('TOPPADDING', (0, 0), (-1, -1), 4),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 20),
                ('BOX', (0, 0), (-1, 0), 1, HAIRLINE),
            ]))
            elements.append(st)
            elements.append(Spacer(1, 10))

            # Invoice number
            info = [[Paragraph('Invoice Number', label),
                     Paragraph(f'#{invoice.invoice_number}', value)]]
            it = Table(info, colWidths=[doc.width * 0.4, doc.width * 0.6])
            it.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, -1), WHITE),
                ('TOPPADDING', (0, 0), (-1, -1), 8),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
                ('LEFTPADDING', (0, 0), (-1, -1), 20),
                ('RIGHTPADDING', (0, 0), (-1, -1), 20),
                ('BOX', (0, 0), (-1, -1), 1, HAIRLINE),
                ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ]))
            elements.append(it)
            elements.append(Spacer(1, 16))

            # === PAYMENT DETAILS ===
            elements.append(Paragraph('Payment Details', section))
            elements.append(Spacer(1, 8))

            tx_notes = invoice.notes or ''
            tx_id = tx_notes.replace('Transaction: ', '') if tx_notes.startswith('Transaction: ') else ''
            items = invoice.items or []
            first_item = items[0] if items else {}
            description = first_item.get('description', '')
            reference = first_item.get('reference', '')

            dr = [
                [Paragraph('Transaction ID', label), Paragraph(tx_id if tx_id else '---', value)],
                [Paragraph('Date', label),
                 Paragraph(invoice.created_at.strftime('%Y/%m/%d  %H:%M') if invoice.created_at else '---', value)],
                [Paragraph('Product', label), Paragraph(description, value)],
            ]
            if reference:
                dr.append([Paragraph('Reference', label), Paragraph(reference, value)])

            dt = Table(dr, colWidths=[doc.width * 0.35, doc.width * 0.65])
            ds = [
                ('BACKGROUND', (0, 0), (-1, -1), WHITE),
                ('TOPPADDING', (0, 0), (-1, -1), 8),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 8),
                ('LEFTPADDING', (0, 0), (-1, -1), 20),
                ('RIGHTPADDING', (0, 0), (-1, -1), 20),
                ('BOX', (0, 0), (-1, -1), 1, HAIRLINE),
                ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ]
            for i in range(len(dr) - 1):
                ds.append(('LINEBELOW', (0, i), (-1, i), 0.5, HAIRLINE))
            dt.setStyle(TableStyle(ds))
            elements.append(dt)
            elements.append(Spacer(1, 16))

            # === SUMMARY ===
            elements.append(Paragraph('Amount Summary', section))
            elements.append(Spacer(1, 8))

            amount = first_item.get('amount', 0)
            coins = invoice.amount_coins

            sr = [
                [Paragraph('Amount', label), Paragraph(f'${amount:.2f}', value_bold)],
                [Paragraph('Coins Received', label), Paragraph(f'+{coins} coins', value_bold)],
            ]

            if tx_notes:
                tx_obj = self.db.query(Transaction).filter(Transaction.id == tx_id).first() if tx_id else None
                if tx_obj and tx_obj.coins_before is not None:
                    sr.append([Paragraph('Balance Before', label),
                               Paragraph(f'{tx_obj.coins_before} coins', value)])
                if tx_obj and tx_obj.coins_after is not None:
                    sr.append([Paragraph('Balance After', label),
                               Paragraph(f'{tx_obj.coins_after} coins', value)])

            sr.append([Paragraph('Total', label), Paragraph(f'${invoice.total_amount:.2f}', value_bold)])
            sr.append([Paragraph('Status', label), Paragraph('Completed', success_val)])

            stb = Table(sr, colWidths=[doc.width * 0.35, doc.width * 0.65])
            ss = [
                ('BACKGROUND', (0, 0), (-1, -1), WHITE),
                ('TOPPADDING', (0, 0), (-1, -1), 7),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 7),
                ('LEFTPADDING', (0, 0), (-1, -1), 20),
                ('RIGHTPADDING', (0, 0), (-1, -1), 20),
                ('BOX', (0, 0), (-1, -1), 1, HAIRLINE),
                ('ALIGN', (1, 0), (1, -1), 'LEFT'),
            ]
            for i in range(len(sr) - 1):
                ss.append(('LINEBELOW', (0, i), (-1, i), 0.5, HAIRLINE))
            stb.setStyle(TableStyle(ss))
            elements.append(stb)
            elements.append(Spacer(1, 20))

            # === FOOTER ===
            fd = [[Paragraph(
                'This is an electronic invoice certified by Stroapp',
                ParagraphStyle('ft', fontName='Vazirmatn', fontSize=9, leading=14,
                               alignment=TA_CENTER, textColor=BODY),
            )]]
            ft = Table(fd, colWidths=[doc.width])
            ft.setStyle(TableStyle([
                ('BACKGROUND', (0, 0), (-1, 0), YELLOW_BG),
                ('TOPPADDING', (0, 0), (-1, -1), 12),
                ('BOTTOMPADDING', (0, 0), (-1, -1), 12),
                ('LEFTPADDING', (0, 0), (-1, -1), 20),
                ('RIGHTPADDING', (0, 0), (-1, -1), 20),
                ('BOX', (0, 0), (-1, 0), 1, YELLOW_BORDER),
                ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
            ]))
            elements.append(ft)
            elements.append(Spacer(1, 20))
            elements.append(Paragraph(
                'Stroapp — SMS Verification Platform',
                ParagraphStyle('br', fontName='Vazirmatn', fontSize=7, leading=10,
                               alignment=TA_CENTER, textColor=MUTED),
            ))

            doc.build(elements)
            return buf.getvalue()

        except ImportError as e:
            logger.warning(f"reportlab not installed: {e}")
            return b""
        except Exception as e:
            logger.error(f"PDF generation error: {e}")
            import traceback
            logger.error(traceback.format_exc())
            return b""
