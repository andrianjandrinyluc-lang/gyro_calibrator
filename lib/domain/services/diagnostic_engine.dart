import 'dart:math';
import '../../core/constants.dart';
import '../../core/utils/math_utils.dart';
import '../../core/utils/signal_processing.dart';
import '../entities/sensitivity_profile.dart';

class DiagnosticEngine {
  TrackingAnalysis analyzeTracking({
    required List<double> reticulePositionsX,
    required List<double> reticulePositionsY,
    required List<double> targetPositionsX,
    required List<double> targetPositionsY,
  }) {
    final errorsX = <double>[];
    final errorsY = <double>[];

    for (int i = 0; i < reticulePositionsX.length; i++) {
      errorsX.add((targetPositionsX[i] - reticulePositionsX[i]).abs());
      errorsY.add((targetPositionsY[i] - reticulePositionsY[i]).abs());
    }

    return TrackingAnalysis(
      rmseX: MathUtils.rmse(errorsX),
      rmseY: MathUtils.rmse(errorsY),
      meanErrorX: MathUtils.mean(errorsX),
      meanErrorY: MathUtils.mean(errorsY),
    );
  }

  FlickAnalysis analyzeFlick({
    required List<double> reticulePositionsX,
    required List<double> targetPositionsX,
    required List<double> reticulePositionsY,
    required List<double> targetPositionsY,
  }) {
    int overshootCount = 0;
    int undershootCount = 0;
    int perfectCount = 0;
    final flickErrors = <double>[];
    int lastTargetIdx = 0;

    for (int i = 1; i < targetPositionsX.length; i++) {
      if ((targetPositionsX[i] - targetPositionsX[lastTargetIdx]).abs() > 50 ||
          (targetPositionsY[i] - targetPositionsY[lastTargetIdx]).abs() > 50) {
        final errorX =
            (targetPositionsX[i] - reticulePositionsX[i]).abs();
        flickErrors.add(errorX);

        const tolerance = 10.0;
        if (reticulePositionsX[i] > targetPositionsX[i] + tolerance) {
          overshootCount++;
        } else if (reticulePositionsX[i] <
            targetPositionsX[i] - tolerance) {
          undershootCount++;
        } else {
          perfectCount++;
        }
        lastTargetIdx = i;
      }
    }

    final totalFlicks = overshootCount + undershootCount + perfectCount;

    return FlickAnalysis(
      overshootRatio: totalFlicks > 0 ? overshootCount / totalFlicks : 0.0,
      undershootRatio: totalFlicks > 0 ? undershootCount / totalFlicks : 0.0,
      perfectRatio: totalFlicks > 0 ? perfectCount / totalFlicks : 0.0,
      averageFlickError:
          flickErrors.isEmpty ? 0.0 : MathUtils.mean(flickErrors),
      totalFlicks: totalFlicks,
    );
  }

  StabilityAnalysis analyzeStability(List<double> gyroSamplesX) {
    final noiseLevel =
        SignalProcessing.estimateNoiseLevel(gyroSamplesX, 0.1);
    final stdDev = MathUtils.standardDeviation(gyroSamplesX);

    return StabilityAnalysis(
      noiseLevelRadPerS: noiseLevel,
      standardDeviationRadPerS: stdDev,
      stabilityScore: (100 - (noiseLevel / 0.1) * 100).clamp(0.0, 100.0),
    );
  }

  CalibrationProfile generateProfile({
    required double baseSensitivity,
    required TrackingAnalysis tracking,
    required FlickAnalysis flick,
    required StabilityAnalysis stability,
  }) {
    double recommendedBaseSens = baseSensitivity;
    final reasons = <String>[];

    if (flick.overshootRatio > AppConstants.overshootHighRatio) {
      recommendedBaseSens *= AppConstants.overshootCorrectionFactor;
      reasons.add(
        "Overshoot détecté sur ${(flick.overshootRatio * 100).toStringAsFixed(0)}% des tirs.",
      );
    }

    if (flick.undershootRatio > AppConstants.undershootHighRatio) {
      recommendedBaseSens *= AppConstants.undershootCorrectionFactor;
      reasons.add(
        "Undershoot détecté sur ${(flick.undershootRatio * 100).toStringAsFixed(0)}% des tirs.",
      );
    }

    final isNoisy =
        stability.noiseLevelRadPerS > AppConstants.noiseHighThreshold;
    if (isNoisy) {
      reasons.add("Tremblements détectés. Sensibilité réduite sur forts zooms.");
    }

    if (tracking.rmseY > tracking.rmseX * 1.5) {
      reasons.add("Précision verticale plus faible. Vérifiez votre prise en main.");
    }

    final avgRmse = (tracking.rmseX + tracking.rmseY) / 2;
    String level;
    if (avgRmse < AppConstants.rmseProThreshold) {
      level = "Compétiteur Pro";
    } else if (avgRmse < 30) {
      level = "Avancé";
    } else if (avgRmse < 50) {
      level = "Intermédiaire";
    } else {
      level = "Débutant";
    }

    final noiseFactor = isNoisy ? 0.85 : 1.0;
    final perScope = {
      'no_scope': recommendedBaseSens,
      'red_dot': recommendedBaseSens * 0.95,
      '2x': recommendedBaseSens * 0.85,
      '3x': recommendedBaseSens * 0.75 * noiseFactor,
      '4x': recommendedBaseSens * 0.65 * noiseFactor,
      '6x': recommendedBaseSens * 0.50 * noiseFactor * noiseFactor,
      '8x': recommendedBaseSens * 0.35 * noiseFactor * noiseFactor,
    };

    return CalibrationProfile(
      baseSensitivity: recommendedBaseSens,
      perScope: perScope,
      level: level,
      reasons: reasons,
      stabilityScore: stability.stabilityScore,
      averageRmse: avgRmse,
    );
  }
}

class TrackingAnalysis {
  final double rmseX;
  final double rmseY;
  final double meanErrorX;
  final double meanErrorY;

  const TrackingAnalysis({
    required this.rmseX,
    required this.rmseY,
    required this.meanErrorX,
    required this.meanErrorY,
  });
}

class FlickAnalysis {
  final double overshootRatio;
  final double undershootRatio;
  final double perfectRatio;
  final double averageFlickError;
  final int totalFlicks;

  const FlickAnalysis({
    required this.overshootRatio,
    required this.undershootRatio,
    required this.perfectRatio,
    required this.averageFlickError,
    required this.totalFlicks,
  });
}

class StabilityAnalysis {
  final double noiseLevelRadPerS;
  final double standardDeviationRadPerS;
  final double stabilityScore;

  const StabilityAnalysis({
    required this.noiseLevelRadPerS,
    required this.standardDeviationRadPerS,
    required this.stabilityScore,
  });
}