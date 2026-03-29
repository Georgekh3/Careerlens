import 'package:flutter/material.dart';

import '../../../job_analysis/presentation/screens/job_analysis_screen.dart';
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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF4F8FF),
              Color(0xFFEAF1FF),
            ],
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
                    const SizedBox(height: 20),
                    const Text(
                      'CareerLens',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF163B84),
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      hasExistingProfile
                          ? 'Your profile is already saved. You can continue with your existing CV or upload a new one.'
                          : 'Upload your CV to create your profile and unlock job analysis.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF5E7299),
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (hasExistingProfile) ...[
                      _ActionCard(
                        title: 'Use My Existing CV',
                        subtitle:
                            'Open your saved profile and continue from where you left off.',
                        icon: Icons.account_box_outlined,
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
                      buttonLabel: 'Upload CV',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const UploadCvScreen(),
                          ),
                        );
                      },
                    ),
                    if (hasExistingProfile) ...[
                      const SizedBox(height: 16),
                      _ActionCard(
                        title: 'Analyze a Job Offer',
                        subtitle:
                            'Use your saved profile to compare against a job description now.',
                        icon: Icons.analytics_outlined,
                        buttonLabel: 'Go to Job Analysis',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const JobAnalysisScreen(),
                            ),
                          );
                        },
                      ),
                    ],
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
    required this.buttonLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD9E5FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A2A63),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 30, color: const Color(0xFF1E4EA8)),
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
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E4EA8),
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
