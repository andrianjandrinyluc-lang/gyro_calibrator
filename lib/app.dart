import 'package:flutter/material.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/config_screen.dart';
import 'presentation/screens/exercise_screen.dart';
import 'presentation/screens/calibration_report_screen.dart';

class GyroCalibratorApp extends StatelessWidget {
  const GyroCalibratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gyro Calibrator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF1A1A2E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/config':
            final type = settings.arguments as String? ?? 'tracking';
            return MaterialPageRoute(
              builder: (_) => ConfigScreen(exerciseType: type),
            );
          case '/tracking':
          case '/flick':
          case '/stability':
            final args = settings.arguments as Map<String, dynamic>;
            final type = args['exerciseType'] as String? ?? 'tracking';
            return MaterialPageRoute(
              builder: (_) => ExerciseScreen(
                currentSensitivities: (args['sensitivities'] as Map)
                    .map((k, v) => MapEntry(k, (v as num).toDouble())),
                exerciseType: type == 'flick'
                    ? ExerciseType.flick
                    : type == 'stability'
                        ? ExerciseType.stability
                        : ExerciseType.tracking,
              ),
            );
          case '/report':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CalibrationReportScreen(
                reticuleX: (args['reticuleX'] as List)
                    .map((e) => (e as num).toDouble())
                    .toList(),
                reticuleY: (args['reticuleY'] as List)
                    .map((e) => (e as num).toDouble())
                    .toList(),
                targetX: (args['targetX'] as List)
                    .map((e) => (e as num).toDouble())
                    .toList(),
                targetY: (args['targetY'] as List)
                    .map((e) => (e as num).toDouble())
                    .toList(),
                timestamps: (args['timestamps'] as List)
                    .map((e) => (e as num).toDouble())
                    .toList(),
                currentSensitivities: (args['currentSensitivities'] as Map)
                    .map((k, v) => MapEntry(k, (v as num).toDouble())),
                exerciseType: args['exerciseType'] as String? ?? 'tracking',
              ),
            );
          default:
            return MaterialPageRoute(builder: (_) => const HomeScreen());
        }
      },
    );
  }
}