import 'dart:io';

import 'canvas_webview_service.dart';
import 'mobile_canvas_webview_service.dart';
import 'windows_canvas_webview_service.dart';

/// Factory runtime: pilih implementasi sesuai OS.
/// (Web hanya disupport sebagai fallback mobile; target resmi Android + Windows.)
CanvasWebviewService createCanvasWebviewService() {
  if (Platform.isWindows) return WindowsCanvasWebviewService();
  return MobileCanvasWebviewService();
}
