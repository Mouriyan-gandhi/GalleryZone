import 'config.dart';

/// The public verification URL an artwork's QR code (and its NFC tag) resolves
/// to. Built from [AppConfig.siteUrl], never from where the app happens to be
/// running: a code printed from a dev build must still point at the real site.
///
/// This is the one place the link is made, so the QR on screen, the QR in the
/// certificate PDF and anything written to a tag cannot drift apart.
String verifyUrlFor(String artworkId) {
  final origin = AppConfig.siteUrl.replaceFirst(RegExp(r'/+$'), '');
  return '$origin/verify/${Uri.encodeComponent(artworkId)}';
}
