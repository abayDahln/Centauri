import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/config/theme.dart';

/// Layar pratinjau/prototype mode (Fase 5): menampilkan frame aktif di dalam
/// WebView penuh tanpa overlay board, sehingga interaksi UI (tap, toggle,
/// accordion) bisa dicoba seperti aplikasi sungguhan.
class FramePreviewPage extends ConsumerStatefulWidget {
  const FramePreviewPage({
    super.key,
    required this.html,
    required this.title,
    required this.width,
  });

  final String html;
  final String title;
  final double width;

  @override
  ConsumerState<FramePreviewPage> createState() => _FramePreviewPageState();
}

class _FramePreviewPageState extends ConsumerState<FramePreviewPage> {
  late final WebViewController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF));
    _controller.loadHtmlString(widget.html);
    _ready = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        toolbarHeight: 52,
        title: Text(widget.title, overflow: TextOverflow.ellipsis),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${widget.width.round()}px',
                style: AppText.caption,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: _ready
              ? WebViewWidget(controller: _controller)
              : const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
