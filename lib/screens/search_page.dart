import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../theme.dart';
import '../config/subjects.dart';
import '../config/areas.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedMode = 'All'; // Online | In-person | Hybrid | All
  String _selectedType = 'All'; // Group | Individual | All
  final Set<String> _selectedSubjectCodes = <String>{};
  bool _useMyArea = false;
  bool _useMyPreferences = false;
  bool _isStudent = false;
  Map<String, num> _recScores = const {};
  String? _lastDocsKey;
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _lastSorted;

  int? _studentGrade;
  String? _studentAreaCode;
  List<String> _studentSubjects = const [];
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
    _loadAuthRole();
  }

  Future<void> _loadStudentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loadingProfile = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('student_profiles')
          .doc(user.uid)
          .get();
      final data = snap.data() ?? {};
      setState(() {
        _studentGrade = (data['grade'] as num?)?.toInt();
        _studentAreaCode = data['area_code'] as String?;
        _studentSubjects =
            (data['subjects_of_interest'] as List?)?.cast<String>() ?? [];
        _loadingProfile = false;
      });
    } catch (_) {
      setState(() => _loadingProfile = false);
    }
  }

  Future<void> _loadAuthRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isStudent = false);
      return;
    }
    try {
      final token = await user.getIdTokenResult(true);
      final role = token.claims?['role'] as String?;
      setState(() => _isStudent = role == 'student');
    } catch (_) {
      setState(() => _isStudent = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<Set<String>> _enrolledClassIdsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream<Set<String>>.value(<String>{});
    return FirebaseFirestore.instance
        .collection('enrollments')
        .where('studentId', isEqualTo: uid)
        .where('status', whereIn: ['active', 'pending'])
        .snapshots()
        .map((q) => q.docs
            .map((d) => (d.data()['classId'] as String?) ?? '')
            .where((id) => id.isNotEmpty)
            .toSet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/student'),
        ),
        title: const Text('Find Classes'),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search class name or subject...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: _showFilterBottomSheet,
                    ),
                    filled: true,
                    fillColor: AppTheme.brandSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildModeChip('All', _selectedMode == 'All'),
                      const SizedBox(width: 8),
                      _buildModeChip('Online', _selectedMode == 'Online'),
                      const SizedBox(width: 8),
                      _buildModeChip('In-person', _selectedMode == 'In-person'),
                      const SizedBox(width: 8),
                      _buildModeChip('Hybrid', _selectedMode == 'Hybrid'),
                      const SizedBox(width: 8),
                      _buildTypeChip('All', _selectedType == 'All'),
                      const SizedBox(width: 8),
                      _buildTypeChip('Group', _selectedType == 'Group'),
                      const SizedBox(width: 8),
                      _buildTypeChip(
                          'Individual', _selectedType == 'Individual'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Classes List
          Expanded(
            child: _loadingProfile
                ? const Center(child: CircularProgressIndicator())
                : _buildClassList(),
          ),
        ],
      ),
    );
  }

  Widget _buildClassList() {
    return StreamBuilder<Set<String>>(
      stream: _enrolledClassIdsStream(),
      builder: (context, enrSnap) {
        final enrolledIds = enrSnap.data ?? <String>{};
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _classesQuery().snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }
            var docs = snapshot.data?.docs ?? [];
            // Client-side filters: subject multiselect, search text
            final text = _searchController.text.trim().toLowerCase();
            docs = docs.where((d) {
              final data = d.data();
              final name = (data['name'] as String?)?.toLowerCase() ?? '';
              final subject = (data['subject_code'] as String?) ?? '';
              final matchesText = text.isEmpty || name.contains(text);
              final subjectOk = _selectedSubjectCodes.isEmpty ||
                  _selectedSubjectCodes.contains(subject);
              final notEnrolled = !enrolledIds.contains(d.id);
              return matchesText && subjectOk && notEnrolled;
            }).toList();
            if (docs.isEmpty) {
              return const Center(child: Text('No classes found.'));
            }
            final docsKey = docs.map((d) => d.id).join(',');
            if (_lastDocsKey == docsKey && _lastSorted != null) {
              final sortedDocs = _lastSorted!;
              return _buildSortedList(sortedDocs);
            }
            return FutureBuilder<
                List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              future:
                  _sortByRecommendations(docs.map((d) => d.id).toList(), docs),
              builder: (context, sortedSnap) {
                final sortedDocs = sortedSnap.data ?? docs;
                return _buildSortedList(sortedDocs);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSortedList(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> sortedDocs) {
    if (_recScores.isNotEmpty) {
      final top = sortedDocs.isNotEmpty ? sortedDocs.first.id : null;
      return Column(
        children: [
          if (top != null)
            Container(
              color: Colors.yellow.withValues(alpha: 0.2),
              padding: const EdgeInsets.all(8),
              child: Text(
                'Recs active. Top score: ${_recScores[top]?.toStringAsFixed(3) ?? '0'}',
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDocs.length,
              itemBuilder: (context, i) {
                final doc = sortedDocs[i];
                final c = doc.data();
                return _buildClassCard(doc.id, c);
              },
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDocs.length,
      itemBuilder: (context, i) {
        final doc = sortedDocs[i];
        final c = doc.data();
        return _buildClassCard(doc.id, c);
      },
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
      _sortByRecommendations(List<String> classIds,
          List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return docs;
      await user.getIdToken(true);
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('getRecommendationsRealtime');
      final res = await callable.call({
        'studentId': user.uid,
        'limit': 50,
        'debug': true,
        'classIds': classIds,
      });
      final data = (res.data as Map?)?.cast<String, dynamic>() ?? {};
      // Prefer results; some versions return under data.results
      final raw = (data['results'] as List?) ?? (data['data'] as List?) ?? [];
      final results = raw
          .map((e) => (e as Map).cast<String, dynamic>())
          .map((m) => {
                'class_id': m['classId'] ?? m['class_id'],
                'score': m['score'] ??
                    m['predicted_probability'] ??
                    m['predicted_value'] ??
                    m['value'] ??
                    0
              })
          .toList();
      // Build score map for classId
      final Map<String, num> scoreById = {
        for (final r in results)
          (r['class_id']?.toString() ?? ''): (r['score'] as num? ?? 0)
      };
      if (mounted) setState(() => _recScores = scoreById);
      // For classes not in results, score 0; keep stable order by created_at if tie
      final withOriginalIndex = [for (int i = 0; i < docs.length; i++) i];
      withOriginalIndex.sort((a, b) {
        final ca = docs[a];
        final cb = docs[b];
        final sa = scoreById[ca.id] ?? 0;
        final sb = scoreById[cb.id] ?? 0;
        if (sa != sb) return sb.compareTo(sa);
        // fallback to created_at desc if available
        final ta = (ca.data()['created_at'] as Timestamp?);
        final tb = (cb.data()['created_at'] as Timestamp?);
        if (ta != null && tb != null) return tb.compareTo(ta);
        return a.compareTo(b);
      });
      final sorted = withOriginalIndex.map((i) => docs[i]).toList();
      // Cache to prevent blinking while FutureBuilder resolves repeatedly
      _lastDocsKey = docs.map((d) => d.id).join(',');
      _lastSorted = sorted;
      return sorted;
    } catch (_) {
      return docs; // fail open
    }
  }

  Query<Map<String, dynamic>> _classesQuery() {
    final coll = FirebaseFirestore.instance.collection('classes');
    Query<Map<String, dynamic>> q =
        coll.where('status', isEqualTo: 'published');
    if (_studentGrade != null) {
      q = q.where('grade', isEqualTo: _studentGrade);
    }
    if (_useMyArea &&
        _studentAreaCode != null &&
        _studentAreaCode!.isNotEmpty) {
      q = q.where('area_code', isEqualTo: _studentAreaCode);
    }
    if (_selectedMode != 'All') {
      q = q.where('mode', isEqualTo: _selectedMode);
    }
    if (_selectedType != 'All') {
      q = q.where('type', isEqualTo: _selectedType);
    }
    // If exactly one subject selected, push down to Firestore; otherwise filter client-side
    if (_selectedSubjectCodes.length == 1) {
      q = q.where('subject_code', isEqualTo: _selectedSubjectCodes.first);
    } else if (_useMyPreferences &&
        _selectedSubjectCodes.isEmpty &&
        _studentSubjects.isNotEmpty) {
      // If using preferences and no manual selection, use first preferred subject to index
      q = q.where('subject_code', isEqualTo: _studentSubjects.first);
    }
    return q.orderBy('created_at', descending: true);
  }

  Widget _buildModeChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandPrimary : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.brandPrimary : AppTheme.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.brandText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.brandSecondary : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.brandSecondary : AppTheme.borderSubtle,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.brandText,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildClassCard(String classId, Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book,
                  size: 36, color: AppTheme.brandPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((c['tutorId'] as String?) != null &&
                        (c['tutorId'] as String).isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: AppTheme.brandPrimary),
                          const SizedBox(width: 6),
                          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            future: FirebaseFirestore.instance
                                .collection('tutor_profiles')
                                .doc(c['tutorId'] as String)
                                .get(),
                            builder: (context, snap) {
                              final data =
                                  snap.data?.data() ?? <String, dynamic>{};
                              final tn =
                                  (data['full_name'] as String?) ?? 'Tutor';
                              return Text(
                                'Tutor: $tn',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.brandPrimary,
                                    ),
                              );
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Text(
                      (c['name'] as String?) ?? 'Class',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subjectName(c['subject_code'] as String?),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _chip((c['type'] as String?) ?? 'Group',
                            _typeColor((c['type'] as String?) ?? 'Group')),
                        const SizedBox(width: 6),
                        _chip(
                            (c['mode'] as String?) ?? 'In-person', Colors.grey),
                      ],
                    ),
                  ],
                ),
              ),
              Text('LKR ${(c['price'] as num?)?.toInt() ?? 0}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.brandPrimary,
                        fontWeight: FontWeight.w700,
                      )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.place, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(_areaName(c['area_code'] as String?)),
              const SizedBox(width: 12),
              Icon(Icons.school, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text('Grade ${(c['grade'] as num?)?.toInt() ?? 0}'),
              const Spacer(),
              if (_recScores.containsKey(classId))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Score ${(_recScores[classId] as num).toDouble().toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: Colors.purple),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                ((c['description'] as String?) ?? '').trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              OutlinedButton(
                onPressed: () => context.push('/class/$classId'),
                child: const Text('View Details'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isStudent
                    ? () => _confirmEnroll(
                        classId, (c['name'] as String?) ?? 'this class')
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Enroll'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, modalSetState) {
          void updateBoth(VoidCallback fn) {
            modalSetState(fn);
            setState(() {});
          }

          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.9,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter Classes',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('Subjects'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: kSubjectOptions.take(12).map((s) {
                        final selected = _selectedSubjectCodes.contains(s.code);
                        return FilterChip(
                          label: Text(s.label),
                          selected: selected,
                          onSelected: (val) {
                            updateBoth(() {
                              if (val) {
                                _selectedSubjectCodes.add(s.code);
                              } else {
                                _selectedSubjectCodes.remove(s.code);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    CheckboxListTile(
                      value: _useMyArea,
                      onChanged: (v) =>
                          updateBoth(() => _useMyArea = v ?? false),
                      title: const Text('Show only classes in my area'),
                      subtitle: Text(_studentAreaCode == null
                          ? 'Area not set'
                          : _areaName(_studentAreaCode)),
                    ),
                    CheckboxListTile(
                      value: _useMyPreferences,
                      onChanged: (v) =>
                          updateBoth(() => _useMyPreferences = v ?? true),
                      title: const Text('Prefer my subjects of interest'),
                      subtitle: Text(_studentSubjects.isEmpty
                          ? 'No preferences set'
                          : _studentSubjects.map(_subjectName).join(', ')),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Center(child: Text('Close')),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  String _subjectName(String? code) {
    if (code == null) return 'Subject';
    final match = kSubjectOptions.firstWhere(
      (s) => s.code == code,
      orElse: () => SubjectOption(code: code, label: code),
    );
    return match.label;
  }

  String _areaName(String? code) {
    if (code == null) return 'Any area';
    final match = kAreaOptions.firstWhere(
      (a) => a.code == code,
      orElse: () => AreaOption(code: code, name: code),
    );
    return match.name;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Group':
        return Colors.blue;
      case 'Individual':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Future<void> _confirmEnroll(String classId, String className) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enroll in Class'),
        content: Text('Do you want to enroll in "$className"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      final callable = FirebaseFunctions.instanceFor(region: 'asia-south1')
          .httpsCallable('enrollInClass');
      await callable.call({'classId': classId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enrolled successfully')),
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final msg = '[${e.code}] ${e.message ?? e.details ?? e.toString()}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enroll: $msg')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to enroll: $e')),
      );
    }
  }
}
