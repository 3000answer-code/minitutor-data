import 'package:flutter_test/flutter_test.dart';
import 'package:app2gong/main.dart';

void main() {
  testWidgets('2공 앱 기본 로드 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const App2Gong());
    expect(find.text('2공'), findsOneWidget);
  });
}
