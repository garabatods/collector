import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:collectorapp/main.dart';

void main() {
  testWidgets('shows splash screen at startup', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const CollectorApp(
        isSupabaseConfigured: false,
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('SYNCHRONIZING VAULT'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));

    expect(find.text('THE DIGITAL CURATOR'), findsOneWidget);
    expect(find.text('Access Archive'), findsOneWidget);
  });
}
