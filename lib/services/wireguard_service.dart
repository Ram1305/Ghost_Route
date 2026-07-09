import 'dart:io';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/wireguard_server.dart';

class WireguardService {
  static String buildConfig(WireguardServer s) {
    final address = s.address.trim();
    final dns = s.dns.trim();
    final allowed = s.allowedIPs.trim().isEmpty ? '0.0.0.0/0, ::/0' : s.allowedIPs.trim();
    final keepalive = s.persistentKeepalive > 0 ? s.persistentKeepalive : 25;

    return [
      '[Interface]',
      'PrivateKey = ${s.clientPrivateKey.trim()}',
      if (address.isNotEmpty) 'Address = $address',
      if (dns.isNotEmpty) 'DNS = $dns',
      '',
      '[Peer]',
      'PublicKey = ${s.publicKey.trim()}',
      'AllowedIPs = $allowed',
      'Endpoint = ${s.host.trim()}:${s.port}',
      'PersistentKeepalive = $keepalive',
      '',
    ].join('\n');
  }

  /// Opens the WireGuard app import flow by sharing a generated `.conf`.
  /// This does not create an in-app tunnel; it hands off to the official app.
  static Future<void> openInWireguardApp(BuildContext context, WireguardServer s) async {
    final cfg = buildConfig(s);
    final safeName = s.serverName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final fileName = (safeName.isEmpty ? 'wireguard' : safeName) + '.conf';

    final Rect origin = _shareOriginFor(context);

    // iOS is picky about file-provider URLs + inferred types. Sharing raw bytes
    // with a `.conf` name yields a document item that WireGuard can import.
    if (Platform.isIOS) {
      final bytes = utf8.encode(cfg);
      await Share.shareXFiles(
        [
          XFile.fromData(
            bytes,
            name: fileName,
            mimeType: 'application/octet-stream',
          ),
        ],
        subject: 'WireGuard config',
        text: 'Import this config in WireGuard to connect.',
        sharePositionOrigin: origin,
      );
      return;
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(cfg);
    await Share.shareXFiles(
      [XFile(file.path, name: fileName)],
      subject: 'WireGuard config',
      text: 'Import this config in WireGuard to connect.',
      sharePositionOrigin: origin,
    );
  }

  static Rect _shareOriginFor(BuildContext context) {
    final ro = context.findRenderObject();
    if (ro is RenderBox && ro.hasSize) {
      final topLeft = ro.localToGlobal(Offset.zero);
      final size = ro.size;
      if (size.width > 0 && size.height > 0) {
        return topLeft & size;
      }
    }
    final size = MediaQuery.of(context).size;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 1,
      height: 1,
    );
  }
}

