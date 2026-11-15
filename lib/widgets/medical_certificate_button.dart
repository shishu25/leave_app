import 'package:flutter/material.dart';
import '../models/leave_models.dart';
import '../utils/certificate_stub.dart'
    if (dart.library.html) '../utils/certificate_web.dart';

class MedicalCertificateButton extends StatelessWidget {
  final LeaveApplication application;
  const MedicalCertificateButton({super.key, required this.application});

  void _view(BuildContext context) {
    final uri = Uri.parse(application.medicalCertificateData!);
    if (uri.data!.mimeType == 'application/pdf') {
      if (!openCertificatePdf(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Open this application in a web browser to view PDF certificates.')));
      }
      return;
    }
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(application.medicalCertificateName!),
              content: SizedBox(
                  width: 700,
                  height: 500,
                  child: InteractiveViewer(
                      child: Image.memory(uri.data!.contentAsBytes(),
                          fit: BoxFit.contain))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (application.medicalCertificateData == null) {
      return const Text('Medical certificate: not attached');
    }
    return TextButton.icon(
        onPressed: () => _view(context),
        icon: const Icon(Icons.visibility_outlined),
        label: Text(
            'View medical certificate: ${application.medicalCertificateName}'));
  }
}
