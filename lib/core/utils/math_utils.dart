import 'dart:math';

class MathUtils {
  MathUtils._();

  static double integrateAngularVelocity(
    double previousVelocity,
    double currentVelocity,
    double deltaTimeSeconds,
  ) {
    return (previousVelocity + currentVelocity) / 2.0 * deltaTimeSeconds;
  }

  static double angleToPixels(
    double angleRadians,
    double fovRadians,
    double screenDimension,
  ) {
    return (angleRadians / fovRadians + 0.5) * screenDimension;
  }

  static double rmse(List<double> errors) {
    if (errors.isEmpty) return 0.0;
    final sumSquares = errors.fold<double>(0, (sum, e) => sum + e * e);
    return sqrt(sumSquares / errors.length);
  }

  static double mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double standardDeviation(List<double> values) {
    if (values.length < 2) return 0.0;
    final m = mean(values);
    final variance = values.fold<double>(0, (sum, v) => sum + pow(v - m, 2)) /
        (values.length - 1);
    return sqrt(variance);
  }
}