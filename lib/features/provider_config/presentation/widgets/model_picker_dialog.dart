import 'package:flutter/material.dart';

import '../../../../app/config/app_palette.dart';
import '../../../../app/config/theme.dart';
import '../../../../app/l10n/l10n.dart';
import '../../data/catalog/provider_models.dart';
import 'model_card.dart';

/// Hasil pemilihan model dari [showModelPickerDialog].
class ModelPickerResult {
  const ModelPickerResult({
    required this.modelId,
    required this.customModels,
    required this.removedModels,
  });

  /// Id model polos yang dipakai provider.
  final String modelId;

  /// Model di luar saran provider yang ditambahkan pengguna.
  final List<String> customModels;

  /// Model template yang dihapus khusus untuk provider ini.
  final List<String> removedModels;
}

/// Dialog pemilih model untuk provider terpilih.
///
/// Isinya hybrid: saran model statis provider (bila ada) + model yang
/// ditambahkan pengguna sendiri lewat "Tambah Model". Mengetuk satu kartu
/// langsung memilih model itu dan menutup dialog. Tombol hapus di tiap kartu
/// hanya mengubah daftar milik provider ini — template aslinya tidak tersentuh.
Future<ModelPickerResult?> showModelPickerDialog(
  BuildContext context, {
  required String? catalogId,
  required String selectedModel,
  required List<String> customModels,
  required List<String> removedModels,
}) {
  return showDialog<ModelPickerResult>(
    context: context,
    builder: (dialogContext) => _ModelPickerDialog(
      catalogId: catalogId,
      selectedModel: selectedModel,
      customModels: customModels,
      removedModels: removedModels,
    ),
  );
}

class _ModelPickerDialog extends StatefulWidget {
  const _ModelPickerDialog({
    required this.catalogId,
    required this.selectedModel,
    required this.customModels,
    required this.removedModels,
  });

  final String? catalogId;
  final String selectedModel;
  final List<String> customModels;
  final List<String> removedModels;

  @override
  State<_ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends State<_ModelPickerDialog> {
  final _newModelController = TextEditingController();
  late final List<String> _custom;
  late final List<String> _removed;
  bool _adding = false;

  /// Daftar berubah (ada model ditambah/dihapus) tanpa memilih model baru.
  bool _changed = false;

  ProviderModelSet? get _set =>
      ProviderModelCatalog.forProvider(widget.catalogId);

  @override
  void initState() {
    super.initState();
    _custom = List.of(widget.customModels);
    _removed = List.of(widget.removedModels);
  }

  @override
  void dispose() {
    _newModelController.dispose();
    super.dispose();
  }

  ModelPickerResult _result(String modelId) => ModelPickerResult(
    modelId: modelId,
    customModels: List.of(_custom),
    removedModels: List.of(_removed),
  );

  void _select(String id) {
    Navigator.of(context).pop(_result(id));
  }

  /// Tutup tanpa memilih model: perubahan daftar tetap dibawa keluar.
  void _close() {
    Navigator.of(context).pop(_changed ? _result(widget.selectedModel) : null);
  }

  /// Menambahkan id model yang diketik, lalu langsung memakainya.
  void _addCustom() {
    final id = _newModelController.text.trim();
    if (id.isEmpty) return;
    final inCatalog = _set?.models.any((model) => model.id == id) ?? false;
    if (inCatalog) {
      // Model template yang pernah dihapus: cukup tampilkan kembali.
      _removed.remove(id);
    } else if (!_custom.contains(id)) {
      _custom.add(id);
    }
    _newModelController.clear();
    _select(id);
  }

  /// Menghapus model dari daftar provider ini saja.
  void _delete(String id) {
    setState(() {
      _changed = true;
      if (_custom.contains(id)) {
        _custom.remove(id);
      } else if (!_removed.contains(id)) {
        _removed.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final set = _set;
    final suggestions = (set?.models ?? const <ProviderModel>[])
        .where((model) => !_removed.contains(model.id))
        .toList();

    return AlertDialog(
      title: Text(l10n.modelPickerTitle),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      content: SizedBox(
        width: 420,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 460),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final model in suggestions) ...[
                  ModelCard(
                    label: set!.label(model),
                    name: model.name,
                    modelId: model.id,
                    selected: model.id == widget.selectedModel,
                    onTap: () => _select(model.id),
                    // Model yang sedang dipakai tidak bisa dihapus: pilih
                    // model lain dulu agar provider tidak tanpa model.
                    onDelete: model.id == widget.selectedModel
                        ? null
                        : () => _delete(model.id),
                  ),
                  const SizedBox(height: 8),
                ],
                // Model kustom tampil apa adanya: alias provider bukan bagian
                // dari id, jadi menampilkan `alias/id` di sini memancing
                // pengguna menyalin/mengetik id yang tidak dikenal provider.
                for (final id in _custom) ...[
                  ModelCard(
                    label: id,
                    name: l10n.modelPickerCustom,
                    modelId: id,
                    selected: id == widget.selectedModel,
                    onTap: () => _select(id),
                    onDelete: id == widget.selectedModel
                        ? null
                        : () => _delete(id),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_adding) _buildNewModelRow() else _buildAddModelCard(),
              ],
            ),
          ),
        ),
      ),
      actions: [TextButton(onPressed: _close, child: Text(l10n.commonCancel))],
    );
  }

  Widget _buildAddModelCard() {
    return InkWell(
      onTap: () => setState(() => _adding = true),
      borderRadius: AppRadius.lg,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lg,
          border: Border.all(color: context.palette.borderStrong),
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 18, color: context.palette.primary),
            const SizedBox(width: 8),
            Text(
              context.l10n.modelPickerAddModel,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: context.palette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewModelRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _newModelController,
            autofocus: true,
            style: const TextStyle(
              fontFamily: AppFonts.monoFamily,
              fontFamilyFallback: AppFonts.monoFallback,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: context.l10n.modelPickerIdHint,
              isDense: true,
            ),
            onSubmitted: (_) => _addCustom(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addCustom,
          child: Text(
            context.l10n.commonAdd,
            style: const TextStyle(fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}
