import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.initialProfile,
  });

  final Map<String, dynamic> initialProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _headlineController;
  late final TextEditingController _locationController;
  late final TextEditingController _summaryController;
  late final TextEditingController _skillsController;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.initialProfile['full_name'] as String? ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialProfile['email'] as String? ?? '',
    );
    _headlineController = TextEditingController(
      text: widget.initialProfile['headline'] as String? ?? '',
    );
    _locationController = TextEditingController(
      text: widget.initialProfile['location'] as String? ?? '',
    );
    _summaryController = TextEditingController(
      text: widget.initialProfile['summary'] as String? ?? '',
    );

    final rawSkills = widget.initialProfile['skills'];
    final skills = rawSkills is List ? rawSkills.cast<String>() : <String>[];
    _skillsController = TextEditingController(text: skills.join(', '));
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _headlineController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parsedSkills = _skillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final updatedProfile = <String, dynamic>{
      ...widget.initialProfile,
      'full_name': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'headline': _headlineController.text.trim(),
      'location': _locationController.text.trim(),
      'summary': _summaryController.text.trim(),
      'skills': parsedSkills,
    };

    Navigator.of(context).pop(updatedProfile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF1E4EA8),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InputField(
                label: 'Full Name',
                controller: _fullNameController,
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) {
                    return 'Full name is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = (value ?? '').trim();
                  if (email.isEmpty) {
                    return 'Email is required.';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
                    return 'Enter a valid email.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Headline',
                controller: _headlineController,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Headline is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Location',
                controller: _locationController,
                validator: (value) => null,
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Summary / About',
                controller: _summaryController,
                maxLines: 4,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Summary is required.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _InputField(
                label: 'Skills (comma separated)',
                controller: _skillsController,
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return 'Add at least one skill.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save Changes'),
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
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    required this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF163B84),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD6E1FB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD6E1FB)),
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
