import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';
import '../../data/catalog/provider_models.dart';
import 'model_card.dart';

/// Hasil pemilihan model dari [showModelPickerDialog].
class ModelPickerResult {
  const ModelPickerResult({required this.modelId, required this.customModels});

  /// Id model polos yang dipakai provider.
  final String modelId;

  /// Model di luar saran provider yang ditambahkan pengguna.
  final List<String> customModels;
}

/// Dialog pemilih model untuk provider terpilih.
///
/// Isinya hybrid: saran model statis provider (bila ada) + model yang
/// ditambahkan pengguna sendiri lewat "Tambah Model". Mengetuk satu kartu
/// langsung memilih model itu dan menutup dialog.
Future<ModelPickerResult?> showModelPickerDialog(
  BuildContext context, {
  required String? catalogId,
  required String selectedModel,
  required List<String> customModels,
}) {
  return showDialog<ModelPickerResult>(
    context: context,
    builder: (dialogContext) => _ModelPickerDialog(
      catalogId: catalogId,
      selectedModel: selectedModel,
      customModels: customModels,
    ),
  );
}

class _ModelPickerDialog extends StatefulWidget {
  const _ModelPickerDialog({
    required this.catalogId,
    required this.selectedModel,
    required this.customModels,
  });

  final String? catalogId;
  final String selectedModel;
  final List<String> customModels;

  @override
  State<_ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends State<_ModelPickerDialog> {
  final _newModelController = TextEditingController();
  late final List<String> _custom;
  bool _adding = false;

  ProviderModelSet? get _set =>
      ProviderModelCatalog.forProvider(widget.catalogId);

  @override
  void initState() {
    super.initState();
    _custom = List.of(widget.customModels);
  }

  @override
  void dispose() {
    _newModelController.dispose();
    super.dispose();
  }

  void _select(String id) {
    Navigator.of(context)
        .pop(ModelPickerResult(modelId: id, customModels: List.of(_custom)));
  }

  /// Menambahkan id model yang diketik, lalu langsung memakainya.
  void _addCustom() {
    final id = _newModelController.text.trim();
    if (id.isEmpty) return;
    final inCatalog = _set?.models.any((model) => model.id == id) ?? false;
    if (!inCatalog && !_custom.contains(id)) _custom.add(id);
    _newModelController.clear();
    _select(id);
  }

  @override
  Widget build(BuildContext context) {
    final set = _set;
    final suggestions = set?.models ?? const <ProviderModel>[];

    return AlertDialog(
      title: const Text('Pilih Model'),
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
                  ),
                  const SizedBox(height: 8),
                ],
                // Model kustom tampil apa adanya: alias provider bukan bagian
                // dari id, jadi menampilkan `alias/id` di sini memancing
                // pengguna menyalin/mengetik id yang tidak dikenal provider.
                for (final id in _custom) ...[
                  ModelCard(
                    label: id,
                    name: 'Model kustom',
                    modelId: id,
                    selected: id == widget.selectedModel,
                    onTap: () => _select(id),
                  ),
                  const SizedBox(height: 8),
                ],
                if (_adding) _buildNewModelRow() else _buildAddModelCard(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
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
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: const Row(
          children: [
            Icon(Icons.add, size: 18, color: AppColors.accentPrimary),
            SizedBox(width: 8),
            Text(
              'Tambah Model',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.accentPrimary,
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
            decoration: const InputDecoration(
              hintText: 'e.g. "gpt-4o"',
              isDense: true,
            ),
            onSubmitted: (_) => _addCustom(),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _addCustom,
          child: const Text('Tambah', style: TextStyle(fontSize: 12.5)),
        ),
      ],
    );
  }
}
