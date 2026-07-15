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
}
