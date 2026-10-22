import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../../../app/widgets/app_toast.dart';
import '../../data/services/canvas_service_registry.dart';
import '../../data/services/canvas_webview_service.dart';
import '../../data/services/canvas_webview_service_factory.dart';
import '../../domain/page.dart';
import '../../domain/page_slug.dart';
import '../provider/workspace_provider.dart';
import 'chat_side_panel.dart';
import 'element_edit_menu.dart';
import 'element_text_editor.dart';
import 'page_switch_tracker.dart';

/// Host preview halaman: SATU WebView untuk seluruh app yang selalu
/// menampilkan halaman aktif. Fluid — mengisi penuh kontainer, tanpa lebar
/// CSS yang di-pin. Klik `<a href>` di-intercept oleh bridge JS lalu dipetakan
/// ke halaman yang cocok (atau dibuka di browser untuk link eksternal).
class PagePreview extends ConsumerStatefulWidget {
  const PagePreview({super.key});

  @override
  ConsumerState<PagePreview> createState() => _PagePreviewState();
}

class _PagePreviewState extends ConsumerState<PagePreview> {
  final CanvasWebviewService _service = createCanvasWebviewService();
  StreamSubscription<CanvasSelectEvent>? _subscription;
  bool _ready = false;
  String? _error;
  String? _registeredPageId;

  /// Overlay "Memuat…" hanya untuk pergantian halaman (bukan mutasi HTML
  /// halaman yang sama) — lihat [PageSwitchTracker].
  final PageSwitchTracker _switchTracker = PageSwitchTracker();
  bool _switching = false;

  /// Geometri node yang menunya sedang terbuka. Null = menu tertutup.
  NodeGeometry? _menuGeometry;

  /// Rantai breadcrumb yang dipertahankan saat user naik ke induk, supaya
  /// anak yang tadi dipilih tetap bisa dituju kembali dari menu yang sama.
  List<NodeAncestor> _menuChain = const [];

  /// Node yang sedang diedit inline + teks/style awalnya.
  String? _editingNodeId;
  Rect? _editingRect;

  /// Kotak elemen yang sedang diedit (bukan kotak teks) — dipakai untuk
  /// menempatkan toolbar ✓/✕ di dekat elemennya.
  Rect? _editingElementRect;

  /// Id elemen yang ring-nya digambar (elemen terpilih, bisa induk dari
  /// target tulis). Dipakai agar kotak toolbar hanya diperbarui oleh geometri
  /// elemen itu, bukan oleh kotak teks anaknya.
  String? _editingElementId;
  String _editingText = '';
  String _liveText = '';
  Map<String, String> _editingStyles = const {};

  /// Ketikan ditahan sebentar lalu dikirim ke JS, supaya DOM (dan layout
  /// komponen) ikut berubah real-time tanpa membanjiri bridge.
  Timer? _liveTextTimer;

  /// Warna aksen terakhir yang dikirim ke JS (hindari kiriman berulang).
  String? _accentHex;

  /// Posisi gulir terakhir di dokumen aktif (CSS px). Dipulihkan setelah
  /// dokumen dirender ulang karena mutasi (hapus komponen / edit teks),
  /// supaya user tidak terlempar ke paling atas.
  double _scrollX = 0;
  double _scrollY = 0;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Overlay seleksi di dalam WebView memakai warna aksen aplikasi; kirim
    // ulang setiap tema berubah.
    final hex = _hexOf(context.palette.primary);
    if (hex == _accentHex) return;
    _accentHex = hex;
    _service.setSelectionAccent(hex);
  }

  Future<void> _initialize() async {
    try {
      await _service.init();
      _subscription = _service.selectionEvents.listen(
        _onEvent,
        onError: (Object e) => debugPrint('[workspace] bridge error: $e'),
      );
      final page = ref.read(workspaceProvider).activePage;
      if (page != null) {
        _registeredPageId = page.id;
        CanvasServiceRegistry.register(page.id, _service);
        await _service.renderHtml(page.html.isEmpty ? null : page.html);
        await _service.setSelectionMode(
          ref.read(workspaceProvider).selectionMode,
        );
        final accent = _accentHex;
        if (accent != null) await _service.setSelectionAccent(accent);
      } else {
        await _service.renderHtml(null);
      }
    } catch (e) {
      debugPrint('[workspace] WebView gagal init/render: $e');
      _error = '$e';
    }
    if (mounted) setState(() => _ready = true);
  }

  Future<void> _retryRender() async {
    if (mounted) setState(() => _error = null);
    try {
      final page = ref.read(workspaceProvider).activePage;
      await _service.renderHtml(
        page == null || page.html.isEmpty ? null : page.html,
      );
      await _service.setSelectionMode(
        ref.read(workspaceProvider).selectionMode,
      );
      final accent = _accentHex;
      if (accent != null) await _service.setSelectionAccent(accent);
    } catch (e) {
      debugPrint('[workspace] retry render gagal: $e');
      if (mounted) setState(() => _error = '$e');
    }
  }

  /// Registrasi service di bawah id halaman aktif (agar MCP/exporter bisa
  /// menemukannya) dan muat HTML-nya.
  Future<void> _renderPage(String? pageId, String? html) async {
    // Dokumen baru = koordinat lama tidak berlaku lagi; tutup menu/editor.
    _resetSelectionUi();
    // Mutasi pada halaman yang SAMA (hapus komponen / edit teks) memuat ulang
    // dokumen. Posisi gulir lama disimpan agar tidak kembali ke paling atas.
    final samePage = pageId != null && _registeredPageId == pageId;
    final restoreScroll = samePage ? Offset(_scrollX, _scrollY) : null;
    if (!samePage) {
      _scrollX = 0;
      _scrollY = 0;
    }
    // Berpindah halaman → tindih preview dengan indikator memuat selagi
    // WebView memuat dokumen baru (klik tab langsung terasa responsif).
    final switching = _switchTracker.isSwitching(pageId);
    if (switching && mounted && _ready) setState(() => _switching = true);
    if (_registeredPageId != null && _registeredPageId != pageId) {
      CanvasServiceRegistry.unregister(_registeredPageId!);
      _registeredPageId = null;
    }
    if (pageId != null) {
      CanvasServiceRegistry.register(pageId, _service);
      _registeredPageId = pageId;
    }
    // Error halaman sebelumnya tidak relevan lagi.
    if (mounted && _error != null) setState(() => _error = null);
    try {
      await _service.renderHtml(html == null || html.isEmpty ? null : html);
      // Dokumen baru selalu mulai di mode interaksi; terapkan ulang.
      await _service.setSelectionMode(
        ref.read(workspaceProvider).selectionMode,
      );
      final accent = _accentHex;
      if (accent != null) await _service.setSelectionAccent(accent);
      // Seleksi dipertahankan lintas render (mis. setelah edit teks / hapus)
      // supaya menu elemen muncul lagi dengan geometri terbaru.
      final selected = ref.read(workspaceProvider).selectedNodeId;
      if (selected != null) await _service.selectNode(selected);
      // Dipulihkan setelah seleksi (selectNode bisa memicu scrollIntoView).
      if (restoreScroll != null &&
          (restoreScroll.dx > 0 || restoreScroll.dy > 0)) {
        await _service.scrollTo(restoreScroll.dx, restoreScroll.dy);
      }
      if (mounted && _error != null) setState(() => _error = null);
    } catch (e) {
      debugPrint('[workspace] renderHtml gagal: $e');
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted && _switching) setState(() => _switching = false);
    }
  }

  void _onEvent(CanvasSelectEvent event) {
    switch (event.type) {
      case 'png':
      case 'pngError':
      case 'html':
      case 'outerHtml':
      case 'outerHtmlError':
        return; // dikonsumsi peminta via stream yang sama.
      case 'error':
        final message = event.errorMessage ?? context.l10n.previewGenericError;
        debugPrint('[workspace] bridge error: $message');
        if (mounted) setState(() => _error = message);
        return;
      case 'ready':
        if (mounted && _error != null) setState(() => _error = null);
        return;
      case 'navigate':
        _onNavigate(event.href ?? '');
        return;
      case 'geometry':
        final geometry = event.geometry;
        if (geometry != null) {
          ref.read(workspaceProvider.notifier).updateNodeGeometry(geometry);
          _onGeometry(geometry);
        }
        return;
      case 'textLayout':
        // Geometri baru setelah teks berubah: editor ikut bergeser/menyesuaikan.
        final live = event.geometry;
        if (live != null &&
            _editingNodeId != null &&
            live.id == _editingNodeId &&
            (live.textRect != null || live.textBox != null) &&
            mounted) {
          setState(() {
            _editingRect = _editorRectFor(live);
            // Toolbar tetap di kotak elemen; payload ini milik target teks.
            if (live.id == _editingElementId) {
              _editingElementRect = Rect.fromLTWH(
                live.x,
                live.y,
                live.width,
                live.height,
              );
            }
          });
        }
        return;
      case 'select':
        // Fokus edit: seleksi elemen lain ditahan sampai Simpan/Batal.
        if (_editingNodeId != null) return;
        ref.read(workspaceProvider.notifier).selectNodeFromCanvas(event.id);
        if (event.id == null) _closeMenu();
        return;
      case 'scroll':
        // Simpan posisi baca sebelum dokumen mungkin dimuat ulang.
        _scrollX = event.scrollX ?? _scrollX;
        _scrollY = event.scrollY ?? _scrollY;
        // Saat edit, editor ikut bergeser bersama teks (sesi edit tidak
        // dibatalkan hanya karena halaman digulir).
        if (_editingNodeId != null) {
          _service.requestNodeGeometry(_editingNodeId!);
          return;
        }
        // Menu native tidak ikut tergulir bersama halaman.
        _closeMenu();
        return;
      case 'cancelled':
        _closeMenu();
        if (_editingNodeId != null) _cancelTextEdit(reopenMenu: false);
        return;
      case 'hover':
        ref.read(workspaceProvider.notifier).hoverNode(event.id);
        return;
    }
  }

  Future<void> _onNavigate(String href) async {
    final pages = ref.read(workspaceProvider).pages;
    final resolved = resolveLink(href, pages);
    // Teks diambil sebelum ada `await` agar context tidak dipakai di celah async.
    final l10n = context.l10n;
    switch (resolved.kind) {
      case LinkKind.internal:
        final id = resolved.pageId;
        if (id != null) ref.read(workspaceProvider.notifier).setActivePage(id);
      case LinkKind.external:
        final uri = Uri.tryParse(href.startsWith('//') ? 'https:$href' : href);
        if (uri == null) {
          _toast(l10n.previewLinkInvalid(href));
          return;
        }
        try {
          final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!ok) _toast(l10n.previewLinkOpenFailed(href));
        } catch (_) {
          _toast(l10n.previewLinkOpenFailed(href));
        }
      case LinkKind.unknown:
        _toast(l10n.previewPageNotFound(href));
      case LinkKind.anchor:
        break;
    }
  }

  /// "Edit dengan AI" dari menu elemen: tempel mention lalu buka chat.
  void _editElementWithAi(String? nodeId, String? label) {
    if (nodeId == null) return;
    ref
        .read(workspaceProvider.notifier)
        .addElementMention(nodeId: nodeId, label: label ?? '');
    _closeMenu();
    ref.read(panelTabProvider.notifier).select(PanelTab.chat);
    ref.read(panelVisibleProvider.notifier).show();
  }

  /// Geometri terbaru dari JS: buka/perbarui menu elemen.
  void _onGeometry(NodeGeometry geometry) {
    if (_editingNodeId != null) {
      // Reposisi editor saat halaman digulir (sesi edit tetap berjalan).
      if (geometry.id == _editingNodeId) {
        setState(() {
          _editingRect = _editorRectFor(geometry);
          if (geometry.id == _editingElementId) {
            _editingElementRect = Rect.fromLTWH(
              geometry.x,
              geometry.y,
              geometry.width,
              geometry.height,
            );
          }
        });
      }
      return;
    }
    final state = ref.read(workspaceProvider);
    if (!state.selectionMode || state.selectedNodeId != geometry.id) return;
    setState(() {
      _menuGeometry = geometry;
      _menuChain = _mergeChain(_menuChain, geometry.chain);
    });
  }

  /// Pertahankan rantai yang lebih panjang saat user naik ke induk, supaya
  /// anak yang tadi dipilih tetap bisa dituju lagi lewat breadcrumb.
  List<NodeAncestor> _mergeChain(
    List<NodeAncestor> current,
    List<NodeAncestor> next,
  ) {
    if (next.isEmpty) return const [];
    if (current.length > next.length && _isPrefix(next, current)) {
      return current;
    }
    return next;
  }

  bool _isPrefix(List<NodeAncestor> prefix, List<NodeAncestor> list) {
    if (prefix.length > list.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (prefix[i].id != list[i].id) return false;
    }
    return true;
  }

  void _closeMenu() {
    if (_menuGeometry == null && _menuChain.isEmpty) return;
    setState(() {
      _menuGeometry = null;
      _menuChain = const [];
    });
  }

  void _resetSelectionUi() {
    if (_menuGeometry == null && _editingNodeId == null) return;
    _liveTextTimer?.cancel();
    setState(() {
      _menuGeometry = null;
      _menuChain = const [];
      _editingNodeId = null;
      _editingElementId = null;
      _editingRect = null;
      _editingElementRect = null;
    });
  }

  /// Pilih elemen lain (induk/anak) langsung dari breadcrumb.
  Future<void> _selectAncestor(String id) async {
    if (id == _menuGeometry?.id) return;
    ref.read(workspaceProvider.notifier).selectNode(id);
    await _service.selectNode(id);
  }

  /// Buka editor teks inline di atas teks elemen.
  void _openTextEditor() {
    final geometry = _menuGeometry;
    if (geometry == null || !geometry.textEditable) return;
    // Target tulis bisa anak dari elemen terpilih (label di dalam tombol).
    final targetId = geometry.textNodeId.isEmpty
        ? geometry.id
        : geometry.textNodeId;
    final rect = _editorRectFor(geometry);
    setState(() {
      _editingNodeId = targetId;
      _editingElementId = geometry.id;
      _editingRect = rect;
      _editingElementRect = Rect.fromLTWH(
        geometry.x,
        geometry.y,
        geometry.width,
        geometry.height,
      );
      _editingText = geometry.text;
      _liveText = geometry.text;
      _editingStyles = geometry.textStyles.isNotEmpty
          ? geometry.textStyles
          : geometry.styles;
      _menuGeometry = null;
    });
    // Ring digambar di elemen terpilih (bentuk komponen asli), bukan di
    // kotak teks kecil di dalamnya.
    _service.setTextEditing(targetId, true, ringId: geometry.id);
  }

  /// Kotak editor: lebar dari kotak isi elemen (agar wrap sama dengan
  /// halaman), posisi atas dari kotak teks sebenarnya.
  Rect _editorRectFor(NodeGeometry geometry) {
    final textRect = geometry.textRect;
    final box = geometry.textBox;
    final align = geometry.textStyles['textAlign'] ?? 'left';
    final boxLeft = box?.left ?? textRect?.left ?? geometry.x;
    final boxWidth = box?.width ?? textRect?.width ?? geometry.width;
    // Teks rata kiri bisa dimulai setelah ikon (mis. chip dengan ikon), jadi
    // caret harus mulai di kotak teks, bukan di tepi kotak isi. Untuk teks
    // rata tengah/kanan, biarkan lebar penuh dan serahkan ke textAlign.
    final centered = align == 'center' || align == 'right' || align == 'end';
    final left = centered ? boxLeft : (textRect?.left ?? boxLeft);
    final width = centered
        ? boxWidth
        : math.max(40.0, boxLeft + boxWidth - left);
    return Rect.fromLTWH(
      left,
      textRect?.top ?? box?.top ?? geometry.y,
      width,
      textRect?.height ?? 0,
    );
  }

  /// Setiap ketikan langsung ditulis ke DOM supaya komponen ikut membesar /
  /// mengecil saat itu juga.
  void _onEditorChanged(String text) {
    _liveText = text;
    final id = _editingNodeId;
    if (id == null) return;
    _liveTextTimer?.cancel();
    _liveTextTimer = Timer(const Duration(milliseconds: 16), () {
      final target = _editingNodeId;
      if (target == null) return;
      _service.liveTextUpdate(target, _liveText);
    });
  }

  /// Simpan teks hasil inline edit; HTML halaman ikut disinkronkan.
  Future<void> _commitTextEdit(String text) async {
    final id = _editingNodeId;
    if (id == null) return;
    _liveTextTimer?.cancel();
    final l10n = context.l10n;
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await _cancelTextEdit();
      return;
    }
    setState(() {
      _editingNodeId = null;
      _editingElementId = null;
      _editingRect = null;
      _editingElementRect = null;
    });
    await _service.setTextEditing(id, false);
    final ok = await ref
        .read(workspaceProvider.notifier)
        .commitCanvasTextEdit(id, trimmed);
    if (!ok) _toast(l10n.previewTextEditFailed);
  }

  /// Batalkan inline edit: teks asli ditampilkan lagi tanpa perubahan.
  /// [reopenMenu] false saat pembatalan dipicu scroll/Escape — menu tetap
  /// tertutup, bukan muncul lagi di posisi lama.
  Future<void> _cancelTextEdit({bool reopenMenu = true}) async {
    final id = _editingNodeId;
    if (id == null) return;
    _liveTextTimer?.cancel();
    setState(() {
      _editingNodeId = null;
      _editingElementId = null;
      _editingRect = null;
      _editingElementRect = null;
    });
    // DOM sudah ikut berubah selama mengetik; kembalikan teks aslinya.
    if (_liveText != _editingText) {
      await _service.liveTextUpdate(id, _editingText);
      _liveText = _editingText;
    }
    await _service.setTextEditing(id, false);
    // Geometri diminta untuk elemen TERPILIH (bisa induk dari target teks).
    final selected = ref.read(workspaceProvider).selectedNodeId;
    if (reopenMenu && selected != null) {
      await _service.requestNodeGeometry(selected);
    }
  }

  /// Hapus elemen terpilih; hasilnya bisa dikembalikan lewat Undo.
  Future<void> _deleteSelectedNode() async {
    final id = _menuGeometry?.id ?? ref.read(workspaceProvider).selectedNodeId;
    if (id == null) return;
    final l10n = context.l10n;
    final notifier = ref.read(workspaceProvider.notifier);
    _closeMenu();
    final ok = await notifier.deleteNode(id);
    if (!ok) {
      _toast(l10n.previewDeleteFailed);
      return;
    }
    if (!mounted) return;
    showAppToast(
      context,
      l10n.previewComponentDeleted,
      kind: AppToastKind.success,
      actionLabel: l10n.commonUndo,
      onAction: notifier.undo,
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    showAppToast(context, message, kind: AppToastKind.error);
  }

  @override
  void dispose() {
    if (_registeredPageId != null) {
      CanvasServiceRegistry.unregister(_registeredPageId!);
    }
    _liveTextTimer?.cancel();
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final html = ref.watch(workspaceProvider.select((s) => s.activePage?.html));

    // Muat ulang saat halaman aktif berganti atau HTML-nya berubah.
    // `activePage` mengembalikan instance baru setiap halaman berubah, jadi
    // listener ini menangkap pergantian halaman DAN perubahan HTML.
    ref.listen<AppPage?>(
      workspaceProvider.select((s) => s.activePage),
      (_, page) => _renderPage(page?.id, page?.html),
    );

    ref.listen<String?>(
      workspaceProvider.select((s) => s.selectedNodeId),
      (_, id) => _service.selectNode(id),
    );
    ref.listen<String?>(
      workspaceProvider.select((s) => s.hoveredNodeId),
      (_, id) => _service.hoverNode(id),
    );
    ref.listen<bool>(
      workspaceProvider.select((s) => s.selectionMode),
      (_, enabled) => _service.setSelectionMode(enabled),
    );

    Widget content;
    if (!_ready) {
      content = const _WebviewLoading();
    } else if (html == null || html.isEmpty) {
      content = const _PreviewEmptyState();
    } else if (_error != null) {
      content = _WebviewError(message: _error!, onRetry: _retryRender);
    } else {
      content = _service.buildView();
    }

    // Bingkai (border, radius, bilah browser) disediakan pemanggil agar
    // WebView bisa mengisi penuh area tanpa clipping tambahan.
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return ColoredBox(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(child: content),
              if (_menuGeometry != null && _editingNodeId == null)
                _positionMenu(size),
              if (_editingNodeId != null && _editingRect != null)
                _positionEditor(size),
              // Selagi dokumen baru dimuat, halaman lama tetap terlihat dan
              // ditindih scrim + spinner supaya pindah halaman terasa responsif.
              if (_switching) const _PageSwitchLoading(),
            ],
          ),
        );
      },
    );
  }

  /// Menu elemen mengambang di atas elemen terpilih (atau di bawahnya bila
  /// ruang atas tidak cukup).
  Widget _positionMenu(Size size) {
    final geometry = _menuGeometry!;
    const menuWidth = ElementEditMenu.width;
    const margin = 8.0;
    final estimatedHeight = 44.0 + (geometry.textEditable ? 34.0 : 0.0) + 68.0;

    var left = geometry.x;
    if (left + menuWidth > size.width - margin) {
      left = size.width - menuWidth - margin;
    }
    left = left
        .clamp(margin, math.max(margin, size.width - menuWidth - margin))
        .toDouble();

    var top = geometry.y - estimatedHeight - margin;
    if (top < margin) top = geometry.y + geometry.height + margin;
    top = top
        .clamp(margin, math.max(margin, size.height - estimatedHeight - margin))
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: math.max(200.0, size.width - 16)),
        child: ElementEditMenu(
          chain: _menuChain.isEmpty
              ? [
                  NodeAncestor(
                    id: geometry.id,
                    tag: geometry.tag,
                    label: geometry.tag,
                  ),
                ]
              : _menuChain,
          selectedId: geometry.id,
          canEditText: geometry.textEditable,
          onEditText: _openTextEditor,
          onEditWithAi: () => _editElementWithAi(geometry.id, geometry.tag),
          onDelete: _deleteSelectedNode,
          onSelectAncestor: _selectAncestor,
          onClose: () {
            _closeMenu();
            ref.read(workspaceProvider.notifier).selectNode(null);
            _service.selectNode(null);
          },
        ),
      ),
    );
  }

  /// Kartu edit mengambang di dekat elemen: di bawahnya bila ada ruang,
  /// kalau tidak di atasnya, dan selalu di dalam viewport.
  Widget _positionEditor(Size size) {
    final rect = _editingElementRect ?? _editingRect!;
    const margin = 8.0;
    const gap = 8.0;

    // Lebar nyaman untuk mengetik: tidak selebar halaman, tidak sekecil label.
    final maxWidth = math.max(160.0, math.min(420.0, size.width - margin * 2));
    final width = rect.width
        .clamp(math.min(240.0, maxWidth), maxWidth)
        .toDouble();

    // Perkiraan tinggi kartu (field 1–5 baris + baris tombol + padding).
    final charsPerLine = math.max(8, (width / 8).floor());
    final lines = ((_liveText.length / charsPerLine).ceil()).clamp(1, 5);
    final cardHeight = 96.0 + (lines - 1) * 20.0;

    var top = rect.bottom + gap;
    if (top + cardHeight > size.height - margin) {
      top = rect.top - cardHeight - gap;
    }
    top = top
        .clamp(margin, math.max(margin, size.height - cardHeight - margin))
        .toDouble();

    var left = rect.left;
    left = left
        .clamp(margin, math.max(margin, size.width - width - margin))
        .toDouble();

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: ElementTextEditor(
        initialText: _editingText,
        styles: _editingStyles,
        onSave: _commitTextEdit,
        onCancel: () => _cancelTextEdit(),
        onChanged: _onEditorChanged,
      ),
    );
  }

  static String _hexOf(Color color) {
    String channel(double value) =>
        (value * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${channel(color.r)}${channel(color.g)}${channel(color.b)}';
  }
}

class _PageSwitchLoading extends StatelessWidget {
  const _PageSwitchLoading();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: Colors.white.withValues(alpha: 0.72),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: context.palette.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.previewLoading,
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewEmptyState extends StatelessWidget {
  const _PreviewEmptyState();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.bgSurface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.web_asset_outlined,
                size: 30,
                color: context.palette.textDisabled,
              ),
              const SizedBox(height: 12),
              Text(
                context.l10n.previewNoPagesTitle,
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.previewNoPagesBody,
                style: context.text.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebviewError extends StatelessWidget {
  const _WebviewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.bgSunken,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.web_asset_off_outlined,
                size: 26,
                color: context.palette.statusError,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.previewLoadFailedTitle,
                style: TextStyle(
                  fontFamily: AppFonts.uiFamily,
                  fontFamilyFallback: AppFonts.uiFallback,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.length > 220
                    ? '${message.substring(0, 220)}…'
                    : message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.monoFamily,
                  fontFamilyFallback: AppFonts.monoFallback,
                  fontSize: 10.5,
                  height: 1.5,
                  color: context.palette.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(context.l10n.commonRetry),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.previewWebView2Hint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: context.palette.textDisabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebviewLoading extends StatelessWidget {
  const _WebviewLoading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.palette.bgSurface,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.palette.primary,
          ),
        ),
      ),
    );
  }
}
