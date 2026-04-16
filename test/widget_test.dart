import 'package:flutter_test/flutter_test.dart';
import 'package:asometutor/main.dart';

void main() {
  testWidgets('Asome Tutor 앱 기본 로드 테스트', (WidgetTester tester) async {
    await tester.pumpWidget(const AsomeTutorApp());
    expect(find.text('Asome Tutor'), findsWidgets);
  });
}
