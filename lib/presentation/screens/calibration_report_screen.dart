import 'package:flutter/material.dart';
import '../../domain/services/diagnostic_engine.dart';

class CalibrationReportScreen extends StatelessWidget {
  final List<double> reticuleX;
  final List<double> reticuleY;
  final List<double> targetX;
  final List<double> targetY;
  final List<double> timestamps;
  final Map<String, double> currentSensitivities;
  final String exerciseType;

  const CalibrationReportScreen({
    super.key,
    required this.reticuleX,
    required this.reticuleY,
    required this.targetX,
    required this.targetY,
    required this.timestamps,
    required this.currentSensitivities,
    this.exerciseType = 'tracking',
  });

  String get _exerciseLabel {
    switch (exerciseType) {
      case 'flick':
        return 'Flick';
      case 'stability':
        return 'Stabilité';
      default:
        return 'Tracking';
    }
  }

  @override
  Widget build(BuildContext context) {
    final engine = DiagnosticEngine();

    final tracking = engine.analyzeTracking(
      reticulePositionsX: reticuleX,
      reticulePositionsY: reticuleY,
      targetPositionsX: targetX,
      targetPositionsY: targetY,
    );

    final flick = engine.analyzeFlick(
      reticulePositionsX: reticuleX,
      targetPositionsX: targetX,
      reticulePositionsY: reticuleY,
      targetPositionsY: targetY,
    );

    final gyroSamplesX = reticuleX.map((x) => x / 1000).toList();
    final stability = engine.analyzeStability(gyroSamplesX);

    final profile = engine.generateProfile(
      baseSensitivity: currentSensitivities['no_scope'] ?? 200.0,
      tracking: tracking,
      flick: flick,
      stability: stability,
    );

    final ratio =
        profile.baseSensitivity / (currentSensitivities['no_scope'] ?? 200.0);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text('Rapport — $_exerciseLabel'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLevelCard(profile),
            const SizedBox(height: 12),
            Text(
              'Test : $_exerciseLabel — Valeurs pour Gyroscope → ADS (visée sans tir).',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            if (exerciseType == 'flick') _buildFlickStats(flick),
            if (exerciseType == 'stability')
              _buildStabilityStats(stability),
            _buildScoreCards(tracking, stability, profile),
            const SizedBox(height: 16),
            _buildSensitivityTable(profile, ratio),
            const SizedBox(height: 16),
            _buildReasons(profile),
          ],
        ),
      ),
    );
  }

  Widget _buildFlickStats(dynamic flick) {
    return Card(
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Statistiques de Flick',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statColumn('Parfaits', '${(flick.perfectRatio * 100).toInt()}%',
                    Colors.green),
                _statColumn(
                    'Overshoot', '${(flick.overshootRatio * 100).toInt()}%', Colors.red),
                _statColumn('Undershoot',
                    '${(flick.undershootRatio * 100).toInt()}%', Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStabilityStats(dynamic stability) {
    return Card(
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Statistiques de Stabilité',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Bruit : ${stability.noiseLevelRadPerS.toStringAsFixed(4)} rad/s',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            Text(
              'Score : ${stability.stabilityScore.toStringAsFixed(0)}/100',
              style: TextStyle(
                  color: stability.stabilityScore > 70
                      ? Colors.green
                      : Colors.orange,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildLevelCard(dynamic profile) {
    final levelColors = {
      'Compétiteur Pro': Colors.amber,
      'Avancé': Colors.blue,
      'Intermédiaire': Colors.green,
      'Débutant': Colors.grey,
    };

    return Card(
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.emoji_events,
                color: levelColors[profile.level] ?? Colors.white, size: 48),
            const SizedBox(height: 8),
            Text(profile.level,
                style: TextStyle(
                    color: levelColors[profile.level] ?? Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('RMSE: ${profile.averageRmse.toStringAsFixed(1)} px',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
            Text(
                'Stabilité: ${profile.stabilityScore.toStringAsFixed(0)}/100',
                style: const TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCards(
      dynamic tracking, dynamic stability, dynamic profile) {
    return Row(
      children: [
        Expanded(
          child: _scoreCard('Précision X',
              '${tracking.rmseX.toStringAsFixed(1)} px', Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _scoreCard('Précision Y',
              '${tracking.rmseY.toStringAsFixed(1)} px', Colors.cyan),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _scoreCard('Stabilité',
              '${stability.stabilityScore.toStringAsFixed(0)}%', Colors.green),
        ),
      ],
    );
  }

  Widget _scoreCard(String title, String value, Color color) {
    return Card(
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSensitivityTable(dynamic profile, double ratio) {
    final labels = {
      'no_scope': 'Sans viseur',
      'red_dot': 'Red Dot / Holo',
      '2x': 'Lunette x2',
      '3x': 'Lunette x3',
      '4x': 'Lunette x4',
      '6x': 'Lunette x6',
      '8x': 'Lunette x8',
    };

    return Card(
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sensibilités Recommandées (ADS)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Table(
              border: TableBorder.all(color: Colors.white24),
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1),
                2: FlexColumnWidth(1),
              },
              children: [
                const TableRow(children: [
                  Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Viseur',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold))),
                  Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Avant',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center)),
                  Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Recommandé',
                          style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center)),
                ]),
                ...labels.entries.map((entry) {
                  final key = entry.key;
                  final currentVal = currentSensitivities[key] ?? 200.0;
                  final recommendedVal = currentVal *
                      ratio *
                      (profile.perScope[key] ?? 1.0) /
                      (profile.perScope['no_scope'] ?? 1.0);

                  return TableRow(children: [
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(entry.value,
                            style: const TextStyle(color: Colors.white))),
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('${currentVal.toInt()}%',
                            style: const TextStyle(color: Colors.white54),
                            textAlign: TextAlign.center)),
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text('${recommendedVal.toInt()}%',
                            style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center)),
                  ]);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasons(dynamic profile) {
    return Card(
      color: const Color(0xFF16213E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Analyse & Recommandations',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (profile.reasons.isEmpty)
              const Text('Tout est bon ! Votre sensibilité est bien réglée.',
                  style: TextStyle(color: Colors.white70))
            else
              ...profile.reasons.map((reason) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(reason,
                                style:
                                    const TextStyle(color: Colors.white70))),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}