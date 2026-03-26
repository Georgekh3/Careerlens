import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CvUploadResult {
  const CvUploadResult({
    required this.cvUploadId,
    required this.storagePath,
    required this.originalFilename,
  });

  final String cvUploadId;
  final String storagePath;
  final String originalFilename;
}

class CvUploadService {
  CvUploadService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<CvUploadResult> uploadCv(PlatformFile file) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('No signed-in user found.');
    }

    final bytes = file.bytes;
    if (bytes == null) {
      throw StateError('The selected file could not be read.');
    }

    final extension = (file.extension ?? '').trim().toLowerCase();
    final contentType = _contentTypeFor(extension);
    final storagePath =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}_${_sanitizeFileName(file.name)}';

    await _client.storage
        .from('cvs')
        .uploadBinary(
          storagePath,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );

    final insertedRow =
        await _client
            .from('cv_uploads')
            .insert({
      'user_id': user.id,
      'storage_bucket': 'cvs',
      'storage_path': storagePath,
      'original_filename': file.name,
      'mime_type': contentType,
      'file_size_bytes': file.size,
      'extraction_status': 'uploaded',
    })
            .select('id')
            .single();

    return CvUploadResult(
      cvUploadId: insertedRow['id'] as String,
      storagePath: storagePath,
      originalFilename: file.name,
    );
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        throw StateError('Unsupported CV file type.');
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}
