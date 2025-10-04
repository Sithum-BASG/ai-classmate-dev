import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme.dart';
import '../../config/backend.dart';

class CreateSessionPage extends StatefulWidget {
  final String classId;
  final String? sessionId; // if provided → edit mode

  const CreateSessionPage({super.key, required this.classId, this.sessionId});

  @override
  State<CreateSessionPage> createState() => _CreateSessionPageState();
}

class _CreateSessionPageState extends State<CreateSessionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  DateTime? _selectedDate; // date only
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _submitting = false;
  bool _loadingExisting = false;

  bool get isEditing => widget.sessionId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingExisting = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('sessions')
          .doc(widget.sessionId!)
          .get();
      final data = doc.data();
      if (data != null) {
        final startTs = data['start_time'];
        final endTs = data['end_time'];
        if (startTs is Timestamp) {
          final dt = startTs.toDate();
          _selectedDate = DateTime(dt.year, dt.month, dt.day);
          _selectedStartTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        }
        if (endTs is Timestamp) {
          final dt = endTs.toDate();
          _selectedEndTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        }
        _labelController.text = (data['label'] as String?) ?? '';
        _venueController.text = (data['venue'] as String?) ?? '';
      }
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (date == null) return;
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
  }

  Future<void> _pickStartTime() async {
    final now = TimeOfDay.now();
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? now,
    );
    if (t == null) return;
    setState(() {
      _selectedStartTime = t;
      if (_selectedEndTime != null && !_isEndAfterStart(_selectedEndTime!, t)) {
        _selectedEndTime = null;
      }
    });
  }

  Future<void> _pickEndTime() async {
    if (_selectedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a start time first')),
      );
      return;
    }
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? _selectedStartTime!,
    );
    if (t == null) return;
    if (!_isEndAfterStart(t, _selectedStartTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    setState(() {
      _selectedEndTime = t;
    });
  }

  bool _isEndAfterStart(TimeOfDay end, TimeOfDay start) {
    final endMinutes = end.hour * 60 + end.minute;
    final startMinutes = start.hour * 60 + start.minute;
    return endMinutes > startMinutes;
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a date')),
      );
      return;
    }
    if (_selectedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a start time')),
      );
      return;
    }
    if (_selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an end time')),
      );
      return;
    }
    if (!_isEndAfterStart(_selectedEndTime!, _selectedStartTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
    });
    try {
      // Ensure latest custom claims (role/tutorApproved) after approval
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      final startDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );
      final endDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedEndTime!.hour,
        _selectedEndTime!.minute,
      );
      final callable =
          FirebaseFunctions.instanceFor(region: BackendConfig.firebaseRegion)
              .httpsCallable(BackendConfig.fnCreateOrUpdateSession);
      await callable.call({
        'classId': widget.classId,
        if (isEditing) 'sessionId': widget.sessionId,
        'startMs': startDateTime.millisecondsSinceEpoch,
        'endMs': endDateTime.millisecondsSinceEpoch,
        if (_labelController.text.trim().isNotEmpty)
          'label': _labelController.text.trim(),
        if (_venueController.text.trim().isNotEmpty)
          'venue': _venueController.text.trim(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isEditing ? 'Session updated' : 'Session created')),
      );
      context.pop();
    } on FirebaseFunctionsException catch (e) {
      String message;
      switch (e.code) {
        case 'failed-precondition':
          message =
              'This session overlaps with another one. Please choose a different time.';
          break;
        case 'permission-denied':
          message =
              'You are not allowed to create sessions. Ensure your tutor account is approved and you own this class.';
          break;
        case 'invalid-argument':
          message =
              'Please check the date and time you selected and try again.';
          break;
        case 'not-found':
          message = 'Class not found or access denied.';
          break;
        default:
          message = e.message ?? 'Something went wrong. Please try again.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Couldn't create session. Please try again.")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
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
          onPressed: () => context.pop(),
        ),
        title: Text(isEditing ? 'Edit Session' : 'Create Session'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                child: _loadingExisting && isEditing
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _labelController,
                            decoration: const InputDecoration(
                              labelText: 'Optional label',
                              hintText: 'e.g., Week 1, Intro, etc.',
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _venueController,
                            decoration: const InputDecoration(
                              labelText: 'Venue (optional)',
                              hintText: 'e.g., Room 201, Zoom link',
                              border: OutlineInputBorder(),
                            ),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Date'),
                            subtitle: Text(
                              _selectedDate == null
                                  ? 'Choose date'
                                  : _formatDateOnly(_selectedDate!),
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: OutlinedButton.icon(
                              onPressed: _pickDate,
                              icon: const Icon(Icons.calendar_today),
                              label: const Text('Pick'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Start time'),
                            subtitle: Text(
                              _selectedStartTime == null
                                  ? 'Choose start time'
                                  : _formatTimeOfDay(_selectedStartTime!),
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: OutlinedButton.icon(
                              onPressed: _pickStartTime,
                              icon: const Icon(Icons.schedule),
                              label: const Text('Pick'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('End time'),
                            subtitle: Text(
                              _selectedEndTime == null
                                  ? 'Choose end time'
                                  : _formatTimeOfDay(_selectedEndTime!),
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: OutlinedButton.icon(
                              onPressed: _pickEndTime,
                              icon: const Icon(Icons.schedule_outlined),
                              label: const Text('Pick'),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Create Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateOnly(DateTime dt) {
    final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final day = dayNames[dt.weekday % 7];
    final month = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$day $d/$month ${dt.year}';
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final minute = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $ampm';
  }
}
