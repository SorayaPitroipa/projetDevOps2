import pytest
from pathlib import Path
from app.services.pdf_extractor import extract_text_from_pdf


def test_extract_text_from_pdf_file_not_found():
    fake_path = Path("uploads/nonexistent.pdf")
    with pytest.raises(FileNotFoundError):
        extract_text_from_pdf(fake_path)
