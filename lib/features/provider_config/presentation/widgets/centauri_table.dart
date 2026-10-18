import 'package:flutter/material.dart';

import '../../../../app/config/theme.dart';

/// Definisi satu kolom pada [CentauriTable].
class CentauriTableColumn<T> {
  const CentauriTableColumn({
    required this.label,
    required this.cell,
    this.flex = 1,
    this.width,
    this.alignment = Alignment.centerLeft,
  });

  /// Judul kolom pada baris header.
  final String label;

  /// Pembangun isi sel untuk satu baris.
  final Widget Function(BuildContext context, T row) cell;

  /// Bobot lebar bila [width] null.
  final int flex;

  /// Lebar tetap (mis. kolom aksi). Menang atas [flex].
  final double? width;

  final Alignment alignment;
}

/// Tabel ringan: baris header + baris data dengan hover dan highlight.
///
/// Sengaja tanpa sorting/pagination — hanya presentasi. Dipakai layar daftar
/// provider dan layar katalog.
class CentauriTable<T> extends StatelessWidget {
  const CentauriTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowKey,
    this.onRowTap,
    this.isSelected,
    this.isActive,
    this.emptyState,
  });

  final List<CentauriTableColumn<T>> columns;
  final List<T> rows;

  /// Kunci unik per baris (untuk `ValueKey`).
  final String Function(T row) rowKey;

  final void Function(T row)? onRowTap;

  /// Baris terpilih → latar [AppColors.selectionBg].
  final bool Function(T row)? isSelected;

  /// Baris aktif → border aksen.
  final bool Function(T row)? isActive;

  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return emptyState ?? const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        for (final row in rows) ...[
          _buildRow(context, row),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Row(
        children: [
          for (final column in columns)
            _box(
              column,
              child: Text(
                column.label,
                style: AppText.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, T row) {
    final selected = isSelected?.call(row) ?? false;
    final active = isActive?.call(row) ?? false;
    return _TableRow(
      key: ValueKey(rowKey(row)),
      selected: selected,
      active: active,
      onTap: onRowTap == null ? null : () => onRowTap!(row),
      children: [
        for (final column in columns)
          _box(column, child: column.cell(context, row)),
      ],
    );
  }

  Widget _box(CentauriTableColumn<T> column, {required Widget child}) {
    final content = Align(alignment: column.alignment, child: child);
    final width = column.width;
    if (width != null) return SizedBox(width: width, child: content);
    return Expanded(flex: column.flex, child: content);
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({
    super.key,
    required this.children,
    required this.selected,
    required this.active,
    this.onTap,
  });

  final List<Widget> children;
  final bool selected;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.selected
        ? AppColors.selectionBg
        : (_hovered ? AppColors.hoverBg : AppColors.bgSurface);
    final borderColor = widget.active
        ? AppColors.accentPrimary
        : AppColors.borderSubtle;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: borderColor),
            borderRadius: AppRadius.md,
          ),
          child: Row(children: widget.children),
        ),
      ),
    );
  }
}
