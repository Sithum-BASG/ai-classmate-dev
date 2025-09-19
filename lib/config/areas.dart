class AreaOption {
  const AreaOption({required this.code, required this.name});
  final String code;
  final String name;
  @override
  String toString() => '$name ($code)';
}

// Canonical list of areas (no CSV, hardcoded)
const List<AreaOption> kAreaOptions = [
  AreaOption(code: 'CMB-01', name: 'Colombo 01 - Fort'),
  AreaOption(code: 'CMB-03', name: 'Colombo 03 - Kollupitiya'),
  AreaOption(code: 'CMB-04', name: 'Colombo 04 - Bambalapitiya'),
  AreaOption(code: 'CMB-05', name: 'Colombo 05 - Havelock'),
  AreaOption(code: 'CMB-06', name: 'Colombo 06 - Wellawatte'),
  AreaOption(code: 'CMB-07', name: 'Colombo 07 - Cinnamon Gardens'),
  AreaOption(code: 'CMB-08', name: 'Colombo 08 - Borella'),
  AreaOption(code: 'CMB-10', name: 'Colombo 10 - Maradana'),
  AreaOption(code: 'CMB-11', name: 'Colombo 11 - Pettah'),
  AreaOption(code: 'DEH-01', name: 'Dehiwala'),
  AreaOption(code: 'MTL-01', name: 'Mount Lavinia'),
  AreaOption(code: 'NUG-01', name: 'Nugegoda'),
  AreaOption(code: 'KOT-01', name: 'Sri Jayawardenepura Kotte'),
  AreaOption(code: 'RAJ-01', name: 'Rajagiriya'),
  AreaOption(code: 'BAT-01', name: 'Battaramulla'),
  AreaOption(code: 'MAL-01', name: 'Malabe'),
  AreaOption(code: 'MAH-01', name: 'Maharagama'),
  AreaOption(code: 'HOM-01', name: 'Homagama'),
];

class AreasRepository {
  AreasRepository._();
  static Future<List<AreaOption>> loadAreas() async {
    // Return hardcoded list immediately
    return kAreaOptions;
  }
}
