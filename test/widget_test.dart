import 'package:flutter_test/flutter_test.dart';
import 'package:pawan_biryani/main.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const PawanBiryaniApp());
    expect(find.text('Pawan Biryani'), findsWidgets);
  });
}
