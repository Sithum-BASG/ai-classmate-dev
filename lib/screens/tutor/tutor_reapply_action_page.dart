import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class TutorReapplyActionPage extends StatefulWidget {
  const TutorReapplyActionPage({super.key});

  @override
  State<TutorReapplyActionPage> createState() => _TutorReapplyActionPageState();
}

class _TutorReapplyActionPageState extends State<TutorReapplyActionPage> {
  bool _working = false;
  String? _error;

  Future<void> _reapply() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      final ref =
          FirebaseFirestore.instance.collection('tutor_profiles').doc(user.uid);
      // Only update status to comply with security rules that allow
      // rejected -> pending self-transition
      await ref.update({'status': 'pending'});
      if (!mounted) return;
      context.go('/tutor/pending');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reapply for Approval')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Submit your profile for review again?\nThis will set your status to Pending.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _working ? null : _reapply,
                icon: const Icon(Icons.refresh),
                label: _working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Text('Reapply Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
