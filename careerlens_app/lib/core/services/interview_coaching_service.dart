import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class CoachingQuestion {
  const CoachingQuestion({
    required this.question,
    required this.category,
    required this.intent,
  });

  final String question;
  final String category;
  final String intent;

  factory CoachingQuestion.fromJson(Map<String, dynamic> json) {
    return CoachingQuestion(
      question: json['question'] as String? ?? '',
      category: json['category'] as String? ?? '',
      intent: json['intent'] as String? ?? '',
    );
  }
}

class TurnEvaluationScores {
  const TurnEvaluationScores({
    required this.relevance,
    required this.clarity,
    required this.technicalDepth,
    required this.communicationQuality,
    required this.logicalStructure,
  });

  final int relevance;
  final int clarity;
  final int technicalDepth;
  final int communicationQuality;
  final int logicalStructure;

  factory TurnEvaluationScores.fromJson(Map<String, dynamic> json) {
    return TurnEvaluationScores(
      relevance: json['relevance'] as int? ?? 0,
      clarity: json['clarity'] as int? ?? 0,
      technicalDepth: json['technical_depth'] as int? ?? 0,
      communicationQuality: json['communication_quality'] as int? ?? 0,
      logicalStructure: json['logical_structure'] as int? ?? 0,
    );
  }
}

class TurnEvaluation {
  const TurnEvaluation({
    required this.structuredFeedback,
    required this.improvementSuggestions,
    required this.performanceRating,
    required this.readinessScore,
    required this.scores,
  });

  final String structuredFeedback;
  final List<String> improvementSuggestions;
  final String performanceRating;
  final int readinessScore;
  final TurnEvaluationScores scores;

  factory TurnEvaluation.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return <String>[];
    }

    return TurnEvaluation(
      structuredFeedback: json['structured_feedback'] as String? ?? '',
      improvementSuggestions: stringList(json['improvement_suggestions']),
      performanceRating: json['performance_rating'] as String? ?? '',
      readinessScore: json['readiness_score'] as int? ?? 0,
      scores: TurnEvaluationScores.fromJson(
        Map<String, dynamic>.from(json['scores'] as Map? ?? const <String, dynamic>{}),
      ),
    );
  }
}

class InterviewTurn {
  const InterviewTurn({
    required this.turnId,
    required this.turnNo,
    required this.question,
    required this.answer,
    required this.evaluation,
  });

  final String turnId;
  final int turnNo;
  final CoachingQuestion question;
  final String answer;
  final TurnEvaluation? evaluation;

  factory InterviewTurn.fromJson(Map<String, dynamic> json) {
    final evaluationJson = json['evaluation'];
    return InterviewTurn(
      turnId: json['turn_id'] as String? ?? '',
      turnNo: json['turn_no'] as int? ?? 0,
      question: CoachingQuestion.fromJson(
        Map<String, dynamic>.from(json['question'] as Map? ?? const <String, dynamic>{}),
      ),
      answer: json['answer'] as String? ?? '',
      evaluation: evaluationJson is Map
          ? TurnEvaluation.fromJson(Map<String, dynamic>.from(evaluationJson))
          : null,
    );
  }
}

class InterviewCoachingSession {
  const InterviewCoachingSession({
    required this.sessionId,
    required this.readinessScore,
    required this.performanceTrend,
    required this.sessionSummary,
    required this.focusAreas,
    required this.currentQuestion,
    required this.turns,
    required this.isSessionComplete,
  });

  final String sessionId;
  final int readinessScore;
  final List<int> performanceTrend;
  final String sessionSummary;
  final List<String> focusAreas;
  final CoachingQuestion? currentQuestion;
  final List<InterviewTurn> turns;
  final bool isSessionComplete;

  factory InterviewCoachingSession.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return <String>[];
    }

    List<int> intList(dynamic value) {
      if (value is List) {
        return value.map((item) => int.tryParse(item.toString()) ?? 0).toList();
      }
      return <int>[];
    }

    List<InterviewTurn> turnList(dynamic value) {
      if (value is List) {
        return value
            .whereType<Map>()
            .map((item) => InterviewTurn.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return <InterviewTurn>[];
    }

    final currentQuestionJson = json['current_question'];
    return InterviewCoachingSession(
      sessionId: json['session_id'] as String? ?? '',
      readinessScore: json['readiness_score'] as int? ?? 0,
      performanceTrend: intList(json['performance_trend']),
      sessionSummary: json['session_summary'] as String? ?? '',
      focusAreas: stringList(json['focus_areas']),
      currentQuestion: currentQuestionJson is Map
          ? CoachingQuestion.fromJson(Map<String, dynamic>.from(currentQuestionJson))
          : null,
      turns: turnList(json['turns']),
      isSessionComplete: json['is_session_complete'] as bool? ?? false,
    );
  }
}

class InterviewCoachingResponse {
  const InterviewCoachingResponse({
    required this.message,
    required this.session,
  });

  final String message;
  final InterviewCoachingSession session;

  factory InterviewCoachingResponse.fromJson(Map<String, dynamic> json) {
    return InterviewCoachingResponse(
      message: json['message'] as String? ?? '',
      session: InterviewCoachingSession.fromJson(
        Map<String, dynamic>.from(json['session'] as Map? ?? const <String, dynamic>{}),
      ),
    );
  }
}

class InterviewCoachingService {
  Future<InterviewCoachingResponse> startSession({
    required String rawText,
    String location = '',
  }) async {
    final userId = _currentUserId();
    final response = await http.post(
      Uri.parse('${SupabaseConfig.apiBaseUrl}/interview/session/start'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'raw_text': rawText,
        'location': location,
      }),
    );

    return _parseResponse(
      response,
      errorPrefix: 'Interview coaching start failed',
    );
  }

  Future<InterviewCoachingResponse> answerTurn({
    required String sessionId,
    required String answer,
  }) async {
    final userId = _currentUserId();
    final response = await http.post(
      Uri.parse('${SupabaseConfig.apiBaseUrl}/interview/session/answer'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'session_id': sessionId,
        'answer': answer,
      }),
    );

    return _parseResponse(
      response,
      errorPrefix: 'Interview coaching answer failed',
    );
  }

  String _currentUserId() {
    if (SupabaseConfig.apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL is not configured.');
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('No signed-in user found.');
    }
    return userId;
  }

  InterviewCoachingResponse _parseResponse(
    http.Response response, {
    required String errorPrefix,
  }) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('$errorPrefix with status ${response.statusCode}: ${response.body}');
    }

    return InterviewCoachingResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}
