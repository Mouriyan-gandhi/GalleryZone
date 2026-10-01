import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/verify_url.dart';

/// What the certificate prints - the same fields the website's PDF carries.
class CoaPdfInput {
  const CoaPdfInput({
    required this.artworkId,
    required this.title,
    required this.artistName,
    required this.category,
    required this.medium,
    required this.coaCertificateNumber,
    required this.coaIssueDate,
    required this.ownerName,
    this.productCode,
    this.dimensions,
    this.yearCreated,
  });

  final String artworkId;
  final String? productCode;
  final String title;
  final String artistName;
  final String category;
  final String medium;
  final String? dimensions;
  final int? yearCreated;
  final String coaCertificateNumber;
  final String coaIssueDate;

  /// The current legal owner as the passport records it.
  final String ownerName;

  /// The file the person is offered.
  String get fileName => 'GalleryZone-CoA-$coaCertificateNumber.pdf';
}

const _gold = PdfColor.fromInt(0xFFB0843A);
const _ink = PdfColor.fromInt(0xFF1A1612);
const _muted = PdfColor.fromInt(0xFF6E6860);

/// The PDF's built-in fonts cover Latin-1 only. Typographic punctuation that
/// titles and names often carry is mapped to its plain equivalent, and anything
/// else outside the range becomes a question mark rather than a blank.
String pdfSafe(String text) {
  const swaps = {
    '‘': "'",
    '’': "'",
    '“': '"',
    '”': '"',
    '–': '-',
    '—': '-',
    '…': '...',
    ' ': ' ',
  };
  final out = StringBuffer();
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    out.write(swaps[char] ?? (rune <= 0xFF ? char : '?'));
  }
  return out.toString();
}

String _longDate(String iso) {
  final date = DateTime.tryParse(iso);
  return date == null ? '-' : DateFormat('d MMMM y').format(date.toLocal());
}

/// The digital Certificate of Authenticity, built from the same passport data
/// the public page shows. The QR resolves to that page, so a printed copy is
/// verifiable by anyone with a phone. It is a record of what GalleryZone has
/// registered; the hand-signed paper version is requested separately.
///
/// [now] and [compress] exist so a test can build it deterministically and read
/// the text back out.
Future<Uint8List> buildCoaPdf(CoaPdfInput input, {DateTime? now, bool compress = true}) async {
  final doc = pw.Document(title: 'Certificate of Authenticity', author: 'GalleryZone', compress: compress);
  final generated = DateFormat('d MMM y, h:mm a').format(now ?? DateTime.now());
  final url = verifyUrlFor(input.artworkId);

  final regular = pw.Font.helvetica();
  final serifBold = pw.Font.timesBold();
  final serifBoldItalic = pw.Font.timesBoldItalic();

  pw.TextStyle style(double size, PdfColor color, {pw.Font? font}) =>
      pw.TextStyle(font: font ?? regular, fontSize: size, color: color);

  final details = <(String, String)>[
    ('Product code', (input.productCode ?? '').isEmpty ? '-' : input.productCode!),
    ('Category', input.category),
    ('Medium', input.medium),
    ('Dimensions', (input.dimensions ?? '').isEmpty ? '-' : input.dimensions!),
    ('Year', input.yearCreated == null ? '-' : '${input.yearCreated}'),
    ('Certificate issued', _longDate(input.coaIssueDate)),
    ('Registered legal owner', input.ownerName),
  ];

  const statement =
      'is an original work registered on GalleryZone. Its provenance - the chain of legal ownership from the '
      "artist onward - is recorded on the platform's ledger and can be verified at any time by scanning the code "
      'below or visiting the address beneath it. This digital certificate reflects the record as of the date of '
      'download; the hand-signed paper certificate issued by the artist on request is the physical counterpart of '
      'this record.';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.all(10 * PdfPageFormat.mm),
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(border: pw.Border.all(color: _gold, width: 0.6)),
        padding: pw.EdgeInsets.all(2.5 * PdfPageFormat.mm),
        child: pw.Container(
          decoration: pw.BoxDecoration(border: pw.Border.all(color: _gold, width: 0.2)),
          padding: pw.EdgeInsets.fromLTRB(
            10 * PdfPageFormat.mm,
            20 * PdfPageFormat.mm,
            10 * PdfPageFormat.mm,
            6 * PdfPageFormat.mm,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text('G A L L E R Y Z O N E', style: style(9, _gold)),
              pw.SizedBox(height: 12 * PdfPageFormat.mm),
              pw.Text('Certificate of Authenticity', style: style(24, _ink, font: serifBold)),
              pw.SizedBox(height: 3 * PdfPageFormat.mm),
              pw.Text(pdfSafe('Certificate No. ${input.coaCertificateNumber}'), style: style(9.5, _muted)),
              pw.SizedBox(height: 10 * PdfPageFormat.mm),
              pw.Container(width: 30 * PdfPageFormat.mm, height: 0.5, color: _gold),
              pw.SizedBox(height: 10 * PdfPageFormat.mm),
              pw.Text('This certifies that the artwork', style: style(10, _muted)),
              pw.SizedBox(height: 8 * PdfPageFormat.mm),
              pw.Text(
                pdfSafe(input.title),
                textAlign: pw.TextAlign.center,
                style: style(20, _ink, font: serifBoldItalic),
              ),
              pw.SizedBox(height: 3 * PdfPageFormat.mm),
              pw.Text(pdfSafe('by ${input.artistName}'), style: style(11, _muted)),
              pw.SizedBox(height: 10 * PdfPageFormat.mm),
              for (final (label, value) in details)
                pw.Padding(
                  padding: pw.EdgeInsets.only(bottom: 2 * PdfPageFormat.mm),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(width: 12 * PdfPageFormat.mm),
                      pw.SizedBox(width: 73 * PdfPageFormat.mm, child: pw.Text(label, style: style(10, _muted))),
                      pw.Expanded(child: pw.Text(pdfSafe(value), style: style(10, _ink))),
                    ],
                  ),
                ),
              pw.SizedBox(height: 4 * PdfPageFormat.mm),
              pw.Text(statement, textAlign: pw.TextAlign.center, style: style(9, _muted)),
              pw.SizedBox(height: 8 * PdfPageFormat.mm),
              pw.SizedBox(
                width: 38 * PdfPageFormat.mm,
                height: 38 * PdfPageFormat.mm,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium),
                  data: url,
                  color: _ink,
                ),
              ),
              pw.SizedBox(height: 4 * PdfPageFormat.mm),
              pw.Text(url, style: style(8.5, _gold)),
              pw.SizedBox(height: 2 * PdfPageFormat.mm),
              pw.Text('Scan to verify authenticity and current ownership', style: style(8.5, _muted)),
              pw.Spacer(),
              pw.Text(
                'Generated $generated - GalleryZone acts as an intermediary; title passes directly from seller to buyer.',
                textAlign: pw.TextAlign.center,
                style: style(7.5, _muted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return doc.save();
}
