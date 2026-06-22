import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../helpers/browser_helper.dart';
import '../services/vpn_engine.dart';
import '../theme/nexus_theme.dart';

class IncognitoBrowserScreen extends StatefulWidget {
  final bool embedded;

  const IncognitoBrowserScreen({super.key, this.embedded = false});

  @override
  State<IncognitoBrowserScreen> createState() => _IncognitoBrowserScreenState();
}

class _BrowserTab {
  _BrowserTab({required this.id, required String initialUrl})
      : url = initialUrl,
        title = _titleFromUrl(initialUrl);

  final String id;
  String url;
  String title;
  double progress = 0;
  bool canGoBack = false;
  bool canGoForward = false;
  InAppWebViewController? controller;

  static String _titleFromUrl(String url) {
    final display = BrowserHelper.displayUrl(url);
    if (display.isEmpty) return 'New tab';
    final host = display.split('/').first;
    return host.isEmpty ? 'New tab' : host;
  }

  void updateUrl(String? next) {
    if (next == null || next.isEmpty) return;
    url = next;
    title = _titleFromUrl(next);
  }
}

class _IncognitoBrowserScreenState extends State<IncognitoBrowserScreen> {
  final _urlController = TextEditingController();
  final _urlFocus = FocusNode();
  final List<_BrowserTab> _tabs = [];
  int _activeTabIndex = 0;
  int _tabCounter = 0;

  _BrowserTab get _activeTab => _tabs[_activeTabIndex];

  @override
  void initState() {
    super.initState();
    _addTab(url: BrowserHelper.defaultStartUrl, activate: true);
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

  void _addTab({String? url, bool activate = true}) {
    final tab = _BrowserTab(
      id: 'tab_${_tabCounter++}',
      initialUrl: url ?? BrowserHelper.defaultStartUrl,
    );
    setState(() {
      _tabs.add(tab);
      if (activate) {
        _activeTabIndex = _tabs.length - 1;
        _syncUrlField();
      }
    });
  }

  void _closeTab(int index) {
    if (_tabs.length <= 1) return;
    setState(() {
      _tabs.removeAt(index);
      if (_activeTabIndex >= _tabs.length) {
        _activeTabIndex = _tabs.length - 1;
      } else if (index < _activeTabIndex) {
        _activeTabIndex--;
      }
      _syncUrlField();
    });
  }

  void _selectTab(int index) {
    if (index == _activeTabIndex) return;
    setState(() {
      _activeTabIndex = index;
      _syncUrlField();
    });
  }

  void _syncUrlField() {
    _urlController.text = BrowserHelper.displayUrl(_activeTab.url);
  }

  Future<void> _loadInput(String input) async {
    final url = BrowserHelper.resolveInput(input);
    _urlFocus.unfocus();
    final tab = _activeTab;
    tab.updateUrl(url);
    _urlController.text = BrowserHelper.displayUrl(url);
    await tab.controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
    setState(() {});
  }

  Future<void> _updateNavState(_BrowserTab tab) async {
    final controller = tab.controller;
    if (controller == null) return;
    tab.canGoBack = await controller.canGoBack();
    tab.canGoForward = await controller.canGoForward();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeTab;
    return Scaffold(
      backgroundColor: NexusTheme.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildChrome(context, active),
            _buildTabBar(),
            if (active.progress < 1)
              LinearProgressIndicator(
                value: active.progress,
                minHeight: 2,
                backgroundColor: NexusTheme.border,
                color: NexusTheme.teal,
              ),
            Expanded(child: _buildWebViews()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: NexusTheme.bg2,
        border: Border(bottom: BorderSide(color: NexusTheme.border)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        children: [
          for (var i = 0; i < _tabs.length; i++) _buildTabChip(i),
          _buildNewTabButton(),
        ],
      ),
    );
  }

  Widget _buildTabChip(int index) {
    final tab = _tabs[index];
    final selected = index == _activeTabIndex;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectTab(index),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: selected
                  ? NexusTheme.teal.withOpacity(0.14)
                  : NexusTheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected
                    ? NexusTheme.teal.withOpacity(0.45)
                    : NexusTheme.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.public_rounded,
                  size: 14,
                  color: selected ? NexusTheme.teal : NexusTheme.text3,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    tab.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: selected ? NexusTheme.text : NexusTheme.text2,
                    ),
                  ),
                ),
                if (_tabs.length > 1) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _closeTab(index),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: selected ? NexusTheme.text2 : NexusTheme.text3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewTabButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addTab(),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 30,
          decoration: BoxDecoration(
            color: NexusTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NexusTheme.border),
          ),
          child: const Icon(Icons.add_rounded, size: 18, color: NexusTheme.teal),
        ),
      ),
    );
  }

  Widget _buildChrome(BuildContext context, _BrowserTab active) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Column(
        children: [
          Row(
            children: [
              if (!widget.embedded)
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close_rounded, size: 22),
                  color: NexusTheme.text2,
                  tooltip: 'Close',
                )
              else
                const SizedBox(width: 8),
              IconButton(
                onPressed: active.canGoBack
                    ? () async {
                        await active.controller?.goBack();
                        await _updateNavState(active);
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
                color: active.canGoBack ? NexusTheme.text : NexusTheme.text3,
                tooltip: 'Back',
              ),
              IconButton(
                onPressed: active.canGoForward
                    ? () async {
                        await active.controller?.goForward();
                        await _updateNavState(active);
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                color: active.canGoForward ? NexusTheme.text : NexusTheme.text3,
                tooltip: 'Forward',
              ),
              IconButton(
                onPressed: () => active.controller?.reload(),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                color: NexusTheme.text2,
                tooltip: 'Refresh',
              ),
              IconButton(
                onPressed: () => _addTab(),
                icon: const Icon(Icons.add_box_outlined, size: 20),
                color: NexusTheme.text2,
                tooltip: 'New tab',
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
                    const Icon(
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
                const Icon(Icons.search_rounded, size: 18, color: NexusTheme.text3),
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

  Widget _buildWebViews() {
    return IndexedStack(
      index: _activeTabIndex,
      children: [
        for (final tab in _tabs) _buildWebView(tab),
      ],
    );
  }

  Widget _buildWebView(_BrowserTab tab) {
    return InAppWebView(
      key: ValueKey(tab.id),
      initialUrlRequest: URLRequest(url: WebUri(tab.url)),
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
        tab.controller = controller;
        if (tab == _activeTab) {
          _updateNavState(tab);
        }
      },
      onLoadStart: (controller, url) {
        tab.updateUrl(url?.toString());
        tab.progress = 0;
        if (tab == _activeTab) {
          _urlController.text = BrowserHelper.displayUrl(tab.url);
        }
        setState(() {});
      },
      onLoadStop: (controller, url) async {
        tab.updateUrl(url?.toString());
        tab.progress = 1;
        if (tab == _activeTab) {
          _urlController.text = BrowserHelper.displayUrl(tab.url);
        }
        setState(() {});
        await _updateNavState(tab);
      },
      onProgressChanged: (controller, progress) {
        tab.progress = progress / 100;
        if (tab == _activeTab) setState(() {});
      },
      onUpdateVisitedHistory: (controller, url, isReload) async {
        tab.updateUrl(url?.toString());
        if (tab == _activeTab) {
          _urlController.text = BrowserHelper.displayUrl(tab.url);
        }
        setState(() {});
        await _updateNavState(tab);
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
