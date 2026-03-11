import 'package:flutter/material.dart';

import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.profile,
  });

  final Map<String, dynamic> profile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Map<String, dynamic> _profile;

  @override
  void initState() {
    super.initState();
    _profile = Map<String, dynamic>.from(widget.profile);
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => EditProfileScreen(initialProfile: _profile),
      ),
    );

    if (updated != null) {
      setState(() {
        _profile = updated;
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    }
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return <String>[];
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  @override
  Widget build(BuildContext context) {
    final skills = _asStringList(_profile['skills']);
    final experience = _asMapList(_profile['experience']);
    final education = _asMapList(_profile['education']);
    final certifications = _asMapList(_profile['certifications']);

    final summary = (_profile['summary'] as String?)?.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF1E4EA8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeaderCard(profile: _profile),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Summary / About',
              child: Text(
                (summary == null || summary.isEmpty)
                    ? 'No summary available yet.'
                    : summary,
                style: const TextStyle(color: Color(0xFF2A3F66), height: 1.45),
              ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Skills',
              child: skills.isEmpty
                  ? const Text(
                      'No skills available yet.',
                      style: TextStyle(color: Color(0xFF4E6388)),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: skills
                          .map(
                            (skill) => Chip(
                              label: Text(skill),
                              backgroundColor: const Color(0xFFE9F0FF),
                              labelStyle: const TextStyle(
                                color: Color(0xFF1E4EA8),
                                fontWeight: FontWeight.w600,
                              ),
                              side: BorderSide.none,
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Experience',
              child: experience.isEmpty
                  ? const Text(
                      'No experience available yet.',
                      style: TextStyle(color: Color(0xFF4E6388)),
                    )
                  : Column(
                      children: experience
                          .map(
                            (item) => _DetailTile(
                              title:
                                  '${item['job_title'] ?? '-'} - ${item['company'] ?? '-'}',
                              subtitle:
                                  '${item['start_date'] ?? '-'} to ${item['end_date'] ?? '-'}\n${item['description'] ?? '-'}',
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Education',
              child: education.isEmpty
                  ? const Text(
                      'No education available yet.',
                      style: TextStyle(color: Color(0xFF4E6388)),
                    )
                  : Column(
                      children: education
                          .map(
                            (item) => _DetailTile(
                              title: '${item['degree'] ?? '-'} (${item['year'] ?? '-'})',
                              subtitle: '${item['institution'] ?? '-'}',
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              title: 'Certifications',
              child: certifications.isEmpty
                  ? const Text(
                      'No certifications available yet.',
                      style: TextStyle(color: Color(0xFF4E6388)),
                    )
                  : Column(
                      children: certifications
                          .map(
                            (item) => _DetailTile(
                              title: '${item['name'] ?? '-'} (${item['year'] ?? '-'})',
                              subtitle: '${item['issuer'] ?? '-'}',
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openEditProfile,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Edit Profile'),
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
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final name = (profile['full_name'] as String?)?.trim();
    final email = (profile['email'] as String?)?.trim();
    final headline = (profile['headline'] as String?)?.trim();

    final safeName = (name == null || name.isEmpty) ? 'User Name' : name;
    final safeEmail = (email == null || email.isEmpty) ? 'No email yet' : email;
    final safeHeadline =
        (headline == null || headline.isEmpty) ? 'Headline not available yet' : headline;

    final initials =
        safeName.isNotEmpty ? safeName.substring(0, 1).toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E63C5), Color(0xFF1E4EA8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E4EA8),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  safeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  safeHeadline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  safeEmail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E9FA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF163B84),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1A3567),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF4E6388),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
