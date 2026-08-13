/// Modèle immuable représentant un échantillon du gyroscope.
class GyroSample {
  final double x; // rotation verticale (rad/s)
  final double y; // rotation horizontale (rad/s)
  final double z; // roulis (ignoré)
  final int timestamp;

  const GyroSample({
    required this.x,
    required this.y,
    required this.z,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'z': z,
        'timestamp': timestamp,
      };

  factory GyroSample.fromJson(Map<String, dynamic> json) => GyroSample(
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        z: (json['z'] as num).toDouble(),
        timestamp: (json['timestamp'] as num).toInt(),
      );
}