import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_garage/main.dart';

void main() {
  testWidgets('shows login form when signed out', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyGarageApp()));

    await tester.pump();

    expect(find.text('My Garage'), findsOneWidget);
    expect(find.text('帳號'), findsOneWidget);
    expect(find.text('密碼'), findsOneWidget);
    expect(find.text('登入'), findsOneWidget);
  });

  testWidgets('opens register page from login form', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MyGarageApp()));

    await tester.pump();
    await tester.tap(find.text('還沒有帳號？建立帳號'));
    await tester.pumpAndSettle();

    expect(find.text('建立帳號'), findsWidgets);
    expect(find.text('加入 My Garage'), findsOneWidget);
    expect(find.text('確認密碼'), findsOneWidget);
  });
}
