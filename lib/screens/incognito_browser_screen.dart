import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/browser_helper.dart';
import '../services/vpn_engine.dart';
import '../theme/nexus_theme.dart';

class IncognitoBrowserScreen extends StatefulWidget {
  const IncognitoBrowserScreen({super.key});

  @override
  State<IncognitoBrowserScreen> createState() => _IncognitoBrowserScreenState();
}

class _IncognitoBrowserScreenState extends State<IncognitoBrowserScreen> {
  InAppWebViewController? _controller;
  final _urlController = TextEditingController();
  final _urlFocus = FocusNode();

  double _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  String? _currentUrl;

  @override
  void initState() {
    super.initState();
    _urlController.text = BrowserHelper.displayUrl(BrowserHelper.defaultStartUrl);
  }

  @override
  void dispose() {
    _clearSessionData();
    _urlController.dispose();
    _urlFocus.dispose();
    super.dispose();
  }

  Future<void> _clearSessionData() async {
    try {
      await CookieManager.instance().deleteAllCookies();
      await InAppWebViewController.clearAllCache();
    } catch (_) {}
  }

  Future<void> _loadInput(String input) async {
    final url = BrowserHelper.resolveInput(input);
    _urlFocus.unfocus();
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri(url)),
    );
  }

  Future<void> _updateNavState() async {
    if (_controller == null) return;
    final back = await _controller!.canGoBack();
    final forward = await _controller!.canGoForward();
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexusTheme.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildChrome(context),
            if (_progress < 1)
              LinearProgressIndicator(
                value: _progress,
                minHeight: 2,
                backgroundColor: NexusTheme.border,
                color: NexusTheme.teal,
              ),
            Expanded(child: _buildWebView()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildChrome(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close_rounded, size: 22),
                color: NexusTheme.text2,
                tooltip: 'Close',
              ),
              IconButton(
                onPressed: _canGoBack
                    ? () async {
                        await _controller?.goBack();
                        await _updateNavState();
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                color: _canGoBack ? NexusTheme.text : NexusTheme.text3,
                tooltip: 'Back',
              ),
              IconButton(
                onPressed: _canGoForward
                    ? () async {
                        await _controller?.goForward();
                        await _updateNavState();
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                color: _canGoForward ? NexusTheme.text : NexusTheme.text3,
                tooltip: 'Forward',
              ),
              IconButton(
                onPressed: () => _controller?.reload(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: NexusTheme.text2,
                tooltip: 'Refresh',
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: NexusTheme.teal.withOpacity(0.1),
                  border: Border.all(color: NexusTheme.teal.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.visibility_off_rounded,
                      size: 13,
                      color: NexusTheme.teal,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Incognito',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        letterSpacing: 0.5,
                        color: NexusTheme.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: NexusTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NexusTheme.border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: NexusTheme.text3),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    focusNode: _urlFocus,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: NexusTheme.text,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search or enter URL',
                      hintStyle: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: NexusTheme.text3,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    textInputAction: TextInputAction.go,
                    onSubmitted: _loadInput,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.url,
                  ),
                ),
                IconButton(
                  onPressed: () => _loadInput(_urlController.text),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  color: NexusTheme.teal,
                  tooltip: 'Go',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(BrowserHelper.defaultStartUrl),
      ),
      initialSettings: InAppWebViewSettings(
        incognito: true,
        javaScriptEnabled: true,
        useOnDownloadStart: false,
        transparentBackground: true,
        supportZoom: true,
        builtInZoomControls: true,
        displayZoomControls: false,
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
      },
      onLoadStart: (controller, url) {
        setState(() {
          _currentUrl = url?.toString();
          _urlController.text = BrowserHelper.displayUrl(_currentUrl);
        });
      },
      onLoadStop: (controller, url) async {
        setState(() {
          _currentUrl = url?.toString();
          _urlController.text = BrowserHelper.displayUrl(_currentUrl);
          _progress = 1;
        });
        await _updateNavState();
      },
      onProgressChanged: (controller, progress) {
        setState(() => _progress = progress / 100);
      },
      onUpdateVisitedHistory: (controller, url, isReload) async {
        setState(() {
          _currentUrl = url?.toString();
          _urlController.text = BrowserHelper.displayUrl(_currentUrl);
        });
        await _updateNavState();
      },
    );
  }

  Widget _buildFooter() {
    return StreamBuilder<String>(
      stream: VpnEngine.vpnStageSnapshot(),
      initialData: VpnEngine.vpnDisconnected,
      builder: (context, snapshot) {
        final connected = snapshot.data == VpnEngine.vpnConnected;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            10 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: NexusTheme.bg2,
            border: Border(top: BorderSide(color: NexusTheme.border)),
          ),
          child: Row(
            children: [
              Icon(
                connected ? Icons.shield_rounded : Icons.info_outline_rounded,
                size: 14,
                color: connected ? NexusTheme.teal : NexusTheme.text2,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  connected
                      ? 'VPN active — traffic routed through encrypted tunnel'
                      : 'Connect VPN for encrypted browsing',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: connected ? NexusTheme.teal : NexusTheme.text2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
