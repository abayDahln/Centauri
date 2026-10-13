import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/local_storage_service.dart';
import '../domain/prompt_templates.dart';

/// State preset: gabungan bawaan + kustom, plus override system prompt.
class PresetState {
  const PresetState({
    this.customPresets = const [],
    this.systemPromptOverride,
  });

  final List<DesignTokenPreset> customPresets;

  /// Null = pakai bawaan [uiSystemPrompt].
  final String? systemPromptOverride;

  /// Semua preset (bawaan dulu, lalu kustom).
  List<DesignTokenPreset> get all => [
    ...designTokenPresets,
    ...customPresets,
  ];

  String get effectiveSystemPrompt {
    final override = systemPromptOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
    return uiSystemPrompt;
  }
}

final presetProvider = NotifierProvider<PresetNotifier, PresetState>(
  PresetNotifier.new,
);

/// CRUD preset kustom + editor system prompt (Fase 4: Custom Bebas).
/// Preset bawaan tidak bisa diubah/dihapus — hanya dipakai.
class PresetNotifier extends Notifier<PresetState> {
  @override
  PresetState build() => _load();

  PresetState _load() {
    final storage = LocalStorageService();
    final customs = <DesignTokenPreset>[];
    final raw = storage.readCustomPresetsJson();
    if (raw != null && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final preset = DesignTokenPreset.fromJson(item);
              if (preset.id.isNotEmpty &&
                  preset.promptFragment.trim().isNotEmpty) {
                customs.add(preset);
              }
            }
          }
        }
      } catch (_) {
        // Data korup: mulai dari kosong, jangan crash.
      }
    }
    return PresetState(
      customPresets: customs,
      systemPromptOverride: storage.readSystemPromptOverride(),
    );
  }

  void _persist() {
    LocalStorageService().writeCustomPresetsJson(
      jsonEncode(state.customPresets.map((p) => p.toJson()).toList()),
    );
  }

  /// Tambah preset kustom. Mengembalikan id baru.
  String addPreset({required String label, required String promptFragment}) {
    final preset = DesignTokenPreset(
      id: 'custom_${const Uuid().v4()}',
      label: label.trim().isEmpty ? 'Custom' : label.trim(),
      promptFragment: promptFragment.trim(),
      builtin: false,
    );
    state = PresetState(
      customPresets: [...state.customPresets, preset],
      systemPromptOverride: state.systemPromptOverride,
    );
    _persist();
    return preset.id;
  }

  void updatePreset({
    required String id,
    required String label,
    required String promptFragment,
  }) {
    final updated = state.customPresets
        .map(
          (p) => p.id == id
              ? p.copyWith(
                  label: label.trim().isEmpty ? p.label : label.trim(),
                  promptFragment: promptFragment.trim().isEmpty
                      ? p.promptFragment
                      : promptFragment.trim(),
                )
              : p,
        )
        .toList();
    state = PresetState(
      customPresets: updated,
      systemPromptOverride: state.systemPromptOverride,
    );
    _persist();
  }

  void deletePreset(String id) {
    state = PresetState(
      customPresets: state.customPresets.where((p) => p.id != id).toList(),
      systemPromptOverride: state.systemPromptOverride,
    );
    _persist();
  }

  Future<void> setSystemPromptOverride(String? value) async {
    await LocalStorageService().writeSystemPromptOverride(value);
    state = PresetState(
      customPresets: state.customPresets,
      systemPromptOverride: value?.trim().isEmpty == true ? null : value,
    );
  }
}
