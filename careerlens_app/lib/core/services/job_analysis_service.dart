import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class JobAnalysisResult {
  const JobAnalysisResult({
    required this.jobDescriptionId,
    required this.jobAnalysisId,
    required this.message,
    required this.overallFitScore,
    required this.skillsMatchScore,
    required this.experienceMatchScore,
    required this.educationCertScore,
    required this.domainRelevanceScore,
    required this.matchedSkills,
    required this.missingSkills,
    required this.missingRequirements,
    required this.recommendations,
    required this.overallSummary,
    required this.strengths,
    required this.risks,
  });

  final String jobDescriptionId;
  final String jobAnalysisId;
  final String message;
  final int overallFitScore;
  final int skillsMatchScore;
  final int experienceMatchScore;
  final int educationCertScore;
  final int domainRelevanceScore;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> missingRequirements;
  final List<String> recommendations;
  final String overallSummary;
  final List<String> strengths;
  final List<String> risks;

  factory JobAnalysisResult.fromJson(Map<String, dynamic> json) {
    final analysis = Map<String, dynamic>.from(
      json['analysis'] as Map? ?? const <String, dynamic>{},
    );
    final scoreExplanation = Map<String, dynamic>.from(
      analysis['score_explanation'] as Map? ?? const <String, dynamic>{},
    );

    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return <String>[];
    }

    return JobAnalysisResult(
      jobDescriptionId: json['job_description_id'] as String? ?? '',
      jobAnalysisId: json['job_analysis_id'] as String? ?? '',
      message: json['message'] as String? ?? 'Job analysis completed.',
      overallFitScore: analysis['overall_fit_score'] as int? ?? 0,
      skillsMatchScore: analysis['skills_match_score'] as int? ?? 0,
      experienceMatchScore: analysis['experience_match_score'] as int? ?? 0,
      educationCertScore: analysis['education_cert_score'] as int? ?? 0,
      domainRelevanceScore: analysis['domain_relevance_score'] as int? ?? 0,
      matchedSkills: stringList(analysis['matched_skills']),
      missingSkills: stringList(analysis['missing_skills']),
      missingRequirements: stringList(analysis['missing_requirements']),
      recommendations: stringList(analysis['recommendations']),
      overallSummary: scoreExplanation['overall_summary'] as String? ?? '',
      strengths: stringList(scoreExplanation['strengths']),
      risks: stringList(scoreExplanation['risks']),
    );
  }
}

class JobAnalysisService {
  Future<JobAnalysisResult> analyzeJob({
    required String rawText,
    String title = '',
    String company = '',
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
      Uri.parse('${SupabaseConfig.apiBaseUrl}/job/analyze'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'raw_text': rawText,
        'title': title,
        'company': company,
        'location': location,
        'source': 'pasted',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Job analysis failed with status ${response.statusCode}: ${response.body}',
      );
    }

    return JobAnalysisResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
