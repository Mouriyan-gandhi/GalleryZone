import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../coa/coa_pdf.dart' show pdfSafe;
import 'mou_document.dart';

const _margin = 18 * PdfPageFormat.mm;
const _grey = PdfColor.fromInt(0xFF6E6860);
const _rule = PdfColor.fromInt(0xFF969696);

/// The signed MOU as a PDF: the same blocks the screen shows, the blanks filled
/// from the same values ([mouFieldValue]), the drawn signature on the signature
/// line, the source PDF's running footer on every page, and an execution record
/// at the end. Port of `features/mou/mou-pdf.ts`. Built on the phone from data
/// the screen already has; nothing new is fetched.
///
/// The built-in fonts cover Latin-1 only, so typographic punctuation is mapped
/// to its plain equivalent (see [pdfSafe]).
Future<Uint8List> buildMouPdf(MouDocument document, MouFill fill) async {
  final regular = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();
  final italic = pw.Font.helveticaOblique();

  pw.TextStyle style(
    double size, {
    bool isBold = false,
    bool isItalic = false,
  }) => pw.TextStyle(
    font: isBold ? bold : (isItalic ? italic : regular),
    fontSize: size,
    lineSpacing: size * 0.45,
  );

  pw.Widget gap(double mm) => pw.SizedBox(height: mm * PdfPageFormat.mm);

  pw.Widget write(
    String text, {
    double size = 9.5,
    bool isBold = false,
    bool isItalic = false,
    bool center = false,
    double after = 1.8,
  }) => pw.Padding(
    padding: pw.EdgeInsets.only(bottom: after * PdfPageFormat.mm),
    child: pw.SizedBox(
      width: double.infinity,
      child: pw.Text(
        pdfSafe(text),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: style(size, isBold: isBold, isItalic: isItalic),
      ),
    ),
  );

  pw.Widget field(MouField block) {
    const size = 9.5;
    final value = mouFieldValue(block.key, fill, document.party);
    final label = pdfSafe('${block.label}: ');

    if (value is MouSignature) {
      final bytes = _imageBytes(value.image);
      return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 2 * PdfPageFormat.mm),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(label, style: style(size)),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // The pad is a wide strip; keep its proportions inside a 70 x 14 mm box.
                pw.SizedBox(
                  width: 70 * PdfPageFormat.mm,
                  height: 14 * PdfPageFormat.mm,
                  child: bytes == null
                      ? null
                      : pw.Align(
                          alignment: pw.Alignment.bottomLeft,
                          child: pw.Image(
                            pw.MemoryImage(bytes),
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                ),
                pw.Container(
                  width: 70 * PdfPageFormat.mm,
                  height: 0.5,
                  color: _rule,
                ),
                pw.SizedBox(height: 1.5 * PdfPageFormat.mm),
                pw.Text(pdfSafe(value.name), style: style(8.5, isItalic: true)),
              ],
            ),
          ],
        ),
      );
    }

    final text = switch (value) {
      MouFilled(:final text) => text,
      MouPending(:final text) => text,
      _ => null,
    };
    if (text == null) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 1.8 * PdfPageFormat.mm),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(label, style: style(size)),
            pw.Container(
              width: 70 * PdfPageFormat.mm,
              height: 0.5,
              margin: const pw.EdgeInsets.only(bottom: 2),
              color: _rule,
            ),
          ],
        ),
      );
    }
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 1.8 * PdfPageFormat.mm),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(text: label, style: style(size)),
            pw.TextSpan(
              text: pdfSafe(text),
              style: style(
                size,
                isBold: true,
              ).copyWith(decoration: pw.TextDecoration.underline),
            ),
          ],
        ),
      ),
    );
  }

  final body = <pw.Widget>[];
  for (final block in document.blocks) {
    switch (block) {
      case MouTitle():
        body.add(
          write(block.text, size: 15, isBold: true, center: true, after: 3),
        );
      case MouHeading():
        body
          ..add(gap(2))
          ..add(
            write(
              block.text,
              size: 10.5,
              isBold: true,
              center: block.center,
              after: 2,
            ),
          );
      case MouSubheading():
        body
          ..add(gap(0.8))
          ..add(write(block.text, isBold: true));
      case MouParagraph():
        body.add(write(block.text, center: block.center));
      case MouItem():
        body.add(
          pw.Padding(
            padding: pw.EdgeInsets.only(
              left: 3 * PdfPageFormat.mm,
              bottom: 1.2 * PdfPageFormat.mm,
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 6 * PdfPageFormat.mm,
                  child: pw.Text(pdfSafe(block.marker), style: style(9.5)),
                ),
                pw.Expanded(
                  child: pw.Text(pdfSafe(block.text), style: style(9.5)),
                ),
              ],
            ),
          ),
        );
      case MouSigner():
        body
          ..add(gap(5))
          ..add(write(block.text, size: 10, isBold: true, after: 2.5));
      case MouField():
        body.add(field(block));
      case MouNote():
        body
          ..add(gap(4))
          ..add(write(block.text, size: 7.5, isItalic: true));
    }
  }

  // What the platform recorded, after the document and set apart from it.
  body
    ..add(gap(6))
    ..add(pw.Divider(color: const PdfColor.fromInt(0xFFBEBEBE), thickness: 0.5))
    ..add(gap(2))
    ..add(
      write('Electronic execution record', size: 9, isBold: true, after: 1.5),
    )
    ..add(
      write(
        'Signed electronically on the Galleryzone platform by ${fill.signatureName ?? ''} on ${mouDateTime(fill.date)}.',
        size: 8.5,
      ),
    )
    ..add(
      write(
        '${document.title}, version ${document.version}. The details filled in above are those recorded at the '
        'moment of signing.',
        size: 8.5,
      ),
    );

  final pdf = pw.Document(
    title: pdfSafe(document.title),
    author: 'GalleryZone',
    creator: 'GalleryZone',
  );
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(_margin),
      footer: (context) => pw.Padding(
        padding: pw.EdgeInsets.only(top: 4 * PdfPageFormat.mm),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              pdfSafe(document.footer),
              style: style(7).copyWith(color: _grey),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: style(7).copyWith(color: _grey),
            ),
          ],
        ),
      ),
      build: (context) => body,
    ),
  );
  return pdf.save();
}

Uint8List? _imageBytes(String? dataUrl) {
  if (dataUrl == null || dataUrl.isEmpty) return null;
  try {
    return UriData.parse(dataUrl).contentAsBytes();
  } catch (_) {
    // A malformed image only loses the drawing; the typed name beside it still stands.
    return null;
  }
}

/// `Galleryzone-artist-MOU-2026.3-Ananya-Rao.pdf`
String mouPdfFileName(MouDocument document, MouFill fill) {
  final who = (fill.signatureName ?? 'signed').replaceAll(
    RegExp(r'[^A-Za-z0-9]+'),
    '-',
  );
  return 'Galleryzone-${document.party.name}-MOU-${document.version}-$who.pdf';
}

/// Hands the finished file to the share sheet. A seam: tests have none to talk to.
typedef ShareMouPdf = Future<void> Function(Uint8List bytes, String fileName);

Future<void> shareMouPdf(Uint8List bytes, String fileName) =>
    Printing.sharePdf(bytes: bytes, filename: fileName);
