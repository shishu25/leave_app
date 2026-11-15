// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool openCertificatePdf(Uri data) {
  final content = data.data!;
  final blob = html.Blob([content.contentAsBytes()], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');
  // Keep the URL alive while the browser PDF viewer reads it.
  Future<void>.delayed(
      const Duration(minutes: 5), () => html.Url.revokeObjectUrl(url));
  return true;
}
