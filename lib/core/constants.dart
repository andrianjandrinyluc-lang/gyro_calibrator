class AppConstants {
  AppConstants._();

  static const int targetSampleRate = 100;
  static const double samplePeriod = 1.0 / targetSampleRate;
  static const double fovHorizontal = 1.2;
  static const double fovVertical = 0.68;

  // Seuils de diagnostic
  static const double rmseProThreshold = 15.0;
  static const double overshootHighRatio = 0.6;
  static const double undershootHighRatio = 0.5;
  static const double noiseHighThreshold = 0.04;

  // Facteurs de correction
  static const double overshootCorrectionFactor = 0.85;
  static const double undershootCorrectionFactor = 1.15;
  static const double noiseCorrectionFactor = 0.90;

  // Durées d'exercice
  static const int trackingDuration = 15;
}