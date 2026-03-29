import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/dashboard_service.dart';
import '../../../auth/presentation/screens/upload_cv_screen.dart';
import '../../../interview_coaching/presentation/screens/interview_coaching_screen.dart';
import '../../../job_analysis/presentation/screens/job_analysis_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();

  DashboardSnapshot? _snapshot;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _dashboardService.fetchSnapshot();
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'We could not load your dashboard right now.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openAndRefresh(Widget screen) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) {
      await _loadDashboard();
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final profile = snapshot?.profile ?? const <String, dynamic>{};
    final skills = (profile['skills'] as List?)?.length ?? 0;
    final experience = (profile['experience'] as List?)?.length ?? 0;
    final hasExistingProfile = snapshot?.hasExistingProfile ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('CareerLens'),
        backgroundColor: const Color(0xFF1E4EA8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _DashboardHero(
                    fullName: (profile['full_name'] as String?)?.trim() ?? '',
                    headline: (profile['headline'] as String?)?.trim() ?? '',
                    hasExistingProfile: hasExistingProfile,
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage != null) ...[
                    _StatusCard(message: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  const _SectionTitle(
                    title: 'Quick Actions',
                    subtitle:
                        'Jump into the most important parts of your workflow.',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          title: 'My Profile',
                          subtitle: 'Open and edit your saved profile.',
                          icon: Icons.account_circle_outlined,
                          onTap: () => _openAndRefresh(const ProfileScreen()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionTile(
                          title: 'Upload CV',
                          subtitle: 'Refresh your profile with a new CV.',
                          icon: Icons.upload_file_rounded,
                          onTap: () => _openAndRefresh(const UploadCvScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionTile(
                          title: 'Analyze Job',
                          subtitle: hasExistingProfile
                              ? 'Compare your profile against a job offer.'
                              : 'Upload a CV first to unlock this step.',
                          icon: Icons.analytics_outlined,
                          enabled: hasExistingProfile,
                          onTap: hasExistingProfile
                              ? () => _openAndRefresh(const JobAnalysisScreen())
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricSummaryTile(
                          skillCount: skills,
                          experienceCount: experience,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle(
                    title: 'Recent Job Analyses',
                    subtitle:
                        'Review your latest fit scores and the roles you analyzed.',
                  ),
                  const SizedBox(height: 12),
                  if (snapshot == null || snapshot.recentJobAnalyses.isEmpty)
                    const _EmptyCard(
                      title: 'No job analyses yet',
                      subtitle:
                          'Run a job analysis to start comparing your profile against target roles.',
                    )
                  else
                    ...snapshot.recentJobAnalyses.map(
                      (analysis) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _JobHistoryCard(analysis: analysis),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const _SectionTitle(
                    title: 'Interview Coaching History',
                    subtitle:
                        'Reopen recent coaching sessions and continue practicing.',
                  ),
                  const SizedBox(height: 12),
                  if (snapshot == null ||
                      snapshot.recentCoachingSessions.isEmpty)
                    const _EmptyCard(
                      title: 'No interview sessions yet',
                      subtitle:
                          'Start coaching from a job analysis result to build your readiness over time.',
                    )
                  else
                    ...snapshot.recentCoachingSessions.map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _CoachingHistoryCard(
                          session: session,
                          onTap: () => _openAndRefresh(
                            InterviewCoachingScreen(
                              existingSessionId: session.id,
                              initialLocation: session.location,
                              initialJobDescription: '',
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.fullName,
    required this.headline,
    required this.hasExistingProfile,
  });

  final String fullName;
  final String headline;
  final bool hasExistingProfile;

  @override
  Widget build(BuildContext context) {
    final safeName = fullName.isEmpty ? 'Welcome back' : fullName;
    final safeHeadline = headline.isEmpty
        ? hasExistingProfile
              ? 'Your AI career workflow is ready for the next step.'
              : 'Upload your CV to build your structured profile.'
        : headline;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF244D9B), Color(0xFF193E82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              hasExistingProfile ? 'Dashboard Ready' : 'Setup In Progress',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            safeName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            safeHeadline,
            style: const TextStyle(
              color: Color(0xFFDCE7FF),
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF173D8A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF62779E),
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = enabled
        ? const Color(0xFF173D8A)
        : const Color(0xFF90A2C2);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE7FF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: foreground, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: enabled
                    ? const Color(0xFF62779E)
                    : const Color(0xFF99A8C4),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricSummaryTile extends StatelessWidget {
  const _MetricSummaryTile({
    required this.skillCount,
    required this.experienceCount,
  });

  final int skillCount;
  final int experienceCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_graph_rounded,
            color: Color(0xFF1E4EA8),
            size: 24,
          ),
          const SizedBox(height: 12),
          Text(
            '$skillCount skills',
            style: const TextStyle(
              color: Color(0xFF173D8A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$experienceCount experience item${experienceCount == 1 ? '' : 's'} saved',
            style: const TextStyle(
              color: Color(0xFF62779E),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _JobHistoryCard extends StatelessWidget {
  const _JobHistoryCard({required this.analysis});

  final RecentJobAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7FF)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${analysis.score}',
                style: const TextStyle(
                  color: Color(0xFF173D8A),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.location.isEmpty
                      ? 'Location not provided'
                      : analysis.location,
                  style: const TextStyle(
                    color: Color(0xFF173D8A),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  analysis.preview.isEmpty
                      ? 'No job description preview available.'
                      : analysis.preview,
                  style: const TextStyle(
                    color: Color(0xFF62779E),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                if (analysis.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(analysis.createdAt!),
                    style: const TextStyle(
                      color: Color(0xFF8A9BB8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachingHistoryCard extends StatelessWidget {
  const _CoachingHistoryCard({required this.session, required this.onTap});

  final RecentCoachingSession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusLabel = session.completedAt == null
        ? 'Resume session'
        : 'Review session';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCE7FF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  '${session.readinessScore}',
                  style: const TextStyle(
                    color: Color(0xFF173D8A),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.location.isEmpty
                        ? 'Location not provided'
                        : session.location,
                    style: const TextStyle(
                      color: Color(0xFF173D8A),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    session.sessionSummary.isEmpty
                        ? 'No coaching summary available yet.'
                        : session.sessionSummary,
                    style: const TextStyle(
                      color: Color(0xFF62779E),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        statusLabel,
                        style: const TextStyle(
                          color: Color(0xFF1E4EA8),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (session.startedAt != null)
                        Text(
                          _formatDate(session.startedAt!),
                          style: const TextStyle(
                            color: Color(0xFF8A9BB8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.inbox_outlined, color: Color(0xFF1E4EA8), size: 22),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF173D8A),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF62779E),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3C0C7)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB42318),
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
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
