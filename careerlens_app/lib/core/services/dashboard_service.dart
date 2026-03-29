import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.profile,
    required this.hasExistingProfile,
    required this.recentJobAnalyses,
    required this.recentCoachingSessions,
  });

  final Map<String, dynamic> profile;
  final bool hasExistingProfile;
  final List<RecentJobAnalysis> recentJobAnalyses;
  final List<RecentCoachingSession> recentCoachingSessions;
}

class RecentJobAnalysis {
  const RecentJobAnalysis({
    required this.id,
    required this.score,
    required this.location,
    required this.preview,
    required this.createdAt,
  });

  final String id;
  final int score;
  final String location;
  final String preview;
  final DateTime? createdAt;
}

class RecentCoachingSession {
  const RecentCoachingSession({
    required this.id,
    required this.location,
    required this.readinessScore,
    required this.sessionSummary,
    required this.startedAt,
    required this.completedAt,
  });

  final String id;
  final String location;
  final int readinessScore;
  final String sessionSummary;
  final DateTime? startedAt;
  final DateTime? completedAt;
}

class DashboardService {
  DashboardService({SupabaseClient? client, ProfileService? profileService})
    : _client = client ?? Supabase.instance.client,
      _profileService = profileService ?? ProfileService(client: client);

  final SupabaseClient _client;
  final ProfileService _profileService;

  Future<DashboardSnapshot> fetchSnapshot() async {
    final profile = await _profileService.fetchCurrentUserProfile();
    final hasExistingProfile = _hasExistingProfileData(profile);

    final recentJobAnalyses = await _fetchRecentJobAnalyses();
    final recentCoachingSessions = await _fetchRecentCoachingSessions();

    return DashboardSnapshot(
      profile: profile,
      hasExistingProfile: hasExistingProfile,
      recentJobAnalyses: recentJobAnalyses,
      recentCoachingSessions: recentCoachingSessions,
    );
  }

  Future<List<RecentJobAnalysis>> _fetchRecentJobAnalyses() async {
    final analysisRows = await _client
        .from('job_analyses')
        .select('id, overall_fit_score, created_at, job_description_id')
        .order('created_at', ascending: false)
        .limit(4);

    final rows = List<Map<String, dynamic>>.from(analysisRows);
    if (rows.isEmpty) {
      return const <RecentJobAnalysis>[];
    }

    final descriptionIds = rows
        .map((row) => row['job_description_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    final descriptions = <String, Map<String, dynamic>>{};
    if (descriptionIds.isNotEmpty) {
      final descriptionRows = await _client
          .from('job_descriptions')
          .select('id, location, raw_text')
          .inFilter('id', descriptionIds);

      for (final row in List<Map<String, dynamic>>.from(descriptionRows)) {
        final id = row['id']?.toString();
        if (id != null) {
          descriptions[id] = row;
        }
      }
    }

    return rows.map((row) {
      final description =
          descriptions[row['job_description_id']?.toString()] ??
          const <String, dynamic>{};
      final rawText = description['raw_text']?.toString() ?? '';
      return RecentJobAnalysis(
        id: row['id']?.toString() ?? '',
        score: row['overall_fit_score'] as int? ?? 0,
        location: description['location']?.toString() ?? '',
        preview: _previewText(rawText),
        createdAt: _parseDateTime(row['created_at']),
      );
    }).toList();
  }

  Future<List<RecentCoachingSession>> _fetchRecentCoachingSessions() async {
    final sessionRows = await _client
        .from('interview_coaching_sessions')
        .select(
          'id, location, current_readiness_score, session_summary, started_at, completed_at',
        )
        .order('started_at', ascending: false)
        .limit(4);

    return List<Map<String, dynamic>>.from(sessionRows).map((row) {
      return RecentCoachingSession(
        id: row['id']?.toString() ?? '',
        location: row['location']?.toString() ?? '',
        readinessScore: row['current_readiness_score'] as int? ?? 0,
        sessionSummary: row['session_summary']?.toString() ?? '',
        startedAt: _parseDateTime(row['started_at']),
        completedAt: _parseDateTime(row['completed_at']),
      );
    }).toList();
  }

  bool _hasExistingProfileData(Map<String, dynamic> profile) {
    final headline = (profile['headline'] as String? ?? '').trim();
    final summary = (profile['summary'] as String? ?? '').trim();
    final skills = profile['skills'];
    final experience = profile['experience'];
    final education = profile['education'];
    final certifications = profile['certifications'];

    final hasListData =
        (skills is List && skills.isNotEmpty) ||
        (experience is List && experience.isNotEmpty) ||
        (education is List && education.isNotEmpty) ||
        (certifications is List && certifications.isNotEmpty);

    return headline.isNotEmpty || summary.isNotEmpty || hasListData;
  }

  DateTime? _parseDateTime(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty) {
      return null;
    }
    return DateTime.tryParse(text);
  }

  static String _previewText(String rawText) {
    final normalized = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 96) {
      return normalized;
    }
    return '${normalized.substring(0, 93)}...';
  }
}
