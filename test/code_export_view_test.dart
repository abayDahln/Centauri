import 'package:centauri/app/config/theme.dart';
import 'package:centauri/features/code_exporter/presentation/code_export_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/pump_app.dart';

Widget _wrap(String html) {
  return testApp(
    theme: AppTheme.lightTheme,
    home: Scaffold(
      body: SizedBox(
        width: 420,
        height: 720,
        child: CodeExportView(htmlSource: html),
      ),
    ),
  );
}

void main() {
  testWidgets('menampilkan keadaan gagal saat kode Alpha kosong', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap('   '));

    expect(find.text('Kode tidak bisa diubah'), findsOneWidget);
    expect(find.text('Pakai HTML'), findsNothing);
    // Aksi salin dan unduh tidak boleh aktif saat tidak ada kode.
    final copy = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Salin'),
    );
    expect(copy.onPressed, isNull);
  });

  testWidgets('menampilkan kode dan jumlah karakter saat konversi berhasil', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap('<html><body><h1>Halo</h1></body></html>'));

    expect(find.textContaining('karakter'), findsOneWidget);
    expect(find.text('Kode tidak bisa diubah'), findsNothing);
  });
}
