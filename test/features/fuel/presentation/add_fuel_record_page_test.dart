import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_garage/features/fuel/presentation/add_fuel_record_page.dart';
import 'package:my_garage/features/vehicles/data/vehicle.dart';

void main() {
  final testVehicle = Vehicle(
    id: 'v-1',
    userId: 'u-1',
    model: 'Yamaha MT-07',
    year: 2022,
    initialMileage: 500,
    currentMileage: 1000,
    acquisitionCost: 350000,
    createdAt: DateTime(2022, 1, 1),
  );

  Widget createWidgetUnderTest({Vehicle? vehicle}) {
    return ProviderScope(
      child: MaterialApp(
        home: AddFuelRecordPage(vehicle: vehicle ?? testVehicle),
      ),
    );
  }

  testWidgets('displays current mileage as initial value and in helper text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('1000'), findsOneWidget);
    expect(find.text('目前里程：1000 公里'), findsOneWidget);
  });

  testWidgets(
      'shows validation error when entered mileage is lower than current mileage',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Enter lower mileage
    final odometerField = find.widgetWithText(TextFormField, '里程');
    await tester.enterText(odometerField, '800');

    // Scroll to and tap submit button
    final submitButton = find.text('儲存加油紀錄');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    // Verify error message
    expect(find.text('里程不能低於目前里程 (1000 公里)'), findsOneWidget);
  });

  testWidgets(
      'passes validation when entered mileage is greater than or equal to current mileage',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    final odometerField = find.widgetWithText(TextFormField, '里程');
    await tester.enterText(odometerField, '1200');

    final submitButton = find.text('儲存加油紀錄');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    // The odometer error should not be shown
    expect(find.text('里程不能低於目前里程 (1000 公里)'), findsNothing);
  });
}
