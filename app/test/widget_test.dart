import 'package:flutter_test/flutter_test.dart';
import 'package:jronix_vpn/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const JRonixVpnApp());
    expect(find.byType(JRonixVpnApp), findsOneWidget);
  });
}
