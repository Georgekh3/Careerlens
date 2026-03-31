import 'package:flutter/material.dart';

import '../../../../core/services/dashboard_service.dart';

class JobAnalysisDetailScreen extends StatefulWidget {
  const JobAnalysisDetailScreen({super.key, required this.analysisId});

  final String analysisId;

  @override
  State<JobAnalysisDetailScreen> createState() =>
      _JobAnalysisDetailScreenState();
}

class _JobAnalysisDetailScreenState extends State<JobAnalysisDetailScreen> {
  final DashboardService _dashboardService = DashboardService();

  SavedJobAnalysisDetail? _detail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _dashboardService.fetchJobAnalysisDetail(
        widget.analysisId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _detail = detail;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'We could not load this saved job analysis right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Text('Saved Job Analysis'),
        backgroundColor: const Color(0xFF1E4EA8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFB42318)),
                ),
              ),
            )
          : detail == null
          ? const SizedBox.shrink()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionCard(
                    title: 'Saved Context',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          detail.location.isEmpty
                              ? 'Location not provided'
                              : detail.location,
                          style: const TextStyle(
                            color: Color(0xFF173D8A),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (detail.createdAt != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _formatDate(detail.createdAt!),
                            style: const TextStyle(
                              color: Color(0xFF8194B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          detail.rawText.isEmpty
                              ? 'No saved job description text.'
                              : detail.rawText,
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
                    title: 'Overall Fit',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${detail.score}/100',
                          style: const TextStyle(
                            color: Color(0xFF173D8A),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.overallSummary.isEmpty
                              ? 'No summary available.'
                              : detail.overallSummary,
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
                          value: detail.skillsMatchScore,
                          max: 40,
                        ),
                        _ScoreRow(
                          label: 'Experience Match',
                          value: detail.experienceMatchScore,
                          max: 35,
                        ),
                        _ScoreRow(
                          label: 'Education & Certifications',
                          value: detail.educationCertScore,
                          max: 15,
                        ),
                        _ScoreRow(
                          label: 'Domain Relevance',
                          value: detail.domainRelevanceScore,
                          max: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Matched Skills',
                    child: _BulletList(
                      items: detail.matchedSkills,
                      emptyLabel: 'No matched skills.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Missing Skills',
                    child: _BulletList(
                      items: detail.missingSkills,
                      emptyLabel: 'No missing skills.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Missing Requirements',
                    child: _BulletList(
                      items: detail.missingRequirements,
                      emptyLabel: 'No missing requirements.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Recommendations',
                    child: _BulletList(
                      items: detail.recommendations,
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
                          items: detail.strengths,
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
                        _BulletList(
                          items: detail.risks,
                          emptyLabel: 'No risks listed.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final month = <int, String>{
    1: 'Jan',
    2: 'Feb',
    3: 'Mar',
    4: 'Apr',
    5: 'May',
    6: 'Jun',
    7: 'Jul',
    8: 'Aug',
    9: 'Sep',
    10: 'Oct',
    11: 'Nov',
    12: 'Dec',
  }[local.month];

  return '${month ?? local.month}/${local.day}/${local.year}';
}
