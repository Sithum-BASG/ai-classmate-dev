import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../config/areas.dart';
import '../../config/subjects.dart';

class TutorEditProfilePage extends StatefulWidget {
  const TutorEditProfilePage({super.key});

  @override
  State<TutorEditProfilePage> createState() => _TutorEditProfilePageState();
}

class _TutorEditProfilePageState extends State<TutorEditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _experienceController = TextEditingController();
  final _qualificationsController = TextEditingController();
  final _bioController = TextEditingController();
  String? _selectedAreaCode;
  final Set<String> _selectedSubjectCodes = <String>{};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _experienceController.dispose();
    _qualificationsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Edit Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Picture Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor:
                                    AppTheme.brandPrimary.withOpacity(0.1),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppTheme.brandPrimary,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.brandPrimary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      // TODO: Implement image picker
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to change profile picture',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Basic Information
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            'Full Name',
                            _nameController,
                            Icons.person,
                            'Enter your full name',
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailController,
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'Your login email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.email),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Phone',
                            _phoneController,
                            Icons.phone,
                            'Enter your phone number',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedAreaCode,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Area',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_drop_down),
                            items: [
                              for (final area in kAreaOptions)
                                DropdownMenuItem(
                                  value: area.code,
                                  child: Text(
                                    area.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedAreaCode = val),
                            validator: (val) => (val == null || val.isEmpty)
                                ? 'Please select your area'
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Professional Information
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Professional Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            'Teaching Experience',
                            _experienceController,
                            Icons.work,
                            'e.g., 8 years',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Qualifications',
                            _qualificationsController,
                            Icons.school,
                            'Enter your qualifications',
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Subjects Taught',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxChipWidth = constraints.maxWidth - 24;
                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final s in kSubjectOptions)
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: maxChipWidth),
                                      child: FilterChip(
                                        label: Text(
                                          s.label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        selected: _selectedSubjectCodes
                                            .contains(s.code),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedSubjectCodes.add(s.code);
                                            } else {
                                              _selectedSubjectCodes
                                                  .remove(s.code);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _bioController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: 'Bio',
                              hintText: 'Tell students about yourself...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.info_outline),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.brandPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: Icon(icon),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('tutor_profiles')
          .doc(user.uid)
          .get();
      final data = doc.data() ?? <String, dynamic>{};
      _nameController.text =
          (data['full_name'] as String?) ?? (user.displayName ?? '');
      _emailController.text = user.email ?? '';
      _phoneController.text = (data['phone'] as String?) ?? '';
      _experienceController.text = (data['experience'] as String?) ?? '';
      _qualificationsController.text =
          (data['qualifications'] as String?) ?? '';
      _bioController.text = (data['about'] as String?) ?? '';
      _selectedAreaCode = (data['area_code'] as String?) ?? _selectedAreaCode;
      final subjects =
          (data['subjects_taught'] as List?)?.cast<String>() ?? <String>[];
      _selectedSubjectCodes
        ..clear()
        ..addAll(subjects);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      final docRef =
          FirebaseFirestore.instance.collection('tutor_profiles').doc(user.uid);
      final existing = await docRef.get();
      final existingData = existing.data() ?? <String, dynamic>{};
      final update = <String, dynamic>{
        'full_name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'area_code': _selectedAreaCode,
        'experience': _experienceController.text.trim(),
        'qualifications': _qualificationsController.text.trim(),
        'about': _bioController.text.trim(),
        'subjects_taught': _selectedSubjectCodes.toList(),
      };
      // Preserve review/status fields explicitly to satisfy security rules
      if (existingData.containsKey('status'))
        update['status'] = existingData['status'];
      if (existingData.containsKey('reviewed_by'))
        update['reviewed_by'] = existingData['reviewed_by'];
      if (existingData.containsKey('reviewed_at'))
        update['reviewed_at'] = existingData['reviewed_at'];

      await docRef.set(update, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: AppTheme.brandSecondary,
        ),
      );
      final currentStatus = (existingData['status'] as String?) ?? 'pending';
      if (currentStatus == 'rejected') {
        context.go('/tutor/pending?rejected=1');
      } else if (currentStatus == 'pending') {
        context.go('/tutor/pending');
      } else {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go('/tutor/profile');
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
