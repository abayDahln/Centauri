import 'package:centauri/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App boots to the canvas preview screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: CentauriApp()));
    await tester.pump();

    expect(find.text('Centauri Canvas'), findsOneWidget);
    expect(find.text('Live Canvas Preview'), findsOneWidget);
    expect(find.text('Generate UI'), findsOneWidget);
  });
}
