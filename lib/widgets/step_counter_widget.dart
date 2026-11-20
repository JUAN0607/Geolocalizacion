import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:vibration/vibration.dart';

import '../theme/app_theme.dart';

class StepCounterWidget extends StatefulWidget {
  final ValueChanged<double> onDistanceUpdated;

  const StepCounterWidget({super.key, required this.onDistanceUpdated});

  static const double walkingThreshold = 1.25;

  static const double metersPerSecond = 1.2;

  static bool isWalking(double x, double y, double z) =>
      sqrt(x * x + y * y + z * z) > walkingThreshold;

  @override
  State<StepCounterWidget> createState() => _StepCounterWidgetState();
}

class _StepCounterWidgetState extends State<StepCounterWidget> {
  bool _isWalking = false;
  double _distanceMeters = 0.0;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;
  Timer? _walkTimer;
  bool _sensorAvailable = true;

  @override
  void initState() {
    super.initState();
    _startSensorMonitoring();
  }

  void _startSensorMonitoring() {
    _walkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isWalking) {
        setState(() {
          _distanceMeters += StepCounterWidget.metersPerSecond;
        });
        widget.onDistanceUpdated(_distanceMeters);
      }
    });

    _gyroSubscription = gyroscopeEventStream().listen(
      (GyroscopeEvent event) {
        final bool walkingNow = StepCounterWidget.isWalking(
          event.x,
          event.y,
          event.z,
        );

        if (walkingNow != _isWalking) {
          setState(() {
            _isWalking = walkingNow;
          });

          if (_isWalking) {
            Vibration.vibrate(duration: 150);
          }
        }
      },
      onError: (Object e) {
        debugPrint('Giroscopio no disponible: $e');
        if (mounted) setState(() => _sensorAvailable = false);
      },
      cancelOnError: true,
    );
  }

  @override
  void dispose() {
    _gyroSubscription?.cancel();
    _walkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _isWalking ? AppTheme.primaryGreen : Colors.grey.shade600;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isWalking ? Icons.directions_walk : Icons.accessibility_new,
              size: 72,
              color: color,
            ),
            const SizedBox(height: 12),
            Text(
              _sensorAvailable
                  ? (_isWalking ? 'Caminando' : 'En reposo')
                  : 'Giroscopio no disponible',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${_distanceMeters.toStringAsFixed(1)} m',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w300),
            ),
            const Text('Distancia recorrida (estimada)'),
          ],
        ),
      ),
    );
  }
}
