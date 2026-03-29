import 'package:flutter/material.dart';

import '../../../profile/presentation/screens/profile_screen.dart';
import 'upload_cv_screen.dart';

class ResumeEntryScreen extends StatelessWidget {
  const ResumeEntryScreen({
    super.key,
    required this.hasExistingProfile,
  });

  final bool hasExistingProfile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF6F9FF), Color(0xFFE7EEFF)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    _HeroCard(hasExistingProfile: hasExistingProfile),
                    const SizedBox(height: 24),
                    const _SectionLabel(
                      title: 'Choose How To Continue',
                      subtitle:
                          'Pick up your existing profile or refresh it with a new CV upload.',
                    ),
                    const SizedBox(height: 18),
                    if (hasExistingProfile) ...[
                      _ActionCard(
                        title: 'Use My Existing CV',
                        subtitle:
                            'Open your saved profile and continue from where you left off.',
                        icon: Icons.account_box_outlined,
                        accentColor: const Color(0xFF0E5CAD),
                        buttonLabel: 'Open My Profile',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    _ActionCard(
                      title: 'Upload New CV',
                      subtitle:
                          'Upload a fresh CV to update your structured profile.',
                      icon: Icons.upload_file_rounded,
                      accentColor: const Color(0xFF1E4EA8),
                      buttonLabel: 'Upload CV',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const UploadCvScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A2A63),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: accentColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF173D8A),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF5A6E95),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F9FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: Color(0xFF1E4EA8),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your saved progress stays linked to the same account.',
                    style: TextStyle(
                      color: Color(0xFF486187),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.hasExistingProfile});

  final bool hasExistingProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF244D9B), Color(0xFF1B3F83)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2220468B),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
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
            child: const Text(
              'AI Career Workflow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'CareerLens',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasExistingProfile
                ? 'Your profile is already saved. Reopen it, continue job analysis, or replace it with a stronger CV version.'
                : 'Start with your CV and turn it into a structured profile built for job analysis and interview coaching.',
            style: const TextStyle(
              color: Color(0xFFDCE7FF),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroStat(label: 'CV to Profile'),
              _HeroStat(label: 'Job Match'),
              _HeroStat(label: 'Interview Coaching'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.title,
    required this.subtitle,
  });

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
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF62779E),
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
