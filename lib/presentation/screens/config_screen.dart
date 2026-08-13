import 'package:flutter/material.dart';

class ConfigScreen extends StatefulWidget {
  final String exerciseType;

  const ConfigScreen({super.key, this.exerciseType = 'tracking'});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  double _noScope = 200.0;
  double _redDot = 200.0;
  double _x2 = 180.0;
  double _x3 = 160.0;
  double _x4 = 140.0;
  double _x6 = 100.0;
  double _x8 = 80.0;

  String get _route {
    switch (widget.exerciseType) {
      case 'flick':
        return '/flick';
      case 'stability':
        return '/stability';
      default:
        return '/tracking';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Configuration'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Entrez vos sensibilités PUBG actuelles',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'PUBG → Réglages → Sensibilité → Gyroscope → ADS',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _buildSlider('Sans viseur (No Scope)', _noScope, (v) {
              setState(() => _noScope = v);
            }),
            _buildSlider('Red Dot / Holo', _redDot, (v) {
              setState(() => _redDot = v);
            }),
            _buildSlider('Lunette x2', _x2, (v) {
              setState(() => _x2 = v);
            }),
            _buildSlider('Lunette x3', _x3, (v) {
              setState(() => _x3 = v);
            }),
            _buildSlider('Lunette x4', _x4, (v) {
              setState(() => _x4 = v);
            }),
            _buildSlider('Lunette x6', _x6, (v) {
              setState(() => _x6 = v);
            }),
            _buildSlider('Lunette x8', _x8, (v) {
              setState(() => _x8 = v);
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, _route, arguments: {
                    'sensitivities': {
                      'no_scope': _noScope,
                      'red_dot': _redDot,
                      '2x': _x2,
                      '3x': _x3,
                      '4x': _x4,
                      '6x': _x6,
                      '8x': _x8,
                    },
                    'exerciseType': widget.exerciseType,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Démarrer le Test',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
      String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white)),
              Text('${value.toInt()}%',
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: 1,
            max: 400,
            divisions: 399,
            activeColor: Colors.blue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}