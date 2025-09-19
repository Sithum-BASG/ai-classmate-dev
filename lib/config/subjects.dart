class SubjectOption {
  const SubjectOption({required this.code, required this.label});
  final String code;
  final String label;
}

// Minimal subject list; extend later to full coverage.
const List<SubjectOption> kSubjectOptions = [
  SubjectOption(code: 'OL_MATH', label: 'Mathematics (O/L)'),
  SubjectOption(code: 'OL_SCI', label: 'Science (O/L)'),
  SubjectOption(code: 'OL_ENG', label: 'English (O/L)'),
  SubjectOption(code: 'OL_SIN', label: 'Sinhala (O/L)'),
  SubjectOption(code: 'OL_TAM', label: 'Tamil (O/L)'),
  SubjectOption(code: 'OL_ICT', label: 'ICT (O/L)'),
  SubjectOption(code: 'AL_MATH', label: 'Combined Mathematics (A/L)'),
  SubjectOption(code: 'AL_PHYS', label: 'Physics (A/L)'),
  SubjectOption(code: 'AL_CHEM', label: 'Chemistry (A/L)'),
  SubjectOption(code: 'AL_BIO', label: 'Biology (A/L)'),
  SubjectOption(code: 'AL_ECON', label: 'Economics (A/L)'),
  SubjectOption(code: 'AL_ACC', label: 'Accounting (A/L)'),
  SubjectOption(code: 'AL_ICT', label: 'ICT (A/L)'),
];
