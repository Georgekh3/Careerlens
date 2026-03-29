import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class InterviewQuestion {
  const InterviewQuestion({
    required this.question,
    required this.whyItMatters,
    required this.suggestedTalkingPoints,
  });

  final String question;
  final String whyItMatters;
  final List<String> suggestedTalkingPoints;

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return <String>[];
    }

    return InterviewQuestion(
      question: json['question'] as String? ?? '',
      whyItMatters: json['why_it_matters'] as String? ?? '',
      suggestedTalkingPoints: stringList(json['suggested_talking_points']),
    );
  }
}

class InterviewPreparationResult {
  const InterviewPreparationResult({
    required this.message,
    required this.interviewReadinessSummary,
    required this.personalPitch,
    required this.focusAreas,
    required this.likelyTopics,
    required this.tailoredQuestions,
    required this.finalTips,
  });

  final String message;
  final String interviewReadinessSummary;
  final String personalPitch;
  final List<String> focusAreas;
  final List<String> likelyTopics;
  final List<InterviewQuestion> tailoredQuestions;
  final List<String> finalTips;

  factory InterviewPreparationResult.fromJson(Map<String, dynamic> json) {
    final preparation = Map<String, dynamic>.from(
      json['preparation'] as Map? ?? const <String, dynamic>{},
    );

    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return <String>[];
    }

    List<InterviewQuestion> questionList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => InterviewQuestion.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return <InterviewQuestion>[];
    }

    return InterviewPreparationResult(
      message:
          json['message'] as String? ?? 'Interview preparation generated.',
      interviewReadinessSummary:
          preparation['interview_readiness_summary'] as String? ?? '',
      personalPitch: preparation['personal_pitch'] as String? ?? '',
      focusAreas: stringList(preparation['focus_areas']),
      likelyTopics: stringList(preparation['likely_topics']),
      tailoredQuestions: questionList(preparation['tailored_questions']),
      finalTips: stringList(preparation['final_tips']),
    );
  }
}

class InterviewPreparationService {
  Future<InterviewPreparationResult> prepareInterview({
    required String rawText,
    String location = '',
  }) async {
    if (SupabaseConfig.apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL is not configured.');
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('No signed-in user found.');
    }

    final response = await http.post(
      Uri.parse('${SupabaseConfig.apiBaseUrl}/interview/prepare'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'raw_text': rawText,
        'title': '',
        'company': '',
        'location': location,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Interview preparation failed with status ${response.statusCode}: ${response.body}',
      );
    }

    return InterviewPreparationResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
