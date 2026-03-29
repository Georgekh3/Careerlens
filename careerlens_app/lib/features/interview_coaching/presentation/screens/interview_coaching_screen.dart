import 'package:flutter/material.dart';

import '../../../../core/services/interview_coaching_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class InterviewCoachingScreen extends StatefulWidget {
  const InterviewCoachingScreen({
    super.key,
    required this.initialLocation,
    required this.initialJobDescription,
  });

  final String initialLocation;
  final String initialJobDescription;

  @override
  State<InterviewCoachingScreen> createState() => _InterviewCoachingScreenState();
}

class _InterviewCoachingScreenState extends State<InterviewCoachingScreen> {
  final InterviewCoachingService _service = InterviewCoachingService();
  final TextEditingController _answerController = TextEditingController();

  bool _isStarting = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  InterviewCoachingSession? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startSession();
      }
    });
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    if (widget.initialJobDescription.trim().length < 20) {
      setState(() {
        _errorMessage = 'The selected job description is too short for interview coaching.';
      });
      return;
    }

    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.startSession(
        rawText: widget.initialJobDescription.trim(),
        location: widget.initialLocation.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = response.session;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Future<void> _submitAnswer() async {
    final session = _session;
    if (session == null || session.currentQuestion == null) {
      return;
    }

    final answer = _answerController.text.trim();
    if (answer.length < 5) {
      setState(() => _errorMessage = 'Write a fuller answer before submitting.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.answerTurn(
        sessionId: session.sessionId,
        answer: answer,
      );
      if (!mounted) {
        return;
      }
      _answerController.clear();
      setState(() {
        _session = response.session;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('AI Interview Coaching'),
        backgroundColor: const Color(0xFF1E4EA8),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
              );
            },
            child: const Text(
              'Profile',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionCard(
              title: 'Session Context',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaLine(label: 'Location', value: widget.initialLocation),
                  const SizedBox(height: 8),
                  _MetaLine(
                    label: 'Mode',
                    value: 'AI-generated mock interview with live scoring',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isStarting)
              const _SectionCard(
                title: 'Starting Session',
                child: Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Generating your first tailored interview question and readiness baseline.',
                        style: TextStyle(
                          color: Color(0xFF38537E),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorMessage != null)
              _SectionCard(
                title: 'Status',
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB42318),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (session != null) ...[
              _SessionSummaryCard(session: session),
              const SizedBox(height: 12),
              if (session.turns.isNotEmpty)
                _TurnsCard(turns: session.turns),
              if (session.currentQuestion != null && !session.isSessionComplete) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Current Question',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.currentQuestion!.question,
                        style: const TextStyle(
                          color: Color(0xFF173D8A),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _TagChip(text: session.currentQuestion!.category),
                          _TagChip(text: session.currentQuestion!.intent),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _answerController,
                        minLines: 5,
                        maxLines: 8,
                        decoration: InputDecoration(
                          hintText: 'Write your answer here...',
                          filled: true,
                          fillColor: const Color(0xFFF9FBFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD5E2FF)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD5E2FF)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF1E4EA8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _submitAnswer,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                          label: Text(
                            _isSubmitting ? 'Evaluating...' : 'Submit Answer',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E4EA8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (session.isSessionComplete) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Session Complete',
                  child: Text(
                    session.sessionSummary.isEmpty
                        ? 'This coaching session is complete.'
                        : session.sessionSummary,
                    style: const TextStyle(
                      color: Color(0xFF38537E),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionSummaryCard extends StatelessWidget {
  const _SessionSummaryCard({required this.session});

  final InterviewCoachingSession session;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Readiness Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${session.readinessScore}/100',
            style: const TextStyle(
              color: Color(0xFF173D8A),
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            session.sessionSummary,
            style: const TextStyle(
              color: Color(0xFF38537E),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          if (session.focusAreas.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Focus Areas',
              style: TextStyle(
                color: Color(0xFF173D8A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.focusAreas.map((item) => _TagChip(text: item)).toList(),
            ),
          ],
          if (session.performanceTrend.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Readiness Progression',
              style: TextStyle(
                color: Color(0xFF173D8A),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: session.performanceTrend
                  .asMap()
                  .entries
                  .map((entry) => _TagChip(text: 'T${entry.key + 1}: ${entry.value}'))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TurnsCard extends StatelessWidget {
  const _TurnsCard({required this.turns});

  final List<InterviewTurn> turns;

  @override
  Widget build(BuildContext context) {
    final answeredTurns = turns.where((turn) => turn.answer.trim().isNotEmpty).toList();
    if (answeredTurns.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'Session Feedback',
      child: Column(
        children: answeredTurns
            .map(
              (turn) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TurnCard(turn: turn),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TurnCard extends StatelessWidget {
  const _TurnCard({required this.turn});

  final InterviewTurn turn;

  @override
  Widget build(BuildContext context) {
    final evaluation = turn.evaluation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Turn ${turn.turnNo}',
          style: const TextStyle(
            color: Color(0xFF173D8A),
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          turn.question.question,
          style: const TextStyle(
            color: Color(0xFF173D8A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          turn.answer,
          style: const TextStyle(
            color: Color(0xFF38537E),
            fontSize: 13,
            height: 1.45,
          ),
        ),
        if (evaluation != null) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TagChip(text: evaluation.performanceRating),
              _TagChip(text: 'Readiness ${evaluation.readinessScore}/100'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            evaluation.structuredFeedback,
            style: const TextStyle(
              color: Color(0xFF38537E),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 10),
          _ScoreBreakdown(scores: evaluation.scores),
          const SizedBox(height: 10),
          _SuggestionsList(items: evaluation.improvementSuggestions),
        ],
      ],
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.scores});

  final TurnEvaluationScores scores;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ScoreRow(label: 'Relevance', value: scores.relevance),
        _ScoreRow(label: 'Clarity', value: scores.clarity),
        _ScoreRow(label: 'Technical Depth', value: scores.technicalDepth),
        _ScoreRow(label: 'Communication', value: scores.communicationQuality),
        _ScoreRow(label: 'Structure', value: scores.logicalStructure),
      ],
    );
  }
}

class _SuggestionsList extends StatelessWidget {
  const _SuggestionsList({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Improvement Suggestions',
          style: TextStyle(
            color: Color(0xFF173D8A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Icon(Icons.circle, size: 8, color: Color(0xFF1E4EA8)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      color: Color(0xFF314A73),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE6FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF173D8A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final safeValue = value.trim().isEmpty ? 'Not provided' : value.trim();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 84,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF173D8A),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            safeValue,
            style: const TextStyle(
              color: Color(0xFF38537E),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1E4EA8),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final progress = (value / 10).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF314A73),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$value/10',
                style: const TextStyle(
                  color: Color(0xFF173D8A),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor: const Color(0xFFE6EEFF),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E4EA8)),
          ),
        ],
      ),
    );
  }
}
