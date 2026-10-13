import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../app/config/theme.dart';
import '../data/services/canvas_shell.dart';

/// Layar pratinjau/prototype mode (Fase 5): menampilkan frame aktif di dalam
/// WebView penuh tanpa overlay board, sehingga interaksi UI (tap, toggle,
/// accordion) bisa dicoba seperti aplikasi sungguhan.
///
/// Bridge metrik (dipakai board) sengaja TIDAK diaktifkan di sini: preview
/// murni menampilkan dokumen apa adanya, tanpa listener seleksi.
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

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFFFFFF));
    // Dokumen konten dimuat langsung. `nativeZoom: false` = tanpa transform
    // CSS, karena preview tampil pada ukuran aslinya di layar penuh.
    _controller.loadHtmlString(injectBridge(widget.html, nativeZoom: false));
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
        child: Center(child: WebViewWidget(controller: _controller)),
      ),
    );
  }
}
