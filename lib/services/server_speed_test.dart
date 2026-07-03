import 'dart:async';
import 'dart:io';

import '../models/vpn.dart';

/// Picks the lowest-latency server from a candidate list via TCP connect timing.
/// There's no real ping/speed data available (the VPN Gate `Ping`/`Speed` fields
/// are self-reported and often stale), so this measures actual reachability
/// latency from the device at connect time.
class ServerSpeedTest {
  static const int _probePort = 443;
  static const int _sampleSize = 10;

  static Future<Vpn?> findFastest(
    List<Vpn> servers, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (servers.isEmpty) return null;

    final candidates = (List<Vpn>.from(servers)..shuffle())
        .take(_sampleSize)
        .toList();

    final latencies = await Future.wait(
      candidates.map((v) => _measure(v, timeout)),
    );

    Vpn? fastest;
    var bestMs = 1 << 31;
    for (var i = 0; i < candidates.length; i++) {
      final ms = latencies[i];
      if (ms != null && ms < bestMs) {
        bestMs = ms;
        fastest = candidates[i];
      }
    }

    return fastest ?? candidates.first;
  }

  static Future<int?> _measure(Vpn vpn, Duration timeout) async {
    final host = vpn.ip.isNotEmpty ? vpn.ip : vpn.hostname;
    if (host.isEmpty) return null;

    final stopwatch = Stopwatch()..start();
    Socket? socket;
    try {
      socket = await Socket.connect(host, _probePort, timeout: timeout);
      return stopwatch.elapsedMilliseconds;
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }
}
