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
import '../provider/generation_stream_provider.dart';
import '../provider/workspace_provider.dart';
import 'chat_side_panel.dart';
import 'element_edit_menu.dart';
import 'generation_canvas_overlay.dart';
import 'element_text_editor.dart';
import 'page_view_cache.dart';

/// Host preview halaman. Setiap halaman punya WebView sendiri yang disimpan
/// di [PageViewCache]: halaman yang pernah dibuka tetap hidup di belakang
/// (dokumen, skrip, posisi gulir), jadi berpindah kembali ke halaman itu
/// seketika tanpa memuat ulang dokumen.
///
/// Halaman yang belum pernah dibuka tetap perlu render pertama; selama itu
/// halaman yang sedang tampil dibiarkan terlihat (bukan ditimpa scrim) dan
/// indikator baru muncul bila render terasa lambat.
///
/// Fluid — mengisi penuh kontainer, tanpa lebar CSS yang di-pin. Klik
/// `<a href>` di-intercept oleh bridge JS lalu dipetakan ke halaman yang cocok
/// (atau dibuka di browser untuk link eksternal).
class PagePreview extends ConsumerStatefulWidget {
  const PagePreview({super.key});

  @override
  ConsumerState<PagePreview> createState() => _PagePreviewState();
}

class _PagePreviewState extends ConsumerState<PagePreview> {
  /// Batas WebView yang disimpan hidup. Halaman aktif + halaman yang sedang
  /// tampil selalu dilindungi dari penggusuran.
  static const int _cachedPages = 3;

  final PageViewCache<_PageSlot> _slots = PageViewCache<_PageSlot>(
    maxEntries: _cachedPages,
  );

  /// Halaman yang sedang dituju (sumber listener halaman aktif).
  String? _activeId;

  /// Halaman yang WebView-nya sedang terpasang di layar. Bisa tertinggal satu
  /// langkah di belakang [_activeId] selama render pertama halaman baru,
  /// supaya halaman lama tidak berkedip hilang.
  String? _displayId;

  bool _ready = false;

  /// Overlay "Memuat…" — hanya tampil bila render pertama halaman baru
  /// melebihi [_switchOverlayDelay], bukan untuk halaman dari cache.
  bool _switching = false;
  Timer? _switchTimer;
  static const Duration _switchOverlayDelay = Duration(milliseconds: 160);

  /// Nomor urut render halaman; render lama yang selesai belakangan diabaikan.
  int _renderSeq = 0;

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

  Timer? _previewTimer;

  _PageSlot? get _activeSlot => _activeId == null ? null : _slots[_activeId!];
  _PageSlot? get _displaySlot =>
      _displayId == null ? null : _slots[_displayId!];

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
    _activeSlot?.service.setSelectionAccent(hex);
  }

  Future<void> _initialize() async {
    final page = ref.read(workspaceProvider).activePage;
    if (page != null) await _renderPage(page.id, page.html);
    if (mounted) setState(() => _ready = true);
  }

  /// Buat WebView baru untuk [pageId] dan langsung mulai inisialisasi di
  /// belakang. Event bridge halaman ini tetap terdaftar walau nanti tidak
  /// sedang tampil.
  _PageSlot _openSlot(String pageId) {
    final service = createCanvasWebviewService();
    final slot = _PageSlot(pageId: pageId, service: service);
    slot.subscription = service.selectionEvents.listen(
      (event) => _onEvent(slot, event),
      onError: (Object e) => debugPrint('[workspace] bridge error: $e'),
    );
    slot.initFuture = service
        .init()
        .then((_) {
          slot.ready = true;
          if (mounted) setState(() {});
        })
        .catchError((Object e) {
          debugPrint('[workspace] WebView gagal init: $e');
          slot.error = '$e';
          if (mounted) setState(() {});
        });
    // MCP/exporter menemukan WebView halaman lewat registry ini — termasuk
    // halaman yang sedang tersimpan di cache.
    CanvasServiceRegistry.register(pageId, service);
    return slot;
  }

  Future<void> _retryRender() async {
    final id = _activeId;
    if (id == null) return;
    final old = _slots.remove(id);
    if (_displayId == id) _displayId = null;
    _activeId = null;
    if (mounted) {
      setState(() {
        _switching = false;
        _ready = true;
      });
    }
    old?.dispose();
    final page = ref.read(workspaceProvider).activePage;
    await _renderPage(page?.id, page?.html);
  }

  /// Tampilkan halaman [pageId] dengan memakai WebView dari cache bila ada.
  ///
  /// Hanya pemuatan pertama sebuah halaman (atau saat HTML-nya berubah) yang
  /// memuat dokumen baru; selebihnya cuma menukar WebView yang terpasang.
  Future<void> _renderPage(String? pageId, String? html) async {
    // Dokumen baru = koordinat lama tidak berlaku lagi; tutup menu/editor.
    _resetSelectionUi();
    _pruneSlots();

    if (pageId == null) {
      _activeId = null;
      _displayId = null;
      _clearSwitchOverlay();
      for (final slot in _slots.clear()) {
        slot.dispose();
      }
      if (mounted) setState(() {});
      return;
    }

    // Penanda render terbaru: hasil render lama yang selesai belakangan
    // (user pindah halaman lagi) tidak boleh menimpa halaman yang aktif.
    final seq = ++_renderSeq;
    final nextHtml = (html == null || html.isEmpty) ? null : html;
    final switching = _activeId != pageId;

    var slot = _slots.touch(pageId);
    final isNew = slot == null;
    slot ??= _openSlot(pageId);
    // Halaman tujuan + halaman yang sedang tampil tidak boleh tergusur.
    final evicted = _slots.store(pageId, slot, keep: [pageId, ?_displayId]);
    for (final gone in evicted) {
      gone.dispose();
    }

    _activeId = pageId;
    final needsRender = isNew || !slot.rendered || slot.html != nextHtml;

    // Bukan pindah halaman dan HTML tidak berubah: tidak ada yang perlu
    // dirender (mis. listener terpicu karena halaman lain dimutasi).
    if (!switching && !needsRender) {
      if (mounted) setState(() {});
      return;
    }

    // Mutasi halaman yang sama memuat ulang dokumen; posisi baca dipertahankan
    // supaya user tidak terlempar ke paling atas.
    final restoreScroll = needsRender && !switching
        ? Offset(slot.scrollX, slot.scrollY)
        : null;

    // Halaman cache tampil seketika; halaman baru baru memunculkan indikator
    // setelah [_switchOverlayDelay] agar pemuatan cepat tidak berkedip.
    if (switching && needsRender) _scheduleSwitchOverlay();

    try {
      await slot.initFuture;
      if (seq != _renderSeq) return;
      if (slot.error != null) {
        if (mounted) setState(() {});
        return;
      }
      if (needsRender) {
        await slot.service.renderHtml(nextHtml);
        if (seq != _renderSeq) return;
        slot
          ..html = nextHtml
          ..displayedHtml = nextHtml
          ..appliedPreview = null
          ..rendered = true;
      }
      // Tampilkan sebelum sinkronisasi JS: pergantian halaman tidak menunggu
      // mode seleksi / aksen / seleksi node.
      _showSlot(slot);
      await _syncSlot(slot, restoreScroll: restoreScroll);
      slot.error = null;
    } catch (e) {
      debugPrint('[workspace] renderHtml gagal: $e');
      slot.error = '$e';
      if (mounted) setState(() {});
    } finally {
      if (seq == _renderSeq) _clearSwitchOverlay();
    }
  }

  /// Pasang WebView [slot] di layar (tanpa memuat ulang dokumennya).
  void _showSlot(_PageSlot slot) {
    if (_displayId == slot.pageId) return;
    _displayId = slot.pageId;
    if (mounted) setState(() {});
  }

  /// Terapkan state aplikasi yang hidup di luar dokumen: mode seleksi, warna
  /// aksen, node terpilih, dan posisi gulir.
  Future<void> _syncSlot(_PageSlot slot, {Offset? restoreScroll}) async {
    final state = ref.read(workspaceProvider);
    await slot.service.setSelectionMode(state.selectionMode);
    final accent = _accentHex;
    if (accent != null) await slot.service.setSelectionAccent(accent);
    // Seleksi dipertahankan lintas render (mis. setelah edit teks / hapus)
    // supaya menu elemen muncul lagi dengan geometri terbaru.
    await slot.service.selectNode(state.selectedNodeId);
    // Dipulihkan setelah seleksi (selectNode bisa memicu scrollIntoView).
    if (restoreScroll != null &&
        (restoreScroll.dx > 0 || restoreScroll.dy > 0)) {
      await slot.service.scrollTo(restoreScroll.dx, restoreScroll.dy);
    }
  }

  /// Buang WebView halaman yang sudah tidak ada di proyek.
  void _pruneSlots() {
    final ids = ref.read(workspaceProvider).pages.map((p) => p.id).toSet();
    for (final id in _slots.ids) {
      if (id == _activeId || ids.contains(id)) continue;
      _slots.remove(id)?.dispose();
    }
  }

  void _scheduleSwitchOverlay() {
    _switchTimer?.cancel();
    _switchTimer = Timer(_switchOverlayDelay, () {
      if (!mounted || _switching) return;
      setState(() => _switching = true);
    });
  }

  void _clearSwitchOverlay() {
    _switchTimer?.cancel();
    _switchTimer = null;
    if (_switching && mounted) setState(() => _switching = false);
  }

  void _onEvent(_PageSlot slot, CanvasSelectEvent event) {
    // Halaman latar tidak boleh mengubah UI halaman aktif; simpan errornya
    // saja supaya tetap terlihat saat halaman itu dibuka.
    if (slot.pageId != _activeId) {
      if (event.type == 'error') {
        slot.error = event.errorMessage ?? 'WebView error';
      }
      return;
    }
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
        slot.error = message;
        if (mounted) setState(() {});
        return;
      case 'ready':
        if (mounted && slot.error != null) setState(() => slot.error = null);
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
        // Simpan posisi baca halaman ini sebelum dokumennya mungkin dimuat
        // ulang (mutasi halaman) atau saat ditinggalkan.
        slot.scrollX = event.scrollX ?? slot.scrollX;
        slot.scrollY = event.scrollY ?? slot.scrollY;
        // Saat edit, editor ikut bergeser bersama teks (sesi edit tidak
        // dibatalkan hanya karena halaman digulir).
        if (_editingNodeId != null) {
          slot.service.requestNodeGeometry(_editingNodeId!);
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
    await _activeSlot?.service.selectNode(id);
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
    _activeSlot?.service.setTextEditing(targetId, true, ringId: geometry.id);
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

  /// Terapkan dokumen parsial ke WebView halaman aktif (throttle 200 ms,
  /// minimal 300 char baru). `null` = pratinjau berakhir: pulihkan halaman
  /// asli bila yang tampil memang dokumen parsial.
  void _schedulePreview(String? html) {
    final slot = _activeSlot;
    if (slot == null) return;
    if (html == null) {
      _previewTimer?.cancel();
      _previewTimer = null;
      final applied = slot.appliedPreview;
      slot.appliedPreview = null;
      if (applied == null) return;
      final page = ref.read(workspaceProvider).activePage;
      if (slot.displayedHtml != (page?.html ?? '')) {
        _renderPage(page?.id, page?.html);
      }
      return;
    }
    if (html == slot.appliedPreview) return;
    if (html.length - (slot.appliedPreview?.length ?? 0) < 300) return;
    _previewTimer?.cancel();
    _previewTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      slot.appliedPreview = html;
      slot.displayedHtml = html;
      slot.service.previewHtml(html);
    });
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
      _activeSlot?.service.liveTextUpdate(target, _liveText);
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
    await _activeSlot?.service.setTextEditing(id, false);
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
      await _activeSlot?.service.liveTextUpdate(id, _editingText);
      _liveText = _editingText;
    }
    await _activeSlot?.service.setTextEditing(id, false);
    // Geometri diminta untuk elemen TERPILIH (bisa induk dari target teks).
    final selected = ref.read(workspaceProvider).selectedNodeId;
    if (reopenMenu && selected != null) {
      await _activeSlot?.service.requestNodeGeometry(selected);
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
    _liveTextTimer?.cancel();
    _previewTimer?.cancel();
    _switchTimer?.cancel();
    for (final slot in _slots.clear()) {
      slot.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final html = ref.watch(workspaceProvider.select((s) => s.activePage?.html));
    final generating = ref.watch(
      workspaceProvider.select((s) => s.isGenerating),
    );

    // Muat ulang saat halaman aktif berganti atau HTML-nya berubah.
    // `activePage` mengembalikan instance baru setiap halaman berubah, jadi
    // listener ini menangkap pergantian halaman DAN perubahan HTML.
    ref.listen<AppPage?>(
      workspaceProvider.select((s) => s.activePage),
      (_, page) => _renderPage(page?.id, page?.html),
    );

    ref.listen<String?>(
      workspaceProvider.select((s) => s.selectedNodeId),
      (_, id) => _activeSlot?.service.selectNode(id),
    );
    ref.listen<String?>(
      workspaceProvider.select((s) => s.hoveredNodeId),
      (_, id) => _activeSlot?.service.hoverNode(id),
    );
    ref.listen<bool>(
      workspaceProvider.select((s) => s.selectionMode),
      (_, enabled) => _activeSlot?.service.setSelectionMode(enabled),
    );

    // Pratinjau live saat generate: dokumen parsial diganti di tempat tanpa
    // navigasi, jadi bridge & posisi gulir tetap.
    ref.listen<String?>(
      generationStreamProvider.select((s) => s.previewHtml),
      (_, html) => _schedulePreview(html),
    );

    final display = _displaySlot;
    final active = _activeSlot;
    final activeError = active?.error;
    Widget content;
    if (!_ready) {
      content = const _WebviewLoading();
    } else if (activeError != null) {
      content = _WebviewError(message: activeError, onRetry: _retryRender);
    } else if (display != null) {
      // WebView halaman yang tampil; dokumennya sudah hidup di cache.
      content = KeyedSubtree(
        key: ValueKey(display.pageId),
        child: display.service.buildView(),
      );
    } else if (active != null) {
      content = const _WebviewLoading();
    } else {
      content = const _PreviewEmptyState();
    }

    // Bingkai (border, radius, bilah browser) disediakan pemanggil agar
    // WebView bisa mengisi penuh area tanpa clipping tambahan.
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        // Halaman tanpa HTML tetap menampilkan empty state di atas WebView-nya
        // (dokumen kosong itu perlu hidup untuk pratinjau saat generate).
        final showEmpty =
            display != null &&
            display.pageId == _activeId &&
            (html == null || html.isEmpty);
        return ColoredBox(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RepaintBoundary(child: content),
              if (showEmpty) const _PreviewEmptyState(),
              if (_menuGeometry != null && _editingNodeId == null)
                _positionMenu(size),
              if (_editingNodeId != null && _editingRect != null)
                _positionEditor(size),
              // Halaman lama tetap terlihat selama render pertama halaman
              // baru; indikator hanya muncul bila render terasa lambat.
              if (_switching) const _PageSwitchLoading(),
              // Selama generate halaman read-only: klik & gulir tidak
              // diteruskan ke WebView.
              if (generating) const AbsorbPointer(child: SizedBox.expand()),
              // Saat berpindah halaman, klik ke halaman lama ditahan supaya
              // tidak memicu navigasi/editor di dokumen yang akan ditinggal.
              if (_switching && !generating)
                const AbsorbPointer(child: SizedBox.expand()),
              const GenerationCanvasOverlay(),
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
            _activeSlot?.service.selectNode(null);
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

/// Satu halaman yang punya WebView sendiri.
///
/// Selama tersimpan di [PageViewCache], dokumennya tetap hidup: skrip, gambar,
/// dan posisi gulir tidak hilang, jadi kembali ke halaman ini tidak memuat
/// ulang apa pun.
class _PageSlot {
  _PageSlot({required this.pageId, required this.service});

  final String pageId;
  final CanvasWebviewService service;
  StreamSubscription<CanvasSelectEvent>? subscription;
  late Future<void> initFuture;

  bool ready = false;
  String? error;

  /// HTML yang benar-benar sudah dimuat. `null` = dokumen kosong.
  String? html;
  bool rendered = false;

  /// HTML yang sedang tampil di WebView (bisa dokumen parsial saat generate).
  String? displayedHtml;

  /// Dokumen parsial terakhir yang sudah dikirim ke WebView.
  String? appliedPreview;

  /// Posisi gulir terakhir di dokumen ini (CSS px).
  double scrollX = 0;
  double scrollY = 0;

  void dispose() {
    CanvasServiceRegistry.unregister(pageId);
    unawaited(subscription?.cancel());
    unawaited(service.dispose());
  }
}

class _PageSwitchLoading extends StatelessWidget {
  const _PageSwitchLoading();

  @override
  Widget build(BuildContext context) {
    // Halaman lama tetap terlihat utuh; yang muncul hanya garis progres tipis
    // di tepi atas kanvas, seperti bilah pemuatan browser.
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: 2.5,
          width: double.infinity,
          child: LinearProgressIndicator(
            minHeight: 2.5,
            color: context.palette.primary,
            backgroundColor: Colors.transparent,
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
