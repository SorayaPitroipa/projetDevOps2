from pathlib import Path
from PyPDF2 import PdfReader
from PyPDF2.errors import EmptyFileError, PdfReadError

try:
    from pdf2image import convert_from_path
    import pytesseract
except ImportError:
    convert_from_path = None  # type: ignore
    pytesseract = None  # type: ignore


def _extract_text_with_pdfreader(pdf_path: Path) -> str:
    try:
        reader = PdfReader(str(pdf_path))
    except (PdfReadError, EmptyFileError, ValueError):
        return ""

    text = []
    for page in reader.pages:
        page_text = page.extract_text()
        if page_text:
            text.append(page_text)
    return "\n".join(text)


def _extract_text_with_ocr(pdf_path: Path) -> str:
    if convert_from_path is None or pytesseract is None:
        return ""

    try:
        pages = convert_from_path(str(pdf_path))
    except Exception:
        return ""

    texts = []
    for page in pages:
        try:
            text = pytesseract.image_to_string(page, lang="fra+eng")
            if text:
                texts.append(text)
        except Exception:
            continue
    return "\n".join(texts)


def extract_text_from_pdf(pdf_path: Path) -> str:
    text = _extract_text_with_pdfreader(pdf_path)
    if text.strip():
        return text
    return _extract_text_with_ocr(pdf_path)
