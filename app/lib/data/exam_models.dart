/// An exam row from `public.exams`.
class Exam {
  const Exam({
    required this.id,
    required this.nameHi,
    required this.nameEn,
    required this.dataVersion,
  });

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
    id: json['id'] as String,
    nameHi: json['name_hi'] as String,
    nameEn: json['name_en'] as String,
    dataVersion: json['data_version'] as String,
  );

  final String id;
  final String nameHi;
  final String nameEn;
  final String dataVersion;

  String nameFor(String languageCode) => languageCode == 'hi' ? nameHi : nameEn;
}

/// One physical standard from `public.standards`. The same keys are used in
/// data/exams/*.json, so both parse with [Standard.fromJson].
class Standard {
  const Standard({
    required this.gender,
    required this.category,
    required this.event,
    required this.kind,
    required this.value,
    required this.sourceUrl,
    required this.verified,
  });

  factory Standard.fromJson(Map<String, dynamic> json) => Standard(
    gender: json['gender'] as String,
    category: json['category'] as String,
    event: json['event'] as String,
    kind: json['kind'] as String,
    value: (json['value'] as num?)?.toDouble(),
    sourceUrl: json['source_url'] as String?,
    verified: json['verified'] as bool? ?? false,
  );

  final String gender;
  final String category;
  final String event;
  final String kind;
  final double? value;
  final String? sourceUrl;
  final bool verified;

  /// Only values read from an official notice may be shown as real standards.
  bool get isConfirmed => verified && value != null && sourceUrl != null;

  bool get isRun => event.startsWith('run_');

  /// Run distance in metres, from an event like `run_4800m`.
  int? get runMetres =>
      isRun ? int.tryParse(event.substring(4, event.length - 1)) : null;
}
