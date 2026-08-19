import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawan_biryani/main.dart';
import 'package:pawan_biryani/network/api_client.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    ApiClient.instance.init();
    await tester.pumpWidget(const ProviderScope(child: PawanBiryaniApp()));
    expect(find.text('Pawan Biryani'), findsWidgets);
    // Flush the initial /settings request timers (connect/receive timeout +
    // retries) so no timer is left pending.
    await tester.pump(const Duration(seconds: 120));
  });
}