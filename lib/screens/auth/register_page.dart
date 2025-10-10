import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../config/subjects.dart';
import '../../models/student_profile.dart';
import '../../config/areas.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  int? _grade;
  String? _areaCode;
  final Set<String> _selectedSubjects = <String>{};

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
    if (_grade == null || _areaCode == null || _selectedSubjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete profile details.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final profile = StudentProfile(
        uid: 'TEMP',
        fullName: _nameController.text.trim(),
        grade: _grade!,
        areaCode: _areaCode!,
        subjectCodesOfInterest: _selectedSubjects.toList(),
      );
      final auth = AuthService();
      await auth.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        profile: profile,
      );
      if (!mounted) return;
      context.go('/student');
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? 'Sign up failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Unexpected error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/auth/login'),
            child: const Text('Login',
                style: TextStyle(color: AppTheme.brandPrimary)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.getHorizontalPadding(context),
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppTheme.getContentMaxWidth(context),
            ),
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
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your name'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your email' : null,
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
                        onPressed: () => setState(() {
                          _obscure = !_obscure;
                        }),
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
                  const Text(
                    'Student Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.brandText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: _grade,
                    items: const [6, 7, 8, 9, 10, 11, 12, 13]
                        .map((g) => DropdownMenuItem<int>(
                              value: g,
                              child: Text('Grade $g'),
                            ))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Current Grade',
                      prefixIcon: Icon(Icons.school_outlined),
                    ),
                    isExpanded: true,
                    onChanged: (v) => setState(() => _grade = v),
                    validator: (v) => v == null ? 'Select your grade' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _areaCode,
                    items: kAreaOptions
                        .map((a) => DropdownMenuItem<String>(
                              value: a.code,
                              child: Text(
                                '${a.name} (${a.code})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    decoration: const InputDecoration(
                      labelText: 'Area',
                      prefixIcon: Icon(Icons.place_outlined),
                    ),
                    isExpanded: true,
                    selectedItemBuilder: (context) => kAreaOptions
                        .map((a) => Text(
                              '${a.name} (${a.code})',
                              overflow: TextOverflow.ellipsis,
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _areaCode = v),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Select your area' : null,
                  ),
                  const SizedBox(height: 12),
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Subjects of Interest',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final s in kSubjectOptions)
                          FilterChip(
                            selected: _selectedSubjects.contains(s.code),
                            label: Text(s.label,
                                style: const TextStyle(fontSize: 12)),
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
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text('Create Account'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/auth/login'),
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
