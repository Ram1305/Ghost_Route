import 'dart:async';

import 'package:flutter/material.dart';

/// Session timer — counts up (subscribers) or down from [seconds] (free tier).
class CountDownTimer extends StatefulWidget {
  final bool running;
  final bool countDown;
  final int? seconds;

  const CountDownTimer.elapsed({
    super.key,
    required this.running,
  })  : countDown = false,
        seconds = null;

  const CountDownTimer.remaining({
    super.key,
    required this.running,
    required this.seconds,
  }) : countDown = true;

  @override
  State<CountDownTimer> createState() => _CountDownTimerState();
}

class _CountDownTimerState extends State<CountDownTimer> {
  Duration _duration = Duration.zero;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.countDown && widget.seconds != null) {
      _duration = Duration(seconds: widget.seconds!);
    }
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant CountDownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.countDown &&
        widget.seconds != null &&
        widget.seconds != oldWidget.seconds) {
      _duration = Duration(seconds: widget.seconds!);
    }
    _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    if (widget.running) {
      if (_timer == null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted) return;
          setState(() {
            if (widget.countDown) {
              if (_duration.inSeconds > 0) {
                _duration = Duration(seconds: _duration.inSeconds - 1);
              }
            } else {
              _duration = Duration(seconds: _duration.inSeconds + 1);
            }
          });
        });
      }
    } else {
      _timer?.cancel();
      _timer = null;
      if (!widget.countDown) {
        _duration = Duration.zero;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String twoDigit(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigit(_duration.inMinutes.remainder(60));
    final seconds = twoDigit(_duration.inSeconds.remainder(60));
    final hours = twoDigit(_duration.inHours.remainder(24));

    return Text('$hours:$minutes:$seconds', style: const TextStyle(fontSize: 22));
  }
}

/// Formats seconds as `mm:ss` for compact banners.
String formatSessionMmSs(int totalSeconds) {
  final clamped = totalSeconds < 0 ? 0 : totalSeconds;
  final m = (clamped ~/ 60).toString().padLeft(2, '0');
  final s = (clamped % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
