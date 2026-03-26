import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileService {
  ProfileService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<Map<String, dynamic>> fetchCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('No signed-in user found.');
    }

    final row = await _client
        .from('profiles')
        .select('email, full_name, avatar_url, authoritative_profile')
        .eq('id', user.id)
        .single();

    return _rowToEditableProfile(Map<String, dynamic>.from(row));
  }

  Future<Map<String, dynamic>> saveCurrentUserProfile(
    Map<String, dynamic> profile,
  ) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw AuthException('No signed-in user found.');
    }

    final existingRow = await _client
        .from('profiles')
        .select('authoritative_profile')
        .eq('id', user.id)
        .single();

    final currentAuthoritative = _asMap(existingRow['authoritative_profile']);
    final updatedAuthoritative = _buildAuthoritativeProfile(
      currentAuthoritative: currentAuthoritative,
      profile: profile,
    );

    await _client
        .from('profiles')
        .update({
          'email': (profile['email'] as String? ?? user.email ?? '')
              .trim()
              .toLowerCase(),
          'full_name': (profile['full_name'] as String? ?? '').trim(),
          'authoritative_profile': updatedAuthoritative,
        })
        .eq('id', user.id);

    return fetchCurrentUserProfile();
  }

  Map<String, dynamic> _rowToEditableProfile(Map<String, dynamic> row) {
    final authoritative = _asMap(row['authoritative_profile']);
    final basics = _asMap(authoritative['basics']);

    return <String, dynamic>{
      'full_name': row['full_name'] ?? '',
      'email': row['email'] ?? '',
      'avatar_url': row['avatar_url'],
      'headline': basics['headline'] ?? '',
      'summary': basics['summary'] ?? '',
      'skills': _extractSkillNames(authoritative['skills']),
      'experience': _asMapList(authoritative['experience']),
      'education': _asMapList(authoritative['education']),
      'certifications': _asMapList(authoritative['certifications']),
    };
  }

  Map<String, dynamic> _buildAuthoritativeProfile({
    required Map<String, dynamic> currentAuthoritative,
    required Map<String, dynamic> profile,
  }) {
    final basics = _asMap(currentAuthoritative['basics']);
    basics['headline'] = (profile['headline'] as String? ?? '').trim();
    basics['summary'] = (profile['summary'] as String? ?? '').trim();

    return <String, dynamic>{
      ...currentAuthoritative,
      'basics': basics,
      'skills': _toStructuredSkills(profile['skills']),
      'experience': _asMapList(profile['experience']),
      'education': _asMapList(profile['education']),
      'certifications': _asMapList(profile['certifications']),
    };
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _extractSkillNames(dynamic value) {
    if (value is! List) {
      return <String>[];
    }

    return value
        .map((item) {
          if (item is Map) {
            return item['name']?.toString().trim() ?? '';
          }
          return item.toString().trim();
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Map<String, dynamic>> _toStructuredSkills(dynamic value) {
    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .map((item) => <String, dynamic>{'name': item})
        .toList();
  }
}
