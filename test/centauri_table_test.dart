import 'package:centauri/app/config/theme.dart';
import 'package:centauri/features/provider_config/presentation/widgets/centauri_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

Widget _host(Widget child) => testApp(home: Scaffold(body: child));

void main() {
  group('CentauriTable', () {
    testWidgets('renders header labels and row cells', (tester) async {
      await tester.pumpWidget(
        _host(
          CentauriTable<String>(
            columns: [
              CentauriTableColumn<String>(
                label: 'Nama',
                cell: (_, row) => Text(row),
              ),
              CentauriTableColumn<String>(
                label: 'Aksi',
                width: 80,
                cell: (_, row) => const Icon(Icons.delete_outline),
              ),
            ],
            rows: const ['alpha', 'beta'],
            rowKey: (row) => row,
          ),
        ),
      );

      expect(find.text('Nama'), findsOneWidget);
      expect(find.text('Aksi'), findsOneWidget);
      expect(find.text('alpha'), findsOneWidget);
      expect(find.text('beta'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNWidgets(2));
    });

    testWidgets('fires onRowTap with the tapped row', (tester) async {
      String? tapped;
      await tester.pumpWidget(
        _host(
          CentauriTable<String>(
            columns: [
              CentauriTableColumn<String>(
                label: 'Nama',
                cell: (_, row) => Text(row),
              ),
            ],
            rows: const ['alpha', 'beta'],
            rowKey: (row) => row,
            onRowTap: (row) => tapped = row,
          ),
        ),
      );

      await tester.tap(find.text('beta'));
      expect(tapped, 'beta');
    });

    testWidgets('renders emptyState and no header when there are no rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CentauriTable<String>(
            columns: [
              CentauriTableColumn<String>(
                label: 'Nama',
                cell: (_, row) => Text(row),
              ),
            ],
            rows: const [],
            rowKey: (row) => row,
            emptyState: const Text('kosong'),
          ),
        ),
      );

      expect(find.text('kosong'), findsOneWidget);
      expect(find.text('Nama'), findsNothing);
    });

    testWidgets('highlights the selected row with selection background', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          CentauriTable<String>(
            columns: [
              CentauriTableColumn<String>(
                label: 'Nama',
                cell: (_, row) => Text(row),
              ),
            ],
            rows: const ['alpha', 'beta'],
            rowKey: (row) => row,
            isSelected: (row) => row == 'beta',
          ),
        ),
      );

      final highlighted = tester
          .widgetList<Container>(find.byType(Container))
          .where((container) {
            final decoration = container.decoration;
            return decoration is BoxDecoration &&
                decoration.color == AppColors.selectionBg;
          });

      expect(highlighted.length, 1);
    });
  });
}
