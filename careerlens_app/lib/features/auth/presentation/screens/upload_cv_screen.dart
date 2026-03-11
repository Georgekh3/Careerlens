import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class UploadCvScreen extends StatefulWidget {
  const UploadCvScreen({super.key});

  @override
  State<UploadCvScreen> createState() => _UploadCvScreenState();
}

class _UploadCvScreenState extends State<UploadCvScreen> {
  PlatformFile? _selectedFile;
  bool _isPicking = false;

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        // Replaces any previously selected file, enforcing one-CV selection.
        setState(() => _selectedFile = result.files.first);
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _removeSelectedFile() {
    setState(() => _selectedFile = null);
  }

  Map<String, dynamic> _parsedProfileFromCv() {
    // TODO: Replace this with parsed JSON returned by your backend after CV upload.
    return <String, dynamic>{};
  }

  String _formatSize(int? bytes) {
    if (bytes == null) {
      return '';
    }
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = _selectedFile != null;
    final fileName = _selectedFile?.name ?? 'No file selected yet.';
    final fileSize = hasFile ? _formatSize(_selectedFile!.size) : '';

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF2F6FF),
              Color(0xFFEAF1FF),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: const Color(0xFF1E4EA8),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Upload CV',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF123A87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD8E4FF)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: Color(0xFF1E4EA8),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload your CV to get started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF163B84),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Supported formats: PDF, DOC, DOCX',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5E7299),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isPicking ? null : _pickFile,
                        icon: _isPicking
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.upload_file_rounded),
                        label: Text(
                          _isPicking
                              ? 'Choosing...'
                              : hasFile
                                  ? 'Choose Another CV'
                                  : 'Choose File',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          foregroundColor: const Color(0xFF1E4EA8),
                          side: const BorderSide(color: Color(0xFFBFD1FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (hasFile) ...[
                        const SizedBox(height: 10),
                        TextButton.icon(
                          onPressed: _removeSelectedFile,
                          icon: const Icon(Icons.delete_outline_rounded),
                          label: const Text('Remove CV'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFB42318),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8E4FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF2D5EBA)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          hasFile ? '$fileName ($fileSize)' : fileName,
                          style: const TextStyle(
                            color: Color(0xFF365480),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD8E4FF)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Processing Status',
                        style: TextStyle(
                          color: Color(0xFF1A3E83),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your CV analysis status will appear here.',
                        style: TextStyle(
                          color: Color(0xFF5B7199),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: hasFile
                        ? () {
                            final parsedProfile = _parsedProfileFromCv();
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ProfileScreen(profile: parsedProfile),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4EA8),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF9FB6E8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Upload CV',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
