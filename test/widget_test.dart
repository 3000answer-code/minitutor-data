import 'package:flutter_test/flutter_test.dart';
import 'package:minitutor/main.dart';

void main() {
  testWidgets('miniTutor 앱 기본 로드 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const App2Gong());
    expect(find.text('miniTutor'), findsWidgets);
  });
}
