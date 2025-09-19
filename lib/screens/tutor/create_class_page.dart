import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  final _classNumberController = TextEditingController();
  final _subjectController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxStudentsController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedType = 'Group';
  String _selectedMode = 'In-person';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  List<String> _selectedStudentIds = [];

  final List<Map<String, dynamic>> _availableStudents = [
    {'id': '1', 'name': 'John Silva', 'grade': 'Grade 13', 'status': 'active'},
    {
      'id': '2',
      'name': 'Sarah Fernando',
      'grade': 'Grade 12',
      'status': 'active'
    },
    {'id': '3', 'name': 'Mike Perera', 'grade': 'Grade 13', 'status': 'active'},
    {
      'id': '4',
      'name': 'Lisa Gunasekera',
      'grade': 'Grade 13',
      'status': 'active'
    },
    {'id': '5', 'name': 'David Kumar', 'grade': 'Grade 12', 'status': 'active'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.classId != null) {
      // Load existing class data for editing
      _classNumberController.text = widget.classId!;
    } else {
      // Generate new class number
      _classNumberController.text =
          '11'; // This should be generated dynamically
    }
  }

  @override
  void dispose() {
    _classNumberController.dispose();
    _subjectController.dispose();
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
        title: Text(isEditing
            ? 'Edit Class ${widget.classId}'
            : 'Create Class ${_classNumberController.text}'),
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
                child: Column(
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

                    // Class Number (Read-only)
                    TextFormField(
                      controller: _classNumberController,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Class Number',
                        prefixText: 'Class ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subject
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        hintText: 'e.g., Physics A/L',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter subject';
                        }
                        return null;
                      },
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
                            items: ['Group', 'Individual', 'Online']
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
                    const SizedBox(height: 16),

                    // Date and Time
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'mm/dd/yyyy'
                                    : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectTime(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Time',
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _selectedTime == null
                                    ? '--:-- --'
                                    : _selectedTime!.format(context),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

              // Add Students Card
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
                      'Add Students to Class',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._availableStudents.map((student) {
                      final isSelected =
                          _selectedStudentIds.contains(student['id']);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedStudentIds.add(student['id']);
                            } else {
                              _selectedStudentIds.remove(student['id']);
                            }
                          });
                        },
                        title: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor:
                                  AppTheme.brandPrimary.withValues(alpha: 0.1),
                              child: Text(
                                student['name']
                                    .split(' ')
                                    .map((e) => e[0])
                                    .take(2)
                                    .join(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.brandPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  student['name'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  student['grade'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'active',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _createClass,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandText,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isEditing
                        ? 'Update Class ${widget.classId}'
                        : 'Create Class ${_classNumberController.text}',
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _createClass() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save class to Firebase
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.classId != null
              ? 'Class updated successfully'
              : 'Class created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/tutor/classes');
    }
  }
}
