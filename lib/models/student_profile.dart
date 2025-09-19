class StudentProfile {
  StudentProfile({
    required this.uid,
    required this.fullName,
    required this.grade,
    required this.areaCode,
    required this.subjectCodesOfInterest,
  });

  final String uid;
  final String fullName;
  final int grade; // e.g., 6..13
  final String areaCode; // e.g., 'Colombo-01' or district code
  final List<String> subjectCodesOfInterest; // e.g., ['OL_MATH', 'AL_PHYS']

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'full_name': fullName,
      'grade': grade,
      'area_code': areaCode,
      'subjects_of_interest': subjectCodesOfInterest,
    };
  }

  static StudentProfile fromMap(String uid, Map<String, dynamic> map) {
    return StudentProfile(
      uid: uid,
      fullName: (map['full_name'] as String?) ?? '',
      grade: map['grade'] as int,
      areaCode: map['area_code'] as String,
      subjectCodesOfInterest:
          List<String>.from(map['subjects_of_interest'] ?? <String>[]),
    );
  }

  StudentProfile copyWith({
    String? uid,
    String? fullName,
    int? grade,
    String? areaCode,
    List<String>? subjectCodesOfInterest,
  }) {
    return StudentProfile(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      grade: grade ?? this.grade,
      areaCode: areaCode ?? this.areaCode,
      subjectCodesOfInterest:
          subjectCodesOfInterest ?? this.subjectCodesOfInterest,
    );
  }
}
