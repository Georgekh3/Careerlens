import 'package:flutter/material.dart';

import '../../../../core/services/job_analysis_service.dart';
import '../../../../core/services/service_exception.dart';
import '../../../interview_coaching/presentation/screens/interview_coaching_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class JobAnalysisScreen extends StatefulWidget {
  const JobAnalysisScreen({super.key});

  @override
  State<JobAnalysisScreen> createState() => _JobAnalysisScreenState();
}

class _JobAnalysisScreenState extends State<JobAnalysisScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _jobDescriptionController = TextEditingController();
  final JobAnalysisService _jobAnalysisService = JobAnalysisService();

  bool _isSubmitting = false;
  String? _errorMessage;
  JobAnalysisResult? _result;

  @override
  void dispose() {
    _locationController.dispose();
    _jobDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyzeJob() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _jobAnalysisService.analyzeJob(
        rawText: _jobDescriptionController.text.trim(),
        location: _locationController.text.trim(),
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
      setState(() {
        _errorMessage = ServiceErrorMapper.toUserMessage(
          error,
          fallback:
              'We could not analyze this job offer right now. Please try again.',
        );
      });
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
        title: const Text('Job Analysis'),
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
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionCard(
                title: 'Paste Job Offer',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Paste the role you want to compare against your saved profile. CareerLens will score the match and point out the biggest gaps.',
                      style: TextStyle(
                        color: Color(0xFF5B7199),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _InputField(
                      label: 'Location',
                      controller: _locationController,
                      validator: (_) => null,
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      label: 'Job Description',
                      controller: _jobDescriptionController,
                      maxLines: 12,
                      validator: (value) {
                        if ((value ?? '').trim().length < 20) {
                          return 'Paste a fuller job description.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _analyzeJob,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.analytics_outlined),
                        label: Text(
                          _isSubmitting ? 'Analyzing...' : 'Analyze Job Offer',
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
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF3C0C7)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFB42318),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFB42318),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_result != null) ...[
                const SizedBox(height: 16),
                _ResultHeader(result: _result!),
                const SizedBox(height: 12),
                _AnalysisResultCard(result: _result!),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => InterviewCoachingScreen(
                            initialLocation: _locationController.text.trim(),
                            initialJobDescription: _jobDescriptionController
                                .text
                                .trim(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.record_voice_over_outlined),
                    label: const Text('Start AI Interview Coaching'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E4EA8),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E4EA8),
                      side: const BorderSide(color: Color(0xFFBCD0FF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.result});

  final JobAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    final score = result.overallFitScore;
    final label = score >= 75
        ? 'Strong Match'
        : score >= 50
        ? 'Moderate Match'
        : 'Gap Detected';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF204B97), Color(0xFF173C80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.insights_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CareerLens compared your structured profile against this role and ranked the clearest overlaps and biggest gaps.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalysisResultCard extends StatelessWidget {
  const _AnalysisResultCard({required this.result});

  final JobAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Overall Fit',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.overallFitScore}/100',
                style: const TextStyle(
                  color: Color(0xFF173D8A),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result.overallSummary.isEmpty
                    ? 'Analysis summary not available.'
                    : result.overallSummary,
                style: const TextStyle(
                  color: Color(0xFF38537E),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Score Breakdown',
          child: Column(
            children: [
              _ScoreRow(
                label: 'Skills Match',
                value: result.skillsMatchScore,
                max: 40,
              ),
              _ScoreRow(
                label: 'Experience Match',
                value: result.experienceMatchScore,
                max: 35,
              ),
              _ScoreRow(
                label: 'Education & Certifications',
                value: result.educationCertScore,
                max: 15,
              ),
              _ScoreRow(
                label: 'Domain Relevance',
                value: result.domainRelevanceScore,
                max: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Matched Skills',
          child: _BulletList(
            items: result.matchedSkills,
            emptyLabel: 'No matched skills.',
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Missing Skills',
          child: _BulletList(
            items: result.missingSkills,
            emptyLabel: 'No missing skills.',
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Missing Requirements',
          child: _BulletList(
            items: result.missingRequirements,
            emptyLabel: 'No missing requirements.',
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Recommendations',
          child: _BulletList(
            items: result.recommendations,
            emptyLabel: 'No recommendations generated.',
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Strengths and Risks',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Strengths',
                style: TextStyle(
                  color: Color(0xFF173D8A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              _BulletList(
                items: result.strengths,
                emptyLabel: 'No strengths listed.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Risks',
                style: TextStyle(
                  color: Color(0xFF173D8A),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              _BulletList(items: result.risks, emptyLabel: 'No risks listed.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

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

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    required this.validator,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF173D8A),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
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
      ],
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.emptyLabel});

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

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.label,
    required this.value,
    required this.max,
  });

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final progress = max == 0 ? 0.0 : (value / max).clamp(0, 1).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
                '$value/$max',
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
