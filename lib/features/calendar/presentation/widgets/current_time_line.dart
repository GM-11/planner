import 'package:flutter/material.dart';
import 'dart:async';

class CurrentTimeLine extends StatefulWidget {
  const CurrentTimeLine({super.key});

  @override
  State<CurrentTimeLine> createState() => _CurrentTimeLineState();
}

class _CurrentTimeLineState extends State<CurrentTimeLine> {
  Timer? _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = _now.hour;
    final minutes = _now.minute;
    final totalMinutes = (hour * 60) + minutes;
    final topPosition = (totalMinutes * 80) / 60;

    return Positioned(
      top: topPosition - 1,
      left: 64,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 2,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.7),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: -4,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
