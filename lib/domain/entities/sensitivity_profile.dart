class CalibrationProfile {
  final String id;
  final DateTime createdAt;
  final double baseSensitivity;
  final Map<String, double> perScope;
  final String level;
  final List<String> reasons;
  final double stabilityScore;
  final double averageRmse;

  CalibrationProfile({
    String? id,
    DateTime? createdAt,
    required this.baseSensitivity,
    required this.perScope,
    required this.level,
    required this.reasons,
    required this.stabilityScore,
    required this.averageRmse,
  })  : id = id ??
            DateTime.now().millisecondsSinceEpoch.toRadixString(36),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'baseSensitivity': baseSensitivity,
        'perScope': perScope,
        'level': level,
        'reasons': reasons,
        'stabilityScore': stabilityScore,
        'averageRmse': averageRmse,
      };
}