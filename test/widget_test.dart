import 'package:flutter_test/flutter_test.dart';
import 'package:week06_notice_lab/main.dart';

void main() {
  testWidgets('NoticeApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NoticeApp());
    expect(find.text('공지사항'), findsOneWidget);
  });
}