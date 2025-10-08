import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String? _photoUrl;
  String? _localPath;
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
      context.go('/admin');
      return;
    }
    String name = user.displayName ?? '';
    String phone = '';
    String? photo = user.photoURL;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (data != null) {
        name = name.isEmpty ? ((data['name'] as String?) ?? '') : name;
        phone = (data['phone'] as String?) ?? '';
        final p = (data['photoUrl'] as String?);
        if (p != null && p.isNotEmpty) photo = p;
      }
    } catch (_) {}
    _nameController.text = name;
    _phoneController.text = phone;
    setState(() {
      _photoUrl = photo;
      _loading = false;
    });
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final x = await _picker.pickImage(
          source: source, maxWidth: 1200, imageQuality: 85);
      if (x == null) return;
      setState(() => _localPath = x.path);
      await _upload(File(x.path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  Future<void> _upload(File file) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final ref = FirebaseStorage.instance.ref(
          'user_uploads/${user.uid}/profile/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();
      await user.updatePhotoURL(url);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'photoUrl': url}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _photoUrl = url;
        _localPath = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile photo updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removePhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.updatePhotoURL(null);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'photoUrl': FieldValue.delete()}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _photoUrl = null);
    } catch (_) {}
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      await user.updateDisplayName(name);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': name,
        'phone': _phoneController.text.trim(),
        'role': 'admin',
        'status': FieldValue.delete(),
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    if (!mounted) return;
    context.go('/admin');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Profile',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(isMobile ? 16 : 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: isMobile ? 36 : 40,
                                  backgroundColor: AppTheme.brandPrimary
                                      .withValues(alpha: 0.1),
                                  backgroundImage: _localPath != null
                                      ? FileImage(File(_localPath!))
                                      : (_photoUrl?.isNotEmpty == true
                                          ? NetworkImage(_photoUrl!)
                                          : null) as ImageProvider<Object>?,
                                  child:
                                      (_photoUrl == null && _localPath == null)
                                          ? Text(
                                              (email.isNotEmpty
                                                      ? email[0].toUpperCase()
                                                      : 'A')
                                                  .toString(),
                                              style: const TextStyle(
                                                  color: AppTheme.brandPrimary,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: InkWell(
                                    onTap: () => _showImagePicker(),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandPrimary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(email,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                  const SizedBox(height: 4),
                                  const Text('Role: Admin',
                                      style:
                                          TextStyle(color: AppTheme.mutedText)),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _signOut,
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign out'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                child: _saving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : const Text('Save Changes'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_photoUrl != null)
                              OutlinedButton(
                                onPressed: _saving ? null : _removePhoto,
                                child: const Text('Remove Photo'),
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

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _pickerTile(Icons.camera_alt, 'Camera', () {
              Navigator.pop(context);
              _pick(ImageSource.camera);
            }),
            _pickerTile(Icons.photo_library, 'Gallery', () {
              Navigator.pop(context);
              _pick(ImageSource.gallery);
            }),
          ],
        ),
      ),
    );
  }

  Widget _pickerTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.brandPrimary),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
