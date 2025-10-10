import 'package:flutter/material.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../config/subjects.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _profileImagePath; // Placeholder; storage integration later
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();
  String _userName = '';
  String _userGradeLabel = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brandText),
          onPressed: () => context.go('/student'),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppTheme.brandText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text(
              'Home',
              style: TextStyle(color: AppTheme.brandPrimary),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Builder(builder: (context) {
                        ImageProvider? provider;
                        if (_profileImagePath != null) {
                          provider = FileImage(File(_profileImagePath!));
                        } else if (_profileImageUrl != null &&
                            _profileImageUrl!.isNotEmpty) {
                          provider = NetworkImage(_profileImageUrl!);
                        }
                        return CircleAvatar(
                          radius: 60,
                          backgroundColor:
                              AppTheme.brandPrimary.withValues(alpha: 0.1),
                          backgroundImage: provider,
                          child: provider == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppTheme.brandPrimary,
                                )
                              : null,
                        );
                      }),
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
                              _showImagePickerOptions();
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userName.isEmpty ? 'Student' : _userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.brandText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userGradeLabel,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfilePage(),
                        ),
                      );
                      if (updated == true && mounted) {
                        _loadUserProfile();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Quick Actions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionTile(
                    Icons.calendar_month,
                    'My Schedule',
                    'View your upcoming classes',
                    () {
                      context.push('/schedule');
                    },
                  ),
                  _buildActionTile(
                    Icons.notifications_outlined,
                    'Notifications',
                    'Manage your notification settings',
                    () {
                      context.push('/notifications');
                    },
                  ),
                  _buildActionTile(
                    Icons.settings_outlined,
                    'Settings',
                    'App settings and preferences',
                    () {
                      context.push('/settings');
                    },
                  ),
                  _buildActionTile(
                    Icons.help_outline,
                    'Help & Support',
                    'Get help with the app',
                    () {
                      context.push('/help');
                    },
                  ),
                  const Divider(height: 32, indent: 20, endIndent: 20),
                  _buildActionTile(
                    Icons.logout,
                    'Logout',
                    'Sign out of your account',
                    () {
                      _confirmAndLogout();
                    },
                    iconColor: Colors.red,
                    showArrow: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? iconColor,
    bool showArrow = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.brandPrimary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppTheme.brandPrimary,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
        ),
      ),
      trailing:
          showArrow ? Icon(Icons.chevron_right, color: Colors.grey[400]) : null,
      onTap: onTap,
    );
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  Icons.camera_alt,
                  'Camera',
                  () async {
                    Navigator.pop(context);
                    await _pickFromSource(ImageSource.camera);
                  },
                ),
                _buildImageOption(
                  Icons.photo_library,
                  'Gallery',
                  () async {
                    Navigator.pop(context);
                    await _pickFromSource(ImageSource.gallery);
                  },
                ),
                if (_profileImagePath != null ||
                    (_profileImageUrl != null && _profileImageUrl!.isNotEmpty))
                  _buildImageOption(
                    Icons.delete,
                    'Remove',
                    () async {
                      Navigator.pop(context);
                      await _removeProfilePhoto();
                    },
                    color: Colors.red,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption(IconData icon, String label, VoidCallback onTap,
      {Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color ?? AppTheme.brandPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color ?? AppTheme.brandText,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      context.go('/auth');
      return;
    }
    String name = user.displayName?.trim() ?? '';
    String gradeLabel = '';
    String? photoUrl = user.photoURL;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('student_profiles')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        name = (name.isEmpty
            ? ((data['full_name'] as String?) ?? '').trim()
            : name);
        final int? grade = (data['grade'] is int)
            ? data['grade'] as int
            : int.tryParse('${data['grade']}');
        if (grade != null) gradeLabel = 'Grade $grade Student';
        final String? p = (data['photoUrl'] as String?);
        if (p != null && p.isNotEmpty) photoUrl = p;
      }
    } catch (_) {
      // ignore Firestore errors and fallback
    }
    if (name.isEmpty && user.email != null) {
      name = user.email!.split('@').first;
    }
    if (!mounted) return;
    setState(() {
      _userName = name.isEmpty ? 'Student' : name;
      _userGradeLabel = gradeLabel;
      _profileImageUrl = photoUrl;
    });
  }

  Future<void> _pickFromSource(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => _profileImagePath = picked.path);
      await _uploadProfileImage(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _uploadProfileImage(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final ref = FirebaseStorage.instance.ref().child(
          'user_uploads/${user.uid}/profile/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      await FirebaseFirestore.instance
          .collection('student_profiles')
          .doc(user.uid)
          .set({'photoUrl': url}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _profileImageUrl = url;
        _profileImagePath = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _removeProfilePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() {
      _profileImagePath = null;
      _profileImageUrl = null;
    });
    try {
      await user.updatePhotoURL(null);
      await FirebaseFirestore.instance
          .collection('student_profiles')
          .doc(user.uid)
          .set({'photoUrl': FieldValue.delete()}, SetOptions(merge: true));
    } catch (_) {}
  }

  void _confirmAndLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              context.go('/auth');
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _schoolController = TextEditingController();
  int? _grade;
  final Set<String> _selectedSubjects = <String>{};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      context.go('/auth');
      return;
    }
    _emailController.text = user.email ?? '';
    _nameController.text = user.displayName ?? '';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('student_profiles')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        _nameController.text = (_nameController.text.isEmpty)
            ? ((data['full_name'] as String?) ?? '')
            : _nameController.text;
        _grade = (data['grade'] is int)
            ? data['grade'] as int
            : int.tryParse('${data['grade']}');
        _schoolController.text = (data['school'] as String?) ?? '';
        _phoneController.text = (data['phone'] as String?) ?? '';
        final List<dynamic>? subs =
            data['subjects_of_interest'] as List<dynamic>?;
        if (subs != null) _selectedSubjects.addAll(subs.map((e) => '$e'));
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final fullName = _nameController.text.trim();
      await user.updateDisplayName(fullName);
      final List<String> subjects = _selectedSubjects.toList();
      await FirebaseFirestore.instance
          .collection('student_profiles')
          .doc(user.uid)
          .set({
        'full_name': fullName,
        'grade': _grade ?? 0,
        'school': _schoolController.text.trim(),
        'phone': _phoneController.text.trim(),
        'subjects_of_interest': subjects,
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to save')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: AppTheme.brandText,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personal Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _textField('Full Name', _nameController, Icons.person,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Required'
                              : null),
                      _textField('Email Address', _emailController, Icons.email,
                          readOnly: true),
                      _textField('Phone Number', _phoneController, Icons.phone,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 24),
                      const Text(
                        'Academic Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _gradeDropdown(),
                      _textField(
                          'School/College', _schoolController, Icons.school),
                      _subjectsChips(),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _textField(
      String label, TextEditingController controller, IconData icon,
      {bool readOnly = false,
      String? Function(String?)? validator,
      TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.brandText,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            validator: validator,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 20, color: AppTheme.brandPrimary),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppTheme.brandPrimary, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Grade',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.brandText,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _grade,
            items: const [6, 7, 8, 9, 10, 11, 12, 13]
                .map((g) => DropdownMenuItem<int>(
                      value: g,
                      child: Text('Grade $g'),
                    ))
                .toList(),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.borderSubtle),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppTheme.brandPrimary, width: 2),
              ),
            ),
            onChanged: (v) => setState(() => _grade = v),
            validator: (v) => v == null ? 'Select your grade' : null,
          ),
        ],
      ),
    );
  }

  Widget _subjectsChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subjects of Interest',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.brandText,
                ),
              ),
              if (_selectedSubjects.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() => _selectedSubjects.clear()),
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in kSubjectOptions)
                FilterChip(
                  selected: _selectedSubjects.contains(s.code),
                  label: Text(s.label, style: const TextStyle(fontSize: 12)),
                  onSelected: (sel) => setState(() {
                    if (sel) {
                      _selectedSubjects.add(s.code);
                    } else {
                      _selectedSubjects.remove(s.code);
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
