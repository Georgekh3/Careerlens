import 'package:flutter/material.dart';

import '../../../../core/services/interview_preparation_service.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class InterviewPreparationScreen extends StatefulWidget {
  const InterviewPreparationScreen({
    super.key,
    required this.initialLocation,
    required this.initialJobDescription,
  });

  final String initialLocation;
  final String initialJobDescription;

  @override
  State<InterviewPreparationScreen> createState() =>
      _InterviewPreparationScreenState();
}

class _InterviewPreparationScreenState extends State<InterviewPreparationScreen> {
  final InterviewPreparationService _service = InterviewPreparationService();

  bool _isSubmitting = false;
  String? _errorMessage;
  InterviewPreparationResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _prepareInterview();
      }
    });
  }

  Future<void> _prepareInterview() async {
    if (widget.initialJobDescription.trim().length < 20) {
      setState(() {
        _errorMessage = 'The selected job description is too short for interview preparation.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.prepareInterview(
        rawText: widget.initialJobDescription.trim(),
        location: widget.initialLocation.trim(),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Interview Preparation'),
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
              title: 'Target Role',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MetaLine(label: 'Location', value: widget.initialLocation),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isSubmitting)
              const _SectionCard(
                title: 'Generating',
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
                        'Building your interview preparation based on the selected job offer.',
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
            if (_result != null) _InterviewPrepResultCard(result: _result!),
          ],
        ),
      ),
    );
  }
}

class _InterviewPrepResultCard extends StatelessWidget {
  const _InterviewPrepResultCard({required this.result});

  final InterviewPreparationResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Readiness Summary',
          child: Text(
            result.interviewReadinessSummary.isEmpty
                ? 'No interview summary available yet.'
                : result.interviewReadinessSummary,
            style: const TextStyle(
              color: Color(0xFF38537E),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Personal Pitch',
          child: Text(
            result.personalPitch.isEmpty
                ? 'No personal pitch generated.'
                : result.personalPitch,
            style: const TextStyle(
              color: Color(0xFF38537E),
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Focus Areas',
          child: _BulletList(
            items: result.focusAreas,
            emptyLabel: 'No focus areas generated.',
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Likely Interview Topics',
          child: _BulletList(
            items: result.likelyTopics,
            emptyLabel: 'No likely topics generated.',
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Practice Questions',
          child: result.tailoredQuestions.isEmpty
              ? const Text(
                  'No tailored questions generated.',
                  style: TextStyle(color: Color(0xFF556B93), fontSize: 13),
                )
              : Column(
                  children: result.tailoredQuestions
                      .map(
                        (question) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question.question,
                                style: const TextStyle(
                                  color: Color(0xFF173D8A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                question.whyItMatters,
                                style: const TextStyle(
                                  color: Color(0xFF4E6388),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _BulletList(
                                items: question.suggestedTalkingPoints,
                                emptyLabel: 'No talking points suggested.',
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Final Tips',
          child: _BulletList(
            items: result.finalTips,
            emptyLabel: 'No final tips generated.',
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

class _BulletList extends StatelessWidget {
  const _BulletList({
    required this.items,
    required this.emptyLabel,
  });

  final List<String> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        emptyLabel,
        style: const TextStyle(color: Color(0xFF556B93), fontSize: 13),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF1E4EA8),
                    ),
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
          )
          .toList(),
    );
  }
}
