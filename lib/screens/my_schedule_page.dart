import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme.dart';

class ScheduleItem {
  ScheduleItem({
    required this.classId,
    required this.className,
    required this.start,
    this.end,
    this.label,
    this.venue,
  });

  final String classId;
  final String className;
  final DateTime start;
  final DateTime? end;
  final String? label;
  final String? venue;
}

class MySchedulePage extends StatefulWidget {
  const MySchedulePage({super.key});

  @override
  State<MySchedulePage> createState() => _MySchedulePageState();
}

class _MySchedulePageState extends State<MySchedulePage> {
  late DateTime _weekStart; // Monday as start of week

  @override
  void initState() {
    super.initState();
    _weekStart = _getWeekStart(DateTime.now());
  }

  DateTime _getWeekStart(DateTime anchor) {
    final d = DateTime(anchor.year, anchor.month, anchor.day);
    final int delta = (d.weekday - DateTime.monday) % 7;
    return d.subtract(Duration(days: delta));
  }

  DateTime get _weekEndExclusive => _weekStart.add(const Duration(days: 7));

  Future<List<ScheduleItem>> _loadWeeklySchedule() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const <ScheduleItem>[];
    }
    final startTs = Timestamp.fromDate(_weekStart);
    final endTs = Timestamp.fromDate(_weekEndExclusive);

    final enrollSnap = await FirebaseFirestore.instance
        .collection('enrollments')
        .where('studentId', isEqualTo: user.uid)
        .where('status', whereIn: ['active', 'pending']).get();

    final Set<String> classIds = <String>{};
    for (final d in enrollSnap.docs) {
      final cid = (d.data()['classId'] as String?) ?? '';
      if (cid.isNotEmpty) classIds.add(cid);
    }
    if (classIds.isEmpty) return const <ScheduleItem>[];

    final List<ScheduleItem> items = <ScheduleItem>[];

    for (final classId in classIds) {
      final classDoc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .get();
      final classData = classDoc.data() ?? <String, dynamic>{};
      final className = (classData['name'] as String?) ?? 'Class';

      final sessionsSnap = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('sessions')
          .where('start_time', isGreaterThanOrEqualTo: startTs)
          .where('start_time', isLessThan: endTs)
          .orderBy('start_time')
          .get();

      for (final s in sessionsSnap.docs) {
        final sd = s.data();
        final ts = sd['start_time'];
        DateTime? start;
        if (ts is Timestamp) start = ts.toDate();
        final te = sd['end_time'];
        DateTime? end;
        if (te is Timestamp) end = te.toDate();
        if (start == null) continue;
        items.add(ScheduleItem(
          classId: classId,
          className: className,
          start: start,
          end: end,
          label: (sd['label'] as String?),
          venue: (sd['venue'] as String?),
        ));
      }
    }

    items.sort((a, b) => a.start.compareTo(b.start));
    return items;
  }

  String _formatWeekRange(DateTime start, DateTime endExclusive) {
    final end = endExclusive.subtract(const Duration(days: 1));
    final s = _fmtDate(start);
    final e = _fmtDate(end);
    return '$s - $e';
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final day = days[(d.weekday - 1) % 7];
    final mon = months[d.month - 1];
    return '$day, $mon ${d.day}';
  }

  String _fmtTimeRange(DateTime start, DateTime? end) {
    String t(DateTime dt) {
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ap';
    }

    final s = t(start);
    final e = end != null ? t(end) : '';
    return e.isEmpty ? s : '$s - $e';
  }

  @override
  Widget build(BuildContext context) {
    final days =
        List<DateTime>.generate(7, (i) => _weekStart.add(Duration(days: i)));

    return Scaffold(
      backgroundColor: AppTheme.brandSurface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.brandText),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/profile');
            }
          },
        ),
        title: const Text(
          'My Schedule',
          style: TextStyle(color: AppTheme.brandText),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _weekStart =
                      _weekStart.subtract(const Duration(days: 7))),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      _formatWeekRange(_weekStart, _weekEndExclusive),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brandText,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() =>
                      _weekStart = _weekStart.add(const Duration(days: 7))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<ScheduleItem>>(
              future: _loadWeeklySchedule(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snapshot.data ?? const <ScheduleItem>[];

                final Map<String, List<ScheduleItem>> byDay =
                    <String, List<ScheduleItem>>{};
                for (final it in items) {
                  final key =
                      DateTime(it.start.year, it.start.month, it.start.day)
                          .toIso8601String();
                  byDay.putIfAbsent(key, () => <ScheduleItem>[]).add(it);
                }

                if (items.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          const Text(
                            'No sessions this week',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brandText,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enroll in classes or check another week.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final key = DateTime(day.year, day.month, day.day)
                        .toIso8601String();
                    final dayItems = List<ScheduleItem>.of(
                        byDay[key] ?? const <ScheduleItem>[]);
                    dayItems.sort((a, b) => a.start.compareTo(b.start));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            _fmtDate(day),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.brandText,
                            ),
                          ),
                        ),
                        if (dayItems.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'No sessions',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: dayItems.map((it) {
                              return Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  onTap: () =>
                                      context.push('/class/${it.classId}'),
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.brandPrimary
                                          .withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _fmtTimeRange(it.start, it.end),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.brandPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  title: Text(
                                    it.className,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Row(
                                    children: [
                                      if ((it.label ?? '').isNotEmpty) ...[
                                        const Icon(
                                            Icons.label_important_outline,
                                            size: 14,
                                            color: AppTheme.mutedText),
                                        const SizedBox(width: 4),
                                        Text(
                                          it.label!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.mutedText),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      if ((it.venue ?? '').isNotEmpty) ...[
                                        const Icon(Icons.place,
                                            size: 14,
                                            color: AppTheme.mutedText),
                                        const SizedBox(width: 4),
                                        Text(
                                          it.venue!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.mutedText),
                                        ),
                                      ],
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
