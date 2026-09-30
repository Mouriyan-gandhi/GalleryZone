import { jsPDF } from "jspdf";
import { mouDateTime, mouFieldValue, type MouBlock, type MouDocument, type MouFill } from "./mou-document";

const PAGE_WIDTH = 210; // A4, mm
const PAGE_HEIGHT = 297;
const MARGIN = 18;
const FOOTER_SPACE = 12;
const CONTENT_WIDTH = PAGE_WIDTH - MARGIN * 2;
const PT = 0.3528; // mm per point
const MINUS = "−"; // U+2212: not in Helvetica's encoding, drawn from Symbol as the source PDF does

/**
 * The signed MOU as a PDF: the same blocks the screen shows, the blanks
 * filled from the same values (mouFieldValue), the drawn signature on the
 * signature line, the source PDF's running footer on every page, and an
 * execution record at the end. Built in the browser from data the page
 * already has; nothing new is fetched.
 */
export function downloadMouPdf(document_: MouDocument, fill: MouFill) {
  const doc = new jsPDF({ unit: "mm", format: "a4" });
  let y = MARGIN;

  const lineHeight = (size: number) => size * PT * 1.45;
  function ensureSpace(height: number) {
    if (y + height > PAGE_HEIGHT - MARGIN - FOOTER_SPACE) {
      doc.addPage();
      y = MARGIN;
    }
  }
  function font(size: number, style: "normal" | "bold" | "italic") {
    doc.setFont("helvetica", style);
    doc.setFontSize(size);
  }

  // One already-wrapped line. Any minus sign is drawn from the Symbol font,
  // piece by piece, so the line keeps its exact characters.
  function drawLine(line: string, x: number, style: "normal" | "bold" | "italic", center: boolean) {
    if (!line.includes(MINUS)) {
      doc.text(line, center ? PAGE_WIDTH / 2 : x, y, { baseline: "top", align: center ? "center" : "left" });
      return;
    }
    const parts = line.split(MINUS);
    const minusWidth = () => {
      doc.setFont("symbol", "normal");
      const w = doc.getTextWidth("-");
      doc.setFont("helvetica", style);
      return w;
    };
    const total = parts.reduce((w, p) => w + doc.getTextWidth(p), 0) + minusWidth() * (parts.length - 1);
    let cx = center ? (PAGE_WIDTH - total) / 2 : x;
    parts.forEach((part, i) => {
      doc.setFont("helvetica", style);
      doc.text(part, cx, y, { baseline: "top" });
      cx += doc.getTextWidth(part);
      if (i < parts.length - 1) {
        doc.setFont("symbol", "normal");
        doc.text("-", cx, y, { baseline: "top" });
        cx += doc.getTextWidth("-");
      }
    });
    doc.setFont("helvetica", style);
  }

  function write(text: string, opts: { size?: number; style?: "normal" | "bold" | "italic"; center?: boolean; indent?: number; after?: number } = {}) {
    const size = opts.size ?? 9.5;
    const style = opts.style ?? "normal";
    const indent = opts.indent ?? 0;
    font(size, style);
    const lines = doc.splitTextToSize(text, CONTENT_WIDTH - indent) as string[];
    for (const line of lines) {
      ensureSpace(lineHeight(size));
      drawLine(line, MARGIN + indent, style, Boolean(opts.center));
      y += lineHeight(size);
    }
    y += opts.after ?? 1.8;
  }

  function writeField(block: Extract<MouBlock, { type: "field" }>) {
    const size = 9.5;
    const value = mouFieldValue(block.key, fill, document_.party);
    font(size, "normal");
    const label = `${block.label}: `;
    const labelWidth = doc.getTextWidth(label);
    const x = MARGIN + labelWidth;

    if (value.kind === "signature") {
      const imageHeight = 14;
      ensureSpace(imageHeight + lineHeight(size) * 2);
      doc.text(label, MARGIN, y + imageHeight - lineHeight(size), { baseline: "top" });
      if (value.image) {
        try {
          // The pad is a wide strip; keep its proportions inside a 70 × 14 mm box.
          const { width, height } = doc.getImageProperties(value.image);
          const w = Math.min(70, (width / height) * imageHeight);
          doc.addImage(value.image, "PNG", x, y + imageHeight - (w / width) * height, w, (w / width) * height);
        } catch {
          // A malformed image only loses the drawing; the typed name below still stands.
        }
      }
      y += imageHeight;
      doc.setDrawColor(150);
      doc.line(x, y + 0.5, x + 70, y + 0.5);
      y += 1.5;
      font(8.5, "italic");
      doc.text(value.name, x, y, { baseline: "top" });
      y += lineHeight(8.5) + 2;
      return;
    }

    const text = value.kind === "text" || value.kind === "pending" ? value.text : null;
    if (!text) {
      ensureSpace(lineHeight(size));
      doc.text(label, MARGIN, y, { baseline: "top" });
      doc.setDrawColor(150);
      doc.line(x, y + size * PT + 0.6, x + 70, y + size * PT + 0.6);
      y += lineHeight(size) + 1.8;
      return;
    }
    font(size, "bold");
    const lines = doc.splitTextToSize(text, CONTENT_WIDTH - labelWidth) as string[];
    lines.forEach((line, i) => {
      ensureSpace(lineHeight(size));
      if (i === 0) {
        font(size, "normal");
        doc.text(label, MARGIN, y, { baseline: "top" });
        font(size, "bold");
      }
      doc.text(line, x, y, { baseline: "top" });
      doc.setDrawColor(150);
      doc.line(x, y + size * PT + 0.6, x + doc.getTextWidth(line), y + size * PT + 0.6);
      y += lineHeight(size);
    });
    y += 1.8;
  }

  for (const block of document_.blocks) {
    switch (block.type) {
      case "title":
        write(block.text, { size: 15, style: "bold", center: true, after: 3 });
        break;
      case "heading":
        y += 2;
        write(block.text, { size: 10.5, style: "bold", center: block.center, after: 2 });
        break;
      case "subheading":
        y += 0.8;
        write(block.text, { size: 9.5, style: "bold" });
        break;
      case "paragraph":
        write(block.text, { center: block.center });
        break;
      case "item": {
        font(9.5, "normal");
        ensureSpace(lineHeight(9.5));
        doc.text(block.marker, MARGIN + 3, y, { baseline: "top" });
        write(block.text, { indent: 9, after: 1.2 });
        break;
      }
      case "signer":
        y += 5;
        write(block.text, { size: 10, style: "bold", after: 2.5 });
        break;
      case "field":
        writeField(block);
        break;
      case "note":
        y += 4;
        write(block.text, { size: 7.5, style: "italic" });
        break;
    }
  }

  // What the platform recorded, after the document and set apart from it.
  y += 6;
  ensureSpace(30);
  doc.setDrawColor(190);
  doc.line(MARGIN, y, PAGE_WIDTH - MARGIN, y);
  y += 5;
  write("Electronic execution record", { size: 9, style: "bold", after: 1.5 });
  write(`Signed electronically on the Galleryzone platform by ${fill.signatureName ?? ""} on ${mouDateTime(fill.date)}.`, { size: 8.5 });
  write(`${document_.title}, version ${document_.version}. The details filled in above are those recorded at the moment of signing.`, { size: 8.5 });

  const pages = doc.getNumberOfPages();
  for (let page = 1; page <= pages; page++) {
    doc.setPage(page);
    font(7, "normal");
    doc.setTextColor(110);
    doc.text(document_.footer, MARGIN, PAGE_HEIGHT - 10);
    doc.text(`Page ${page} of ${pages}`, PAGE_WIDTH - MARGIN, PAGE_HEIGHT - 10, { align: "right" });
    doc.setTextColor(0);
  }

  const who = (fill.signatureName ?? "signed").replace(/[^A-Za-z0-9]+/g, "-");
  doc.save(`Galleryzone-${document_.party}-MOU-${document_.version}-${who}.pdf`);
}
