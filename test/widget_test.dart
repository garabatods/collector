import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:collectorapp/main.dart';

void main() {
  testWidgets('shows splash screen at startup', (WidgetTester tester) async {
    await tester.pumpWidget(const CollectorApp(isSupabaseConfigured: false));

    final splashImage = tester.widget<Image>(find.byType(Image));
    expect(
      splashImage.image,
      const AssetImage('assets/img/Splash_ownzith.png'),
    );

    await tester.pump(const Duration(milliseconds: 3000));

    expect(find.text('Access your archive'), findsOneWidget);
  });
}
