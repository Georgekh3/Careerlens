import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/supabase_config.dart';

class CvProcessingService {
  Future<void> processCv({
    required String userId,
    required String cvUploadId,
    required String storagePath,
    required String originalFilename,
  }) async {
    if (SupabaseConfig.apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL is not configured.');
    }

    final response = await http.post(
      Uri.parse('${SupabaseConfig.apiBaseUrl}/cv/process'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'cv_upload_id': cvUploadId,
        'storage_path': storagePath,
        'original_filename': originalFilename,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'CV processing failed with status ${response.statusCode}: ${response.body}',
      );
    }
  }
}
