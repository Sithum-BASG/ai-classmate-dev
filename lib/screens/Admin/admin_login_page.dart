import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 20 : 32),
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : (isTablet ? 400 : 450),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Column(
                    children: [
                      Container(
                        width: isMobile ? 60 : 80,
                        height: isMobile ? 60 : 80,
                        decoration: BoxDecoration(
                          color: AppTheme.brandPrimary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: isMobile ? 32 : 40,
                        ),
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      Text(
                        'Admin Portal',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ClassMate Administration',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 32 : 48),

                  // Login Form
                  Container(
                    padding: EdgeInsets.all(isMobile ? 20 : 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sign In',
                            style: (isMobile
                                    ? Theme.of(context).textTheme.titleLarge
                                    : Theme.of(context).textTheme.headlineSmall)
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isMobile ? 24 : 32),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                            decoration: InputDecoration(
                              labelText: 'Admin Email',
                              labelStyle:
                                  TextStyle(fontSize: isMobile ? 13 : 15),
                              hintText: 'admin@classmate.lk',
                              hintStyle:
                                  TextStyle(fontSize: isMobile ? 13 : 14),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                size: isMobile ? 20 : 22,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderSubtle,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isMobile ? 12 : 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isMobile ? 16 : 20),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(fontSize: isMobile ? 14 : 16),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle:
                                  TextStyle(fontSize: isMobile ? 13 : 15),
                              hintText: 'Enter your password',
                              hintStyle:
                                  TextStyle(fontSize: isMobile ? 13 : 14),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                size: isMobile ? 20 : 22,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: isMobile ? 20 : 22,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderSubtle,
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: isMobile ? 12 : 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: isMobile ? 12 : 16),

                          // Remember Me and Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: Checkbox(
                                      value: false,
                                      onChanged: (value) {},
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      color: AppTheme.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  context.go('/admin/forgot-password');
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    color: AppTheme.brandPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 24 : 32),

                          // Login Button
                          SizedBox(
                            height: isMobile ? 48 : 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.brandPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Sign In',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontSize: isMobile ? 15 : 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 24 : 32),

                  // Back to Main Site
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        context.go('/');
                      },
                      icon: Icon(
                        Icons.arrow_back,
                        size: isMobile ? 18 : 20,
                      ),
                      label: Text(
                        'Back to Main Site',
                        style: TextStyle(fontSize: isMobile ? 14 : 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate login delay
      Future.delayed(const Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Navigate to admin dashboard
        context.go('/admin/dashboard');
      });
    }
  }
}
