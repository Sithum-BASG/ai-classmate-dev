import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/subjects.dart';
import '../../config/areas.dart';
import '../../theme.dart';

class CreateClassPage extends StatefulWidget {
  final String? classId;

  const CreateClassPage({
    super.key,
    this.classId,
  });

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final _classNameController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'Group';
  String _selectedMode = 'In-person';
  String? _selectedSubjectCode;
  String? _selectedAreaCode;
  int? _selectedGrade; // 6-13
  bool _isLoadingExisting = false;

  @override
  void initState() {
    super.initState();
    if (widget.classId != null) {
      _loadExistingClass();
    }
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _priceController.dispose();
    _maxStudentsController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.classId != null;

    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(isEditing ? 'Edit Class' : 'Create Class'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class Details Card
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
                child: (_isLoadingExisting && isEditing)
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Class Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Class Name
                          TextFormField(
                            controller: _classNameController,
                            decoration: const InputDecoration(
                              labelText: 'Class Name',
                              hintText: 'e.g., Physics A/L - Evening Batch',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? 'Please enter class name'
                                    : null,
                          ),
                          const SizedBox(height: 16),

                          // Subject dropdown
                          DropdownButtonFormField<String>(
                            value: _selectedSubjectCode,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Subject',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final s in kSubjectOptions)
                                DropdownMenuItem(
                                  value: s.code,
                                  child: Text(s.label,
                                      overflow: TextOverflow.ellipsis),
                                ),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedSubjectCode = val),
                            validator: (val) => (val == null || val.isEmpty)
                                ? 'Please select subject'
                                : null,
                          ),
                          const SizedBox(height: 16),

                          // Type and Mode
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedType,
                                  decoration: const InputDecoration(
                                    labelText: 'Type',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ['Group', 'Individual']
                                      .map((type) => DropdownMenuItem(
                                            value: type,
                                            child: Text(type),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedType = value!);
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedMode,
                                  decoration: const InputDecoration(
                                    labelText: 'Mode',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ['In-person', 'Online', 'Hybrid']
                                      .map((mode) => DropdownMenuItem(
                                            value: mode,
                                            child: Text(mode),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedMode = value!);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Grade and Area
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _selectedGrade,
                                  decoration: const InputDecoration(
                                    labelText: 'Grade',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [for (int g = 6; g <= 13; g++) g]
                                      .map((g) => DropdownMenuItem(
                                            value: g,
                                            child: Text('Grade $g'),
                                          ))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedGrade = val),
                                  validator: (val) =>
                                      val == null ? 'Select grade' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedAreaCode,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                    labelText: 'Area',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: [
                                    for (final area in kAreaOptions)
                                      DropdownMenuItem(
                                        value: area.code,
                                        child: Text(area.name,
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _selectedAreaCode = val),
                                  validator: (val) =>
                                      (val == null || val.isEmpty)
                                          ? 'Select area'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Price and Max Students
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Price (Rs.)',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter price';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _maxStudentsController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Max Students',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter max students';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          // Date/Time removed; sessions will define schedules

                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Brief description of the class...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => _createOrUpdateClass(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Update Class' : 'Create Class',
                    style: const TextStyle(
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
    );
  }

  // Date/Time selection removed (sessions will handle schedules)

  Future<void> _createOrUpdateClass() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = {
      'tutorId': user.uid,
      'name': _classNameController.text.trim(),
      'subject_code': _selectedSubjectCode,
      'type': _selectedType,
      'mode': _selectedMode,
      'grade': _selectedGrade,
      'area_code': _selectedAreaCode,
      'price': int.tryParse(_priceController.text.trim()) ?? 0,
      'max_students': int.tryParse(_maxStudentsController.text.trim()) ?? 0,
      'description': _descriptionController.text.trim(),
      'status': 'draft',
      'enrolled_count': 0,
      'total_income': 0,
      'created_at': FieldValue.serverTimestamp(),
    };
    try {
      if (widget.classId == null) {
        await FirebaseFirestore.instance.collection('classes').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .update(data);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.classId == null
                ? 'Class created successfully'
                : 'Class updated successfully')),
      );
      context.go('/tutor/classes');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create class: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _loadExistingClass() async {
    setState(() => _isLoadingExisting = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .get();
      if (!doc.exists) return;
      final data = doc.data() as Map<String, dynamic>;
      _classNameController.text = data['name'] ?? '';
      _selectedSubjectCode = data['subject_code'];
      _selectedType = data['type'] ?? _selectedType;
      _selectedMode = data['mode'] ?? _selectedMode;
      _selectedGrade = (data['grade'] as num?)?.toInt();
      _selectedAreaCode = data['area_code'];
      _priceController.text = (data['price']?.toString() ?? '');
      _maxStudentsController.text = (data['max_students']?.toString() ?? '');
      _descriptionController.text = data['description'] ?? '';
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }
}
