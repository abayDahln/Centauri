import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/theme.dart';
import '../domain/prompt_templates.dart';
import 'preset_provider.dart';

/// Launcher adaptif: dialog di desktop, bottom sheet di mobile.
void showPresetManagerSheet(BuildContext context) {
  final isWide = MediaQuery.sizeOf(context).width >= 720;
  if (isWide) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: AppColors.bgBase,
        insetPadding: const EdgeInsets.all(48),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.md,
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
        child: const SizedBox(
          width: 640,
          height: 560,
          child: PresetManagerView(),
        ),
      ),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bgBase,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
      side: BorderSide(color: AppColors.borderStrong),
    ),
    builder: (_) => const SizedBox(height: 600, child: PresetManagerView()),
  );
}

/// Manajer preset gaya + editor system prompt (Fase 4: Custom Bebas).
/// Preset bawaan hanya bisa dipakai; preset kustom bisa tambah/ubah/hapus.
class PresetManagerView extends ConsumerStatefulWidget {
  const PresetManagerView({super.key});

  @override
  ConsumerState<PresetManagerView> createState() => _PresetManagerViewState();
}

class _PresetManagerViewState extends ConsumerState<PresetManagerView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Gaya & System Prompt',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        TabBar(
          controller: _tabs,
          labelColor: AppColors.accentPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accentPrimary,
          tabs: const [Tab(text: 'Preset Gaya'), Tab(text: 'System Prompt')],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [_PresetList(), _SystemPromptEditor()],
          ),
        ),
      ],
    );
  }
}

class _PresetList extends ConsumerWidget {
  const _PresetList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(presetProvider);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            children: [
              const _ListCaption('BAWAAN'),
              for (final preset in designTokenPresets)
                _PresetTile(preset: preset, builtin: true),
              const SizedBox(height: 8),
              const _ListCaption('KUSTOM'),
              if (state.customPresets.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Belum ada preset kustom. Tambahkan gayamu sendiri, mis. "Neubrutalism Client X".',
                    style: AppText.caption,
                  ),
                ),
              for (final preset in state.customPresets)
                _PresetTile(preset: preset, builtin: false),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _editPreset(context, ref, null),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Tambah preset kustom'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editPreset(
    BuildContext context,
    WidgetRef ref,
    DesignTokenPreset? existing,
  ) async {
    final labelController = TextEditingController(text: existing?.label ?? '');
    final fragmentController = TextEditingController(
      text: existing?.promptFragment ?? 'Design direction: ',
    );
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Preset baru' : 'Ubah preset'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(
                  labelText: 'Nama (mis. Retro Diner)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fragmentController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Design direction (ditempel ke prompt)',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'label': labelController.text,
              'fragment': fragmentController.text,
            }),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final notifier = ref.read(presetProvider.notifier);
    if (existing == null) {
      notifier.addPreset(
        label: result['label'] ?? '',
        promptFragment: result['fragment'] ?? '',
      );
    } else {
      notifier.updatePreset(
        id: existing.id,
        label: result['label'] ?? '',
        promptFragment: result['fragment'] ?? '',
      );
    }
  }
}

class _PresetTile extends ConsumerWidget {
  const _PresetTile({required this.preset, required this.builtin});

  final DesignTokenPreset preset;
  final bool builtin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppColors.bgSurface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.sm,
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: ListTile(
        dense: true,
        title: Text(preset.label, style: AppText.uiSmall),
        subtitle: Text(
          preset.promptFragment,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption,
        ),
        trailing: builtin
            ? const Icon(
                Icons.lock_outline,
                size: 14,
                color: AppColors.textDisabled,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    tooltip: 'Ubah',
                    onPressed: () {
                      final list = ref.read(presetProvider);
                      final current = list.customPresets
                          .where((p) => p.id == preset.id)
                          .firstOrNull;
                      if (current == null) return;
                      _editHere(context, ref, current);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: AppColors.statusError,
                    ),
                    tooltip: 'Hapus',
                    onPressed: () => ref
                        .read(presetProvider.notifier)
                        .deletePreset(preset.id),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _editHere(
    BuildContext context,
    WidgetRef ref,
    DesignTokenPreset existing,
  ) async {
    final labelController = TextEditingController(text: existing.label);
    final fragmentController = TextEditingController(
      text: existing.promptFragment,
    );
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ubah preset'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fragmentController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Design direction',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'label': labelController.text,
              'fragment': fragmentController.text,
            }),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result == null) return;
    ref
        .read(presetProvider.notifier)
        .updatePreset(
          id: existing.id,
          label: result['label'] ?? '',
          promptFragment: result['fragment'] ?? '',
        );
  }
}

class _SystemPromptEditor extends ConsumerStatefulWidget {
  const _SystemPromptEditor();

  @override
  ConsumerState<_SystemPromptEditor> createState() =>
      _SystemPromptEditorState();
}

class _SystemPromptEditorState extends ConsumerState<_SystemPromptEditor> {
  late final TextEditingController _controller;
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(presetProvider);
    if (!_initialized) {
      _controller = TextEditingController(
        text: state.effectiveSystemPrompt,
      );
      _initialized = true;
    }
    final isCustomized =
        state.systemPromptOverride?.trim().isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isCustomized
                ? 'Menggunakan system prompt kustom.'
                : 'Menggunakan system prompt bawaan Centauri.',
            style: AppText.caption,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 8,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(
                fontFamily: AppFonts.monoFamily,
                fontFamilyFallback: AppFonts.monoFallback,
                fontSize: 11.5,
                height: 1.6,
              ),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isCustomized
                      ? () async {
                          await ref
                              .read(presetProvider.notifier)
                              .setSystemPromptOverride(null);
                          setState(() {
                            _controller.text = uiSystemPrompt;
                          });
                        }
                      : null,
                  child: const Text('Kembalikan bawaan'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () async {
                    await ref
                        .read(presetProvider.notifier)
                        .setSystemPromptOverride(_controller.text);
                    if (mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('System prompt disimpan.'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListCaption extends StatelessWidget {
  const _ListCaption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.textDisabled,
        ),
      ),
    );
  }
}
