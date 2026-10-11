import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prompt_editor/domain/html_parser.dart';
import '../../../prompt_editor/domain/prompt_templates.dart';
import '../../../provider_config/data/datasources/ai_api_service.dart';
import '../../../provider_config/presentation/providers/provider_config_provider.dart';
import '../../domain/viewport_mode.dart';

enum ChatRole { user, assistant, error }

class CanvasMessage {
  const CanvasMessage({
    required this.role,
    required this.text,
  });

  final ChatRole role;
  final String text;
}

class CanvasState {
  const CanvasState({
    this.generatedHtml,
    this.viewport = ViewportMode.desktop,
    this.messages = const [],
    this.isGenerating = false,
  });

  final String? generatedHtml;
  final ViewportMode viewport;
  final List<CanvasMessage> messages;
  final bool isGenerating;

  bool get hasCanvasContent => generatedHtml != null;

  CanvasState copyWith({
    String? generatedHtml,
    bool clearHtml = false,
    ViewportMode? viewport,
    List<CanvasMessage>? messages,
    bool? isGenerating,
  }) {
    return CanvasState(
      generatedHtml: clearHtml ? null : (generatedHtml ?? this.generatedHtml),
      viewport: viewport ?? this.viewport,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
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

  void clearCanvas() {
    state = state.copyWith(
      clearHtml: true,
      messages: const [],
      isGenerating: false,
    );
  }

  /// Alur generate/iterasi (FR-02, FR-04):
  /// validasi provider aktif -> kirim percakapan ke AI -> parse di Isolate
  /// -> update canvas.
  Future<void> submitPrompt(
    String prompt, {
    DesignTokenPreset? designToken,
  }) async {
    if (state.isGenerating) return;
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) return;

    final activeProvider =
        await ref.read(apiProviderRepositoryProvider).getActiveProvider();

    if (activeProvider == null) {
      _appendMessage(const CanvasMessage(
        role: ChatRole.error,
        text: 'Belum ada provider aktif. Buka Settings untuk mengonfigurasi API terlebih dahulu.',
      ));
      return;
    }

    final userText = designToken == null
        ? trimmed
        : '$trimmed\n\n[Design Token: ${designToken.label}] ${designToken.promptFragment}';

    state = state.copyWith(
      isGenerating: true,
      messages: [...state.messages, CanvasMessage(role: ChatRole.user, text: userText)],
    );

    try {
      final payload = _buildMessagesPayload();
      final raw = await ref
          .read(aiApiServiceProvider)
          .generateUI(provider: activeProvider, messages: payload);
      final html = await parseHtmlInIsolate(raw);

      state = state.copyWith(
        generatedHtml: html,
        isGenerating: false,
        messages: [
          ...state.messages,
          CanvasMessage(role: ChatRole.assistant, text: html),
        ],
      );
    } on ApiConnectionException catch (e) {
      _appendMessage(CanvasMessage(role: ChatRole.error, text: e.message));
      state = state.copyWith(isGenerating: false);
    } catch (_) {
      _appendMessage(const CanvasMessage(
        role: ChatRole.error,
        text: 'Terjadi kesalahan tak terduga saat memproses respons AI.',
      ));
      state = state.copyWith(isGenerating: false);
    }
  }

  /// Konteks percakapan: system prompt + history user/assistant (FR-04).
  List<Map<String, dynamic>> _buildMessagesPayload() {
    return [
      {'role': 'system', 'content': uiSystemPrompt},
      ...state.messages
          .where((m) => m.role != ChatRole.error)
          .map((m) => {
                'role': m.role == ChatRole.user ? 'user' : 'assistant',
                'content': m.text,
              }),
    ];
  }

  void _appendMessage(CanvasMessage message) {
    state = state.copyWith(messages: [...state.messages, message]);
  }
}
