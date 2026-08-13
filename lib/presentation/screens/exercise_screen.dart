import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/models/gyro_sample.dart';
import '../../domain/services/gyroscope_service.dart';
import '../widgets/aim_simulator.dart';

enum ExerciseType { tracking, flick, stability }

class ExerciseScreen extends StatefulWidget {
  final Map<String, double> currentSensitivities;
  final ExerciseType exerciseType;

  const ExerciseScreen({
    super.key,
    required this.currentSensitivities,
    required this.exerciseType,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final List<double> _reticuleX = [];
  final List<double> _reticuleY = [];
  final List<double> _targetX = [];
  final List<double> _targetY = [];
  final List<double> _timestamps = [];

  StreamController<GyroSample>? _gyroController;
  StreamSubscription<GyroSample>? _gyroSubscription;
  final GyroscopeServiceMock _gyroService = GyroscopeServiceMock();
  bool _isExercising = false;
  bool _isCompleted = false;
  final Random _random = Random();

  String get _title {
    switch (widget.exerciseType) {
      case ExerciseType.tracking:
        return 'Test de Tracking';
      case ExerciseType.flick:
        return 'Test de Flick';
      case ExerciseType.stability:
        return 'Test de Stabilité';
    }
  }

  String get _instruction {
    switch (widget.exerciseType) {
      case ExerciseType.tracking:
        return 'Suivez la cible rouge avec le réticule vert';
      case ExerciseType.flick:
        return 'Visez la cible dès qu\'elle apparaît et restez dessus';
      case ExerciseType.stability:
        return 'Gardez le réticule au centre sans bouger';
    }
  }

  // ---- TRAJECTOIRES ----

  Offset _trackingTrajectory(double time) {
    final speed = 1.5 + sin(time * 0.3) * 0.5;
    final amplitudeX = 120.0 + sin(time * 0.7) * 40.0;
    final amplitudeY = 80.0 + cos(time * 0.5) * 30.0;
    return Offset(
      195.0 + sin(time * speed) * amplitudeX,
      422.0 + cos(time * speed * 1.3) * amplitudeY,
    );
  }

  Offset _flickTarget = Offset.zero;

  Offset _flickTrajectory(double time) {
    // La cible ne bouge pas pendant un flick, elle apparaît à une position fixe
    return _flickTarget;
  }

  Offset _stabilityTarget(double time) {
    // Cible fixe au centre
    return const Offset(195.0, 422.0);
  }

  Offset _getTargetPosition(double time) {
    switch (widget.exerciseType) {
      case ExerciseType.tracking:
        return _trackingTrajectory(time);
      case ExerciseType.flick:
        return _flickTrajectory(time);
      case ExerciseType.stability:
        return _stabilityTarget(time);
    }
  }

  // ---- CALLBACK ----

  void _onFrame(Offset reticule, Offset target, double time) {
    if (!_isExercising) return;
    _reticuleX.add(reticule.dx);
    _reticuleY.add(reticule.dy);
    _targetX.add(target.dx);
    _targetY.add(target.dy);
    _timestamps.add(time);
  }

  // ---- FLICK LOGIC ----

  Timer? _flickTimer;
  int _flickCount = 0;
  static const int maxFlicks = 10;

  void _spawnFlickTarget() {
    if (!_isExercising || _flickCount >= maxFlicks) return;
    setState(() {
      _flickTarget = Offset(
        50.0 + _random.nextDouble() * 290.0,
        200.0 + _random.nextDouble() * 400.0,
      );
    });
    _flickCount++;
  }

  void _startFlickExercise() {
    _flickCount = 0;
    _spawnFlickTarget();
    _flickTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_flickCount >= maxFlicks) {
        timer.cancel();
        _onExerciseComplete();
      } else {
        _spawnFlickTarget();
      }
    });
  }

  // ---- START / STOP ----

  void _startExercise() async {
    setState(() {
      _isExercising = true;
      _isCompleted = false;
      _reticuleX.clear();
      _reticuleY.clear();
      _targetX.clear();
      _targetY.clear();
      _timestamps.clear();
    });

    _gyroController = StreamController<GyroSample>.broadcast();
    await _gyroService.startListening();
    _gyroSubscription = _gyroService.sampleStream.listen(
      (sample) => _gyroController?.add(sample),
    );

    if (widget.exerciseType == ExerciseType.flick) {
      _startFlickExercise();
    }
  }

  void _onExerciseComplete() {
    _flickTimer?.cancel();
    _gyroSubscription?.cancel();
    _gyroController?.close();

    setState(() {
      _isExercising = false;
      _isCompleted = true;
    });

    Navigator.of(context).pushNamed('/report', arguments: {
      'reticuleX': _reticuleX,
      'reticuleY': _reticuleY,
      'targetX': _targetX,
      'targetY': _targetY,
      'timestamps': _timestamps,
      'currentSensitivities': widget.currentSensitivities,
      'exerciseType': widget.exerciseType.name,
    });
  }

  Duration get _duration {
    switch (widget.exerciseType) {
      case ExerciseType.tracking:
        return const Duration(seconds: 15);
      case ExerciseType.flick:
        return const Duration(seconds: 25); // 10 flicks × 2s + marge
      case ExerciseType.stability:
        return const Duration(seconds: 10);
    }
  }

  @override
  void dispose() {
    _flickTimer?.cancel();
    _gyroSubscription?.cancel();
    _gyroController?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isExercising && _gyroController != null
          ? AimSimulator(
              gyroStream: _gyroController!.stream,
              targetPosition: _getTargetPosition,
              onFrame: _onFrame,
              duration: _duration,
              onComplete: _onExerciseComplete,
              showTarget: widget.exerciseType != ExerciseType.stability ||
                  _isCompleted,
            )
          : _buildIdleScreen(),
    );
  }

  Widget _buildIdleScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isCompleted)
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 24),
          Icon(
            widget.exerciseType == ExerciseType.tracking
                ? Icons.track_changes
                : widget.exerciseType == ExerciseType.flick
                    ? Icons.flash_on
                    : Icons.center_focus_strong,
            color: Colors.blue,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            _instruction,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.exerciseType == ExerciseType.flick
                ? '10 cibles, 2 secondes par cible'
                : widget.exerciseType == ExerciseType.stability
                    ? '10 secondes, restez immobile'
                    : '15 secondes, suivez la cible',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed:
                _isCompleted ? () => Navigator.pop(context) : _startExercise,
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: Text(_isCompleted ? 'Terminé' : 'Démarrer le test'),
          ),
        ],
      ),
    );
  }
}