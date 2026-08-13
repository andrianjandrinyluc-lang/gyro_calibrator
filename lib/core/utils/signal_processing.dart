import 'dart:collection';
import 'dart:math';

class SignalProcessing {
  SignalProcessing._();

  static double ewmaFilter(
    double currentValue,
    double previousFiltered,
    double alpha,
  ) {
    return alpha * currentValue + (1 - alpha) * previousFiltered;
  }

  static double estimateNoiseLevel(List<double> signal, double alpha) {
    if (signal.length < 2) return 0.0;
    final residuals = <double>[];
    double filtered = signal.first;
    for (int i = 1; i < signal.length; i++) {
      filtered = ewmaFilter(signal[i], filtered, alpha);
      residuals.add(signal[i] - filtered);
    }
    if (residuals.isEmpty) return 0.0;
    final meanVal =
        residuals.reduce((a, b) => a + b) / residuals.length;
    final variance =
        residuals.map((r) => pow(r - meanVal, 2)).reduce((a, b) => a + b) /
            residuals.length;
    return sqrt(variance);
  }
}