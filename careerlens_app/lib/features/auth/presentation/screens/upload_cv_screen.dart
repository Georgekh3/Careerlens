import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/cv_processing_service.dart';
import '../../../../core/services/cv_upload_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class UploadCvScreen extends StatefulWidget {
  const UploadCvScreen({super.key});

  @override
  State<UploadCvScreen> createState() => _UploadCvScreenState();
}

class _UploadCvScreenState extends State<UploadCvScreen> {
  final CvUploadService _cvUploadService = CvUploadService();
  final CvProcessingService _cvProcessingService = CvProcessingService();

  PlatformFile? _selectedFile;
  bool _isPicking = false;
  bool _isUploading = false;
  String _statusMessage = 'Your CV analysis status will appear here.';
  String? _errorMessage;

  Future<void> _pickFile() async {
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          _errorMessage = null;
          _statusMessage = 'CV selected and ready to upload.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isPicking = false);
      }
    }
  }

  void _removeSelectedFile() {
    setState(() {
      _selectedFile = null;
      _errorMessage = null;
      _statusMessage = 'Your CV analysis status will appear here.';
    });
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

  Future<void> _uploadCv() async {
    final selectedFile = _selectedFile;
    if (selectedFile == null) {
      return;
    }

    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _errorMessage = 'Supabase is not configured. CV upload is unavailable.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _statusMessage = 'Uploading your CV...';
    });

    try {
      final uploadResult = await _cvUploadService.uploadCv(selectedFile);
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw AuthException('No signed-in user found.');
      }

      setState(() {
        _statusMessage = 'CV uploaded. Processing your profile...';
      });

      await _cvProcessingService.processCv(
        userId: userId,
        cvUploadId: uploadResult.cvUploadId,
        storagePath: uploadResult.storagePath,
        originalFilename: uploadResult.originalFilename,
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'CV uploaded and processed successfully.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV uploaded and processed successfully.')),
      );
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ProfileScreen()));
    } on StorageException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
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
            colors: [Color(0xFFF2F6FF), Color(0xFFEAF1FF)],
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF2D5EBA),
                      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Processing Status',
                        style: TextStyle(
                          color: Color(0xFF1A3E83),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Color(0xFF5B7199),
                          fontSize: 13,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: hasFile && !_isUploading ? _uploadCv : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4EA8),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF9FB6E8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isUploading ? 'Uploading...' : 'Upload CV',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
