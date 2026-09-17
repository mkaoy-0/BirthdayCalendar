import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:birthday_wallpaper/calendar_view.dart';

void main() {
  testWidgets('shows calendar month and reports tapped day', (tester) async {
    final pageController = PageController(initialPage: 1200 + 5 - 1);
    int? tappedDay;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: const Size(360, 800),
              ),
              child: CalendarView(
                pageController: pageController,
                currentMonth: 5,
                selectedDay: null,
                daysInMonth: const {5: 31},
                selectedImages: const {},
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                now: DateTime(2026, 5, 15),
                onMonthChanged: (_) {},
                onDayTap: (day) => tappedDay = day,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('5月'), findsOneWidget);
    expect(find.text('01'), findsOneWidget);

    await tester.tap(find.text('01'));
    expect(tappedDay, 1);

    pageController.dispose();
  });
}
