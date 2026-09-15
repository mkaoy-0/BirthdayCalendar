import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:birthday_wallpaper/search_menu_panel.dart';
import 'package:birthday_wallpaper/tag_search_panel.dart';

void main() {
  testWidgets('memo search result reports its date key', (tester) async {
    String? selectedKey;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuSearchPanel(
            defaultImagePath: '',
            onPickDefaultWallpaper: () async {},
            dateMemos: const {'3-14': '誕生日メモ'},
            dateTags: const {},
            onTagTap: (_) {},
            onDateTap: (key) => selectedKey = key,
            showSearch: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '誕生日');
    await tester.pump();
    final memoResult = find.byWidgetPredicate(
      (widget) =>
          widget is RichText &&
          widget.text.toPlainText().contains('誕生日メモ'),
    );
    await tester.tap(memoResult);

    expect(selectedKey, '3-14');
  });

  testWidgets('search mode does not show the default wallpaper button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuSearchPanel(
            defaultImagePath: '',
            onPickDefaultWallpaper: () async {},
            dateMemos: const {},
            dateTags: const {},
            onTagTap: (_) {},
            onDateTap: (_) {},
            showSearch: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
        ),
      ),
    );

    expect(find.text('デフォルト壁紙を設定'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('tag search date reports its date key', (tester) async {
    String? selectedKey;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagSearchPanel(
            tag: '旅行',
            dateTags: const {'8-10': ['旅行']},
            dateMemos: const {'8-10': '旅行の予定'},
            onClose: () {},
            onDateTap: (key) => selectedKey = key,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
        ),
      ),
    );

    await tester.tap(find.text('旅行の予定'));

    expect(selectedKey, '8-10');
  });
}
