import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/leave_models.dart';
import '../theme/app_theme.dart';
import '../utils/leave_data_service.dart';

/// "Request New Leave" form.
/// On mobile this fills the screen; on tablet/desktop it renders as a
/// centered card over a dimmed ground, matching the design mockup's modal.
class RequestLeaveScreen extends StatefulWidget {
  const RequestLeaveScreen({super.key});

  @override
  State<RequestLeaveScreen> createState() => _RequestLeaveScreenState();
}

class _RequestLeaveScreenState extends State<RequestLeaveScreen> {
  LeaveType _leaveType = LeaveType.general;
  DateTime _startDate = DateTime.now().add(const Duration(days: 12));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  final TextEditingController _reasonController = TextEditingController();
  String? _signatureFileName;
  String? _manualDocumentName;
  String? _medicalCertificateName;
  String? _medicalCertificateData;
  DateTime _applicationDate = DateTime.now();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _durationInDays => _endDate.difference(_startDate).inDays + 1;

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickSignature() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _signatureFileName = result.files.first.name);
    }
  }

  Future<void> _pickManualDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _manualDocumentName = result.files.first.name);
    }
  }

  Future<void> _pickMedicalCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (!mounted || result == null) return;
      final file = result.files.single;
      final bytes = file.bytes;
      final ext = file.extension?.toLowerCase();
      if (bytes == null ||
          bytes.isEmpty ||
          bytes.length > 10 * 1024 * 1024 ||
          !['pdf', 'jpg', 'jpeg', 'png'].contains(ext)) {
        throw const FormatException(
            'Choose a PDF, JPG or PNG certificate up to 10 MB.');
      }
      final mime = ext == 'pdf'
          ? 'application/pdf'
          : ext == 'png'
              ? 'image/png'
              : 'image/jpeg';
      setState(() {
        _medicalCertificateName = file.name;
        _medicalCertificateData = 'data:$mime;base64,${base64Encode(bytes)}';
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Unable to attach certificate. Choose a PDF, JPG or PNG up to 10 MB.')));
      }
    }
  }

  Future<void> _generateAndSubmit() async {
    if (_reasonController.text
            .trim()
            .split(RegExp(r'\s+'))
            .where((word) => RegExp(r'[A-Za-z0-9\u0980-\u09FF]').hasMatch(word))
            .length <
        20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please describe the reason for leave in at least 20 words.')),
      );
      return;
    }

    if (_leaveType == LeaveType.medical && _medicalCertificateData == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Please attach a medical certificate for medical leave.')));
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date must follow start date.')));
      return;
    }
    final confirmed = await _showConfirmDialog();
    if (!mounted || confirmed != true) return;

    setState(() => _submitting = true);
    try {
      final application =
          await LeaveDataService.instance.submitLeaveApplication(
        type: _leaveType,
        startDate: _startDate,
        endDate: _endDate,
        reason: _reasonController.text.trim(),
        documentName: _manualDocumentName,
        medicalCertificateName:
            _leaveType == LeaveType.medical ? _medicalCertificateName : null,
        medicalCertificateData:
            _leaveType == LeaveType.medical ? _medicalCertificateData : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(application);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to submit application. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.lg)),
        title: const Text('Submit Leave Application?'),
        content: const Text(
          'Review your application once more. Choose Edit Application to make changes, '
          'or confirm to send it to your administrator for review.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Edit Application'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = screenSizeOf(context) == ScreenSize.mobile;
    final formCard = _FormCard(
      isMobile: isMobile,
      leaveType: _leaveType,
      onLeaveTypeChanged: (t) => setState(() => _leaveType = t),
      startDate: _startDate,
      endDate: _endDate,
      durationInDays: _durationInDays,
      onPickStart: () => _pickDate(isStart: true),
      onPickEnd: () => _pickDate(isStart: false),
      reasonController: _reasonController,
      medicalCertificateName: _medicalCertificateName,
      onPickMedicalCertificate: _pickMedicalCertificate,
      signatureFileName: _signatureFileName,
      onPickSignature: _pickSignature,
      applicationDate: _applicationDate,
      onPickApplicationDate: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _applicationDate,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now().add(const Duration(days: 30)),
        );
        if (picked != null) setState(() => _applicationDate = picked);
      },
      manualDocumentName: _manualDocumentName,
      onPickManualDocument: _pickManualDocument,
      submitting: _submitting,
      onCancel: () => Navigator.of(context).pop(),
      onSubmit: _generateAndSubmit,
    );

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          foregroundColor: AppColors.textPrimary,
          title: const Text('Request New Leave',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        ),
        body: SingleChildScrollView(child: formCard),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.modalGround,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Container(
            width: 860,
            constraints: const BoxConstraints(maxWidth: 860),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.14),
                  blurRadius: 60,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: formCard,
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final bool isMobile;
  final LeaveType leaveType;
  final ValueChanged<LeaveType> onLeaveTypeChanged;
  final DateTime startDate;
  final DateTime endDate;
  final int durationInDays;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final TextEditingController reasonController;
  final String? medicalCertificateName;
  final VoidCallback onPickMedicalCertificate;
  final String? signatureFileName;
  final VoidCallback onPickSignature;
  final DateTime applicationDate;
  final VoidCallback onPickApplicationDate;
  final String? manualDocumentName;
  final VoidCallback onPickManualDocument;
  final bool submitting;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const _FormCard({
    required this.isMobile,
    required this.leaveType,
    required this.onLeaveTypeChanged,
    required this.startDate,
    required this.endDate,
    required this.durationInDays,
    required this.onPickStart,
    required this.onPickEnd,
    required this.reasonController,
    required this.medicalCertificateName,
    required this.onPickMedicalCertificate,
    required this.signatureFileName,
    required this.onPickSignature,
    required this.applicationDate,
    required this.onPickApplicationDate,
    required this.manualDocumentName,
    required this.onPickManualDocument,
    required this.submitting,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Request New Leave',
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    SizedBox(height: 2),
                    Text(
                        'Fill in the details below — a formal application will be generated automatically.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
                IconButton(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.ground,
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: EdgeInsets.all(isMobile ? 18 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Leave Type',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  _LeaveTypeOption(
                    label: 'General Leave',
                    selected: leaveType == LeaveType.general,
                    onTap: () => onLeaveTypeChanged(LeaveType.general),
                    trailingMargin: isMobile ? 0 : 14,
                  ),
                  if (isMobile) const SizedBox(height: 10),
                  _LeaveTypeOption(
                    label: 'Medical / Sick Leave',
                    selected: leaveType == LeaveType.medical,
                    onTap: () => onLeaveTypeChanged(LeaveType.medical),
                    trailingMargin: 0,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              if (leaveType == LeaveType.medical) ...[
                const Text('Medical certificate (required)'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                    onPressed: submitting ? null : onPickMedicalCertificate,
                    icon: const Icon(Icons.attach_file),
                    label: Text(medicalCertificateName ??
                        'Attach certificate (PDF, JPG, PNG; max 10 MB)')),
                const SizedBox(height: 20),
              ],
              const Text('Leave Duration',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.stretch
                    : CrossAxisAlignment.end,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: _DateField(
                        label: 'Start Date',
                        date: startDate,
                        onTap: onPickStart,
                        formatter: dateFmt),
                  ),
                  SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 10 : 0),
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: _DateField(
                        label: 'End Date',
                        date: endDate,
                        onTap: onPickEnd,
                        formatter: dateFmt),
                  ),
                  SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 10 : 0),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                        color: AppColors.accentSoft,
                        borderRadius: BorderRadius.circular(9)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TOTAL',
                            style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accent,
                                letterSpacing: 0.3)),
                        Text('$durationInDays days',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accentDark)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text('Reason for Leave',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe your situation in at least 20 words.',
                  helperText: 'Minimum 20 words required.',
                ),
              ),
              const SizedBox(height: 26),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: _SignatureUpload(
                        fileName: signatureFileName, onPick: onPickSignature),
                  ),
                  SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: _DateField(
                      label: 'Application Date',
                      date: applicationDate,
                      onTap: onPickApplicationDate,
                      formatter: dateFmt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.ground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.description_outlined,
                          size: 17, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                              'Formal application will be generated as an editable .docx',
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 2),
                          Text(
                            manualDocumentName == null
                                ? 'Review and edit before submitting — or upload your own manual application instead.'
                                : 'Manual document attached: $manualDocumentName',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: onPickManualDocument,
                      child: const Text('Upload manually →',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 18 : 32, vertical: 18),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.borderInput),
                ),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: submitting ? null : onSubmit,
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.ground),
                      )
                    : const Text('Generate Application →'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeaveTypeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double trailingMargin;

  const _LeaveTypeOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.trailingMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      flex: screenSizeOf(context) == ScreenSize.mobile ? 0 : 1,
      child: Padding(
        padding: EdgeInsets.only(right: trailingMargin),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primarySoft : AppColors.surface,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: selected ? AppColors.primary : AppColors.border,
                  width: selected ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? AppColors.primary : AppColors.textMuted),
                ),
                Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final DateFormat formatter;

  const _DateField(
      {required this.label,
      required this.date,
      required this.onTap,
      required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: AppColors.borderInput),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatter.format(date),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textPrimary)),
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignatureUpload extends StatelessWidget {
  final String? fileName;
  final VoidCallback onPick;

  const _SignatureUpload({required this.fileName, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Signature',
            style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onPick,
          borderRadius: BorderRadius.circular(11),
          child: Container(
            padding: const EdgeInsets.all(18),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: AppColors.borderDashed,
                  width: 1.5,
                  style: BorderStyle.solid),
            ),
            child: Column(
              children: [
                Icon(
                  fileName == null
                      ? Icons.upload_outlined
                      : Icons.check_circle_outline,
                  size: 22,
                  color: fileName == null
                      ? AppColors.textMuted
                      : AppColors.success,
                ),
                const SizedBox(height: 6),
                Text(
                  fileName ?? 'Upload signature image',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: fileName == null
                          ? AppColors.textMuted
                          : AppColors.success),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
