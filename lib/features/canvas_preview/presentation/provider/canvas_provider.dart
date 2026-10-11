import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prompt_editor/domain/ai_response.dart';
import '../../../prompt_editor/domain/prompt_templates.dart';
import '../../../provider_config/data/datasources/ai_api_service.dart';
import '../../../provider_config/presentation/providers/provider_config_provider.dart';
import '../../domain/viewport_mode.dart';
import '../../domain/dom_tree.dart';

enum ChatRole { user, assistant, error }

/// Mode tampilan area utama, mengikuti pola Design/Dev ala Figma.
enum OutputMode { design, dev }

class CanvasMessage {
  const CanvasMessage({
    required this.role,
    required this.text,
    this.kind = ChatMessageKind.chat,
  });

  final ChatRole role;
  final String text;

  /// Untuk pesan assistant: apakah ini balasan percakapan atau hasil UI.
  final ChatMessageKind kind;
}

/// Jenis isi pesan assistant di panel percakapan.
enum ChatMessageKind { chat, ui }

class CanvasState {
  const CanvasState({
    this.generatedHtml,
    this.viewport = ViewportMode.desktop,
    this.messages = const [],
    this.isGenerating = false,
    this.selectedToken,
    this.domTree,
    this.selectedNodeId,
    this.hoveredNodeId,
    this.outputMode = OutputMode.design,
    this.zoom = 1.0,
    this.generationStartedAt,
  });

  final String? generatedHtml;
  final ViewportMode viewport;
  final List<CanvasMessage> messages;
  final bool isGenerating;

  /// Design token yang dipilih dari sidebar/chat (FR-02).
  final DesignTokenPreset? selectedToken;

  /// Layers tree hasil parsing HTML terakhir.
  final DomTreeResult? domTree;

  /// Node yang dipilih di layers tree (sinkron dua arah dengan canvas).
  final String? selectedNodeId;

  /// Node yang sedang di-hover di layers tree.
  final String? hoveredNodeId;

  /// Design (canvas saja) atau Dev (canvas + code read-only).
  final OutputMode outputMode;

  /// Faktor zoom canvas (0.5 - 2.0).
  final double zoom;

  /// Waktu mulai generate yang sedang berjalan (null bila idle). Dipakai
  /// untuk menampilkan durasi agar state "Generating" tidak terasa hang.
  final DateTime? generationStartedAt;

  bool get hasCanvasContent => generatedHtml != null;

  CanvasState copyWith({
    String? generatedHtml,
    bool clearHtml = false,
    ViewportMode? viewport,
    List<CanvasMessage>? messages,
    bool? isGenerating,
    DesignTokenPreset? selectedToken,
    bool clearToken = false,
    DomTreeResult? domTree,
    String? selectedNodeId,
    bool clearSelection = false,
    String? hoveredNodeId,
    bool clearHover = false,
    OutputMode? outputMode,
    double? zoom,
    DateTime? generationStartedAt,
    bool clearGenerationStart = false,
  }) {
    return CanvasState(
      generatedHtml: clearHtml ? null : (generatedHtml ?? this.generatedHtml),
      viewport: viewport ?? this.viewport,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      selectedToken: clearToken ? null : (selectedToken ?? this.selectedToken),
      domTree: clearHtml ? null : (domTree ?? this.domTree),
      selectedNodeId: clearSelection
          ? null
          : (selectedNodeId ?? this.selectedNodeId),
      hoveredNodeId: clearHover ? null : (hoveredNodeId ?? this.hoveredNodeId),
      outputMode: outputMode ?? this.outputMode,
      zoom: zoom ?? this.zoom,
      generationStartedAt: clearGenerationStart
          ? null
          : (generationStartedAt ?? this.generationStartedAt),
    );
  }
}

final canvasProvider = NotifierProvider<CanvasNotifier, CanvasState>(
  CanvasNotifier.new,
);

class CanvasNotifier extends Notifier<CanvasState> {
  @override
  CanvasState build() => const CanvasState();

  void setViewport(ViewportMode mode) {
    if (mode == state.viewport) return;
    state = state.copyWith(viewport: mode);
  }

  void setOutputMode(OutputMode mode) {
    if (mode == state.outputMode) return;
    state = state.copyWith(outputMode: mode);
  }

  void setZoom(double zoom) {
    final clamped = zoom.clamp(0.5, 2.0);
    if (clamped == state.zoom) return;
    state = state.copyWith(zoom: clamped);
  }

  void zoomIn() => setZoom(state.zoom + 0.1);

  void zoomOut() => setZoom(state.zoom - 0.1);

  void resetZoom() => setZoom(1.0);

  /// Dipilih dari layers tree.
  void selectNode(String? id) {
    if (id == null) {
      if (state.selectedNodeId == null) return;
      state = state.copyWith(clearSelection: true);
      return;
    }
    state = state.copyWith(selectedNodeId: id);
  }

  /// Dipilih dari canvas (klik elemen).
  void selectNodeFromCanvas(String? id) => selectNode(id);

  void hoverNode(String? id) {
    if (id == null) {
      if (state.hoveredNodeId == null) return;
      state = state.copyWith(clearHover: true);
      return;
    }
    if (id == state.hoveredNodeId) return;
    state = state.copyWith(hoveredNodeId: id);
  }

  void setSelectedToken(DesignTokenPreset? token) {
    if (token == null) {
      if (state.selectedToken == null) return;
      state = state.copyWith(clearToken: true);
      return;
    }
    state = state.copyWith(selectedToken: token);
  }

  void clearCanvas() {
    state = state.copyWith(
      clearHtml: true,
      messages: const [],
      isGenerating: false,
      clearSelection: true,
      clearHover: true,
      clearGenerationStart: true,
    );
  }

  /// Alur generate/iterasi (FR-02, FR-04):
  /// validasi provider aktif -> kirim percakapan ke AI -> parse di Isolate
  /// -> stamp id -> update canvas + layers tree.
  Future<void> submitPrompt(
    String prompt, {
    DesignTokenPreset? designToken,
  }) async {
    if (state.isGenerating) return;
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final activeProvider = await ref
        .read(apiProviderRepositoryProvider)
        .getActiveProvider();

    if (activeProvider == null) {
      _appendMessage(
        const CanvasMessage(
          role: ChatRole.error,
          text:
              'Belum ada provider aktif. Buka Settings untuk mengonfigurasi API terlebih dahulu.',
        ),
      );
      return;
    }

    final userText = designToken == null
        ? trimmed
        : '$trimmed\n\n[Design Token: ${designToken.label}] ${designToken.promptFragment}';

    state = state.copyWith(
      isGenerating: true,
      generationStartedAt: DateTime.now(),
      messages: [
        ...state.messages,
        CanvasMessage(role: ChatRole.user, text: userText),
      ],
    );

    try {
      final payload = _buildMessagesPayload();
      final raw = await ref
          .read(aiApiServiceProvider)
          .generateUI(provider: activeProvider, messages: payload);
      final response = await classifyAiResponseInIsolate(raw);

      if (response.isChat) {
        // Balasan percakapan: tidak menyentuh canvas, cukup tampil di chat.
        state = state.copyWith(
          isGenerating: false,
          clearGenerationStart: true,
          messages: [
            ...state.messages,
            CanvasMessage(
              role: ChatRole.assistant,
              kind: ChatMessageKind.chat,
              text: response.text ?? '',
            ),
          ],
        );
        return;
      }

      // Balasan UI: parse + stamp id lalu render ke canvas.
      final html = response.html!;
      final tree = await buildDomTreeInIsolate(html);

      state = state.copyWith(
        generatedHtml: tree.stampedHtml,
        domTree: tree,
        isGenerating: false,
        clearGenerationStart: true,
        clearSelection: true,
        clearHover: true,
        messages: [
          ...state.messages,
          CanvasMessage(
            role: ChatRole.assistant,
            kind: ChatMessageKind.ui,
            text: html,
          ),
        ],
      );
    } on ApiConnectionException catch (e) {
      _appendMessage(CanvasMessage(role: ChatRole.error, text: e.message));
      state = state.copyWith(isGenerating: false, clearGenerationStart: true);
    } catch (e) {
      _appendMessage(
        CanvasMessage(
          role: ChatRole.error,
          text: 'Terjadi kesalahan saat memproses respons AI.\n${e.toString()}',
        ),
      );
      state = state.copyWith(isGenerating: false, clearGenerationStart: true);
    }
  }

  /// Konteks percakapan: system prompt + history user/assistant (FR-04).
  List<Map<String, dynamic>> _buildMessagesPayload() {
    return [
      {'role': 'system', 'content': uiSystemPrompt},
      ...state.messages
          .where((m) => m.role != ChatRole.error)
          .map(
            (m) => {
              'role': m.role == ChatRole.user ? 'user' : 'assistant',
              'content': m.text,
            },
          ),
    ];
  }

  void _appendMessage(CanvasMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }
}
