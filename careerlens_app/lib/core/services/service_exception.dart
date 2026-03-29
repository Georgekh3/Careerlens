import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceException implements Exception {
  const ServiceException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final String? details;

  @override
  String toString() => message;
}

class ServiceErrorMapper {
  static String toUserMessage(Object error, {required String fallback}) {
    if (error is ServiceException) {
      return error.message;
    }
    if (error is AuthException) {
      return 'Your session has expired. Please sign in again.';
    }
    if (error is StorageException) {
      return error.message.isEmpty
          ? 'Your CV could not be uploaded right now. Please try again.'
          : error.message;
    }
    if (error is PostgrestException) {
      return error.message.isEmpty
          ? 'We could not save your data right now. Please try again.'
          : error.message;
    }
    if (error is http.ClientException) {
      return 'The app could not reach the backend. Check that the server is running and try again.';
    }
    if (error is StateError) {
      return error.message;
    }
    return fallback;
  }

  static ServiceException fromHttpResponse(
    http.Response response, {
    required String defaultMessage,
  }) {
    final statusCode = response.statusCode;
    final details = _extractResponseMessage(response.body);

    if (statusCode == 400) {
      return ServiceException(
        details ?? defaultMessage,
        statusCode: statusCode,
        details: response.body,
      );
    }
    if (statusCode == 401 || statusCode == 403) {
      return ServiceException(
        'Your session is no longer valid. Please sign in again.',
        statusCode: statusCode,
        details: response.body,
      );
    }
    if (statusCode == 404) {
      return ServiceException(
        'The requested service is not available right now.',
        statusCode: statusCode,
        details: response.body,
      );
    }
    if (statusCode == 429) {
      return ServiceException(
        'The AI service is busy right now. Please wait a moment and try again.',
        statusCode: statusCode,
        details: response.body,
      );
    }
    if (statusCode >= 500) {
      return ServiceException(
        'The server ran into a problem while processing your request. Please try again.',
        statusCode: statusCode,
        details: response.body,
      );
    }

    return ServiceException(
      details ?? defaultMessage,
      statusCode: statusCode,
      details: response.body,
    );
  }

  static String? _extractResponseMessage(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final directMessage = decoded['message'];
        if (directMessage is String && directMessage.trim().isNotEmpty) {
          return directMessage.trim();
        }

        final detail = decoded['detail'];
        if (detail is String && detail.trim().isNotEmpty) {
          return detail.trim();
        }

        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final nestedMessage = error['message'];
          if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
            return nestedMessage.trim();
          }
        }
      }
    } catch (_) {
      // Fall through to plain text handling.
    }

    return trimmed.length > 180 ? '${trimmed.substring(0, 177)}...' : trimmed;
  }
}
