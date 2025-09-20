import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/areas.dart';
import '../../config/subjects.dart';

class TutorRegisterPage extends StatefulWidget {
  const TutorRegisterPage({super.key});

  @override
  State<TutorRegisterPage> createState() => _TutorRegisterPageState();
}

class _TutorRegisterPageState extends State<TutorRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _areaCode;
  final Set<String> _subjectsTaught = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_areaCode == null || _subjectsTaught.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select area and subjects taught.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      await cred.user?.updateDisplayName(_nameController.text.trim());
      // Create tutor profile with pending status and core fields
      await FirebaseFirestore.instance
          .collection('tutor_profiles')
          .doc(cred.user!.uid)
          .set({
        'full_name': _nameController.text.trim(),
        'status': 'pending',
        'area_code': _areaCode,
        'subjects_taught': _subjectsTaught.toList(),
        'created_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      context.go('/tutor/pending');
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Sign up failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Tutor Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (v) => (v != _passwordController.text)
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _areaCode,
                items: kAreaOptions
                    .map((a) => DropdownMenuItem<String>(
                          value: a.code,
                          child: Text('${a.name} (${a.code})',
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                decoration: const InputDecoration(
                  labelText: 'Teaching Area',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
                isExpanded: true,
                onChanged: (v) => setState(() => _areaCode = v),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select your area' : null,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Subjects Taught',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  if (_subjectsTaught.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _subjectsTaught.clear()),
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
                      selected: _subjectsTaught.contains(s.code),
                      label:
                          Text(s.label, style: const TextStyle(fontSize: 12)),
                      onSelected: (sel) => setState(() {
                        if (sel) {
                          _subjectsTaught.add(s.code);
                        } else {
                          _subjectsTaught.remove(s.code);
                        }
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
