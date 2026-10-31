import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:streak/core/extensions/date_extensions.dart';
import 'package:streak/features/habits/data/habit.dart';
import 'package:streak/features/habits/pages/home_page.dart';
import 'package:streak/features/habits/state/habits_controller.dart';

import 'support/app_harness.dart';

Finder _button(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );

bool _done(WidgetTester tester, String id) => tester
    .element(find.byType(HomePage))
    .read<HabitsController>()
    .byId(id)!
    .isCompletedOn(AppClock.today());

void main() {
  useEmptyStore();

  testWidgets('a normal check asks first, then completes', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Bug 1 = Insulin Killer'),
    ]);
    await pumpScreen(tester, const HomePage());

    await tester.tap(_button('Mark Bug 1 = Insulin Killer as done'));
    await tester.pumpAndSettle();

    expect(find.text('Mark as completed?'), findsOneWidget);
    expect(find.text('Bug 1 = Insulin Killer'), findsWidgets);
    expect(find.text('Yes, complete it'), findsOneWidget);
    expect(find.byIcon(LucideIcons.check), findsWidgets);
    expect(_done(tester, 'a'), isFalse);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Mark as completed?'), findsNothing);
    expect(_done(tester, 'a'), isFalse);

    await tester.tap(_button('Mark Bug 1 = Insulin Killer as done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, complete it'));
    await tester.pumpAndSettle();
    expect(_done(tester, 'a'), isTrue);
  });

  testWidgets('undoing a normal habit still skips the prompt', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'a', name: 'Read', done: lastDays(1)),
    ]);
    await pumpScreen(tester, const HomePage());

    await tester.tap(_button('Mark Read as not done'));
    await tester.pumpAndSettle();

    expect(find.text('Mark as completed?'), findsNothing);
    expect(_done(tester, 'a'), isFalse);
  });

  testWidgets('avoid still asks to log a relapse', (tester) async {
    await seedHabits(tester, [
      testHabit(id: 'c', name: 'Hhuu', kind: HabitKind.negative),
    ]);
    await pumpScreen(tester, const HomePage());

    await tester.tap(_button('Log a relapse for Hhuu'));
    await tester.pumpAndSettle();

    expect(find.text('Log a relapse?'), findsOneWidget);
    expect(find.text('Yes, log it'), findsOneWidget);
    expect(find.text('Mark as completed?'), findsNothing);
  });
}
