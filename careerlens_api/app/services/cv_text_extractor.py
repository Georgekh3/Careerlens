from io import BytesIO

from docx import Document
from pypdf import PdfReader


class UnsupportedCvFormatError(ValueError):
    pass


class CvTextExtractor:
    def extract_text(self, *, file_bytes: bytes, original_filename: str) -> tuple[str, str]:
        extension = self._extension(original_filename)

        if extension == "pdf":
            return self._extract_pdf_text(file_bytes), "pypdf"
        if extension == "docx":
            return self._extract_docx_text(file_bytes), "python-docx"
        if extension == "doc":
            raise UnsupportedCvFormatError(
                "DOC extraction is not supported yet. Please upload PDF or DOCX."
            )

        raise UnsupportedCvFormatError("Unsupported CV file format.")

    def _extract_pdf_text(self, file_bytes: bytes) -> str:
        reader = PdfReader(BytesIO(file_bytes))
        pages = [(page.extract_text() or "").strip() for page in reader.pages]
        return "\n\n".join(page for page in pages if page).strip()

    def _extract_docx_text(self, file_bytes: bytes) -> str:
        document = Document(BytesIO(file_bytes))
        paragraphs = [paragraph.text.strip() for paragraph in document.paragraphs]
        return "\n".join(text for text in paragraphs if text).strip()

    def _extension(self, original_filename: str) -> str:
        return original_filename.rsplit(".", 1)[-1].lower().strip() if "." in original_filename else ""
