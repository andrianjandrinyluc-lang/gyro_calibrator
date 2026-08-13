import 'dart:async';
import 'dart:math';
import '../../data/models/gyro_sample.dart';

abstract class GyroscopeService {
  Stream<GyroSample> get sampleStream;
  Future<void> startListening();
  Future<void> stopListening();
  Future<bool> isAvailable();
}

class GyroscopeServiceMock implements GyroscopeService {
  StreamSubscription? _subscription;
  final StreamController<GyroSample> _controller =
      StreamController<GyroSample>.broadcast();
  bool _isListening = false;

  @override
  Stream<GyroSample> get sampleStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;

    _subscription = Stream.periodic(
      const Duration(milliseconds: 10),
      (_) {
        final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
        return GyroSample(
          x: sin(t * 2.0) * 0.3,
          y: cos(t * 1.5) * 0.3,
          z: 0.0,
          timestamp: DateTime.now().microsecondsSinceEpoch,
        );
      },
    ).listen((sample) {
      if (!_controller.isClosed) _controller.add(sample);
    });
  }

  @override
  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _isListening = false;
  }
}