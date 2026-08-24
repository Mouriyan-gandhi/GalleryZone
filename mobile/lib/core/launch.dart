import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// The public site. The legal documents and the FAQ are native screens now
/// (see `features/legal/`); what still links out is the marketing copy —
/// the landing page, About, Contact and the artist survey.
const galleryZoneSite = 'https://www.galleryzone.art';

/// The app's public contact points, as the web's support pages show them.
const galleryZoneEmail = 'galleryzone@zohomail.in';
const galleryZonePhone = '+919492953627';

/// Opens [url] outside the app.
///
/// Every external tap in the app goes through here so the failure path is
/// handled once: a device with no browser, no mail client, or no dialer
/// gets a message instead of a tap that appears to do nothing. Android also
/// needs the matching `<intent>` entries in `AndroidManifest.xml`'s
/// `<queries>` block, or these fail silently on Android 11+.
Future<void> openExternal(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  // `launchUrl` reports "nothing could handle this" either by returning false
  // or by throwing, depending on the platform — both are the same outcome
  // here.
  var opened = false;
  try {
    opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (opened) return;
  messenger.showSnackBar(SnackBar(content: Text("Couldn't open $url")));
}
