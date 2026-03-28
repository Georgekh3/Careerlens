import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/config/supabase_config.dart';
import '../../../../core/services/profile_service.dart';
import '../../../job_analysis/presentation/screens/job_analysis_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.profile});

  final Map<String, dynamic>? profile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();

  Map<String, dynamic> _profile = <String, dynamic>{};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _profile = Map<String, dynamic>.from(
      widget.profile ?? const <String, dynamic>{},
    );
    if (SupabaseConfig.isConfigured) {
      _loadProfile();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loaded = await _profileService.fetchCurrentUserProfile();
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = loaded;
      });
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Unable to load your profile right now.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute<Map<String, dynamic>>(
        builder: (_) => EditProfileScreen(initialProfile: _profile),
      ),
    );

    if (updated != null) {
      await _saveProfile(updated);
    }
  }

  Future<void> _saveProfile(Map<String, dynamic> updated) async {
    if (!SupabaseConfig.isConfigured) {
      setState(() {
        _profile = updated;
      });
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final saved = await _profileService.saveCurrentUserProfile(updated);
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = saved;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
    } on PostgrestException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } on AuthException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Unable to save your profile right now.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
    final location = (_profile['location'] as String?)?.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: const Color(0xFF1E4EA8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) ...[
                    _SectionCard(
                      title: 'Status',
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFB42318)),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _ProfileHeaderCard(profile: _profile),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Overview',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _MetaBadge(
                          icon: Icons.location_on_outlined,
                          text: (location == null || location.isEmpty)
                              ? 'Location not available yet'
                              : location,
                        ),
                        _MetaBadge(
                          icon: Icons.psychology_alt_outlined,
                          text: '${skills.length} skill${skills.length == 1 ? '' : 's'} identified',
                        ),
                        _MetaBadge(
                          icon: Icons.work_outline_rounded,
                          text:
                              '${experience.length} experience item${experience.length == 1 ? '' : 's'}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Summary / About',
                    child: Text(
                      (summary == null || summary.isEmpty)
                          ? 'No summary available yet.'
                          : summary,
                      style: const TextStyle(
                        color: Color(0xFF2A3F66),
                        height: 1.45,
                      ),
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
                                        '${item['job_title'] ?? item['title'] ?? '-'} - ${item['company'] ?? '-'}',
                                    subtitle:
                                        '${item['start_date'] ?? '-'} to ${item['end_date'] ?? '-'}\n${item['description'] ?? '-'}',
                                    footer: _buildFooter(
                                      evidence: item['evidence']?.toString(),
                                      confidence: item['confidence'],
                                    ),
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
                                    title:
                                        '${item['degree'] ?? '-'} (${item['year'] ?? '-'})',
                                    subtitle: '${item['institution'] ?? '-'}',
                                    footer: _buildFooter(
                                      evidence: item['evidence']?.toString(),
                                      confidence: item['confidence'],
                                    ),
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
                                    title:
                                        '${item['name'] ?? '-'} (${item['year'] ?? '-'})',
                                    subtitle: '${item['issuer'] ?? '-'}',
                                    footer: _buildFooter(
                                      evidence: item['evidence']?.toString(),
                                      confidence: item['confidence'],
                                    ),
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
                      onPressed: _isSaving ? null : _openEditProfile,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.edit_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Edit Profile'),
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
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const JobAnalysisScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Continue to Analyze Job Offer'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E4EA8),
                        side: const BorderSide(color: Color(0xFFBCD0FF)),
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

  Widget? _buildFooter({
    required String? evidence,
    required dynamic confidence,
  }) {
    final safeEvidence = evidence?.trim() ?? '';
    final confidenceValue = confidence is num ? confidence.toDouble() : null;
    if (safeEvidence.isEmpty && confidenceValue == null) {
      return null;
    }

    final footerParts = <String>[];
    if (safeEvidence.isNotEmpty) {
      footerParts.add('Evidence: $safeEvidence');
    }
    if (confidenceValue != null) {
      footerParts.add(
        'Confidence: ${(confidenceValue * 100).clamp(0, 100).toStringAsFixed(0)}%',
      );
    }

    return Text(
      footerParts.join('\n'),
      style: const TextStyle(
        color: Color(0xFF6B7FA6),
        fontSize: 12,
        height: 1.35,
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
    final location = (profile['location'] as String?)?.trim();

    final safeName = (name == null || name.isEmpty) ? 'User Name' : name;
    final safeEmail = (email == null || email.isEmpty) ? 'No email yet' : email;
    final safeHeadline = (headline == null || headline.isEmpty)
        ? 'Headline not available yet'
        : headline;

    final initials = safeName.isNotEmpty
        ? safeName.substring(0, 1).toUpperCase()
        : 'U';

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
                if (location != null && location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    location,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

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
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget? footer;

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
          if (footer != null) ...[
            const SizedBox(height: 6),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7E3FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1E4EA8)),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF2C4676),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
