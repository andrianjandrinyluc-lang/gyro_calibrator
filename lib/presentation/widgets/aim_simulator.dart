import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/utils/math_utils.dart';
import '../../data/models/gyro_sample.dart';

class AimSimulator extends StatefulWidget {
  final Stream<GyroSample> gyroStream;
  final Offset Function(double time) targetPosition;
  final void Function(Offset reticule, Offset target, double time)? onFrame;
  final Duration duration;
  final VoidCallback onComplete;
  final bool showTarget;

  const AimSimulator({
    super.key,
    required this.gyroStream,
    required this.targetPosition,
    this.onFrame,
    required this.duration,
    required this.onComplete,
    this.showTarget = true,
  });

  @override
  State<AimSimulator> createState() => _AimSimulatorState();
}

class _AimSimulatorState extends State<AimSimulator>
    with SingleTickerProviderStateMixin {
  double _angleX = 0.0;
  double _angleY = 0.0;
  double _lastVelocityX = 0.0;
  double _lastVelocityY = 0.0;
  double _elapsedTime = 0.0;
  late final AnimationController _animationController;
  StreamSubscription<GyroSample>? _gyroSubscription;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )
      ..addListener(_onAnimationTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          widget.onComplete();
        }
      });

    _gyroSubscription = widget.gyroStream.listen(_onGyroSample);
    _animationController.forward();
  }

  void _onAnimationTick() {
    setState(() {
      _elapsedTime = _animationController.value *
          widget.duration.inMilliseconds /
          1000.0;
    });
  }

  void _onGyroSample(GyroSample sample) {
    if (_lastVelocityX == 0.0 && _lastVelocityY == 0.0) {
      _lastVelocityX = sample.y;
      _lastVelocityY = sample.x;
      return;
    }

    final deltaTime = AppConstants.samplePeriod;
    final deltaAngleX = MathUtils.integrateAngularVelocity(
        _lastVelocityX, sample.y, deltaTime);
    final deltaAngleY = MathUtils.integrateAngularVelocity(
        _lastVelocityY, sample.x, deltaTime);

    setState(() {
      _angleX += deltaAngleX;
      _angleY += deltaAngleY;
    });

    _lastVelocityX = sample.y;
    _lastVelocityY = sample.x;

    if (widget.onFrame != null && _screenSize != Size.zero) {
      final reticulePos = _getReticuleScreenPosition();
      final targetPos = widget.targetPosition(_elapsedTime);
      widget.onFrame!(reticulePos, targetPos, _elapsedTime);
    }
  }

  Offset _getReticuleScreenPosition() {
    if (_screenSize == Size.zero) return Offset.zero;
    final px = MathUtils.angleToPixels(
        _angleX, AppConstants.fovHorizontal, _screenSize.width);
    final py = MathUtils.angleToPixels(
        _angleY, AppConstants.fovVertical, _screenSize.height);
    return Offset(
        px.clamp(0, _screenSize.width), py.clamp(0, _screenSize.height));
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenSize = Size(constraints.maxWidth, constraints.maxHeight);
        final reticulePos = _getReticuleScreenPosition();
        final targetPos = widget.targetPosition(_elapsedTime);

        return CustomPaint(
          painter: _AimPainter(
            reticulePosition: reticulePos,
            targetPosition: targetPos,
            backgroundColor: Colors.grey[900]!,
            showTarget: widget.showTarget,
          ),
          size: _screenSize,
        );
      },
    );
  }
}

class _AimPainter extends CustomPainter {
  final Offset reticulePosition;
  final Offset targetPosition;
  final Color backgroundColor;
  final bool showTarget;

  _AimPainter({
    required this.reticulePosition,
    required this.targetPosition,
    required this.backgroundColor,
    this.showTarget = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fond
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = backgroundColor);

    // Grille
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Cible
    if (showTarget) {
      canvas.drawCircle(targetPosition, 15, Paint()..color = Colors.red);
      canvas.drawCircle(targetPosition, 10, Paint()..color = Colors.white);
      canvas.drawCircle(targetPosition, 3, Paint()..color = Colors.red);

      // Ligne d'erreur
      final errorPaint = Paint()
        ..color = Colors.yellow.withOpacity(0.5)
        ..strokeWidth = 1;
      canvas.drawLine(reticulePosition, targetPosition, errorPaint);
    }

    // Réticule
    final crosshairPaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2;
    const crosshairSize = 20.0;
    canvas.drawLine(
      Offset(reticulePosition.dx - crosshairSize, reticulePosition.dy),
      Offset(reticulePosition.dx + crosshairSize, reticulePosition.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(reticulePosition.dx, reticulePosition.dy - crosshairSize),
      Offset(reticulePosition.dx, reticulePosition.dy + crosshairSize),
      crosshairPaint,
    );
    canvas.drawCircle(
        reticulePosition, 3, Paint()..color = Colors.greenAccent);
  }

  @override
  bool shouldRepaint(covariant _AimPainter oldDelegate) => true;
}