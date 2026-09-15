import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:birthday_wallpaper/tag_edit_panel.dart';

void main() {
  testWidgets('shows up to three matching tag suggestions', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagEditPanel(
            tags: const ['現在のタグ'],
            editingIndex: 0,
            isEditing: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            tagController: controller,
            tagFocusNode: focusNode,
            onToggleEditing: () {},
            onTagChanged: (_) {},
            onTagButtonTap: (_) {},
            onSubmit: () {},
            onTagTap: (_) {},
            suggestionTags: const [
              'Apple',
              'Pineapple',
              'APPLE',
              'Grape',
              'Apricot',
              'Banana',
            ],
            onTagSuggestionTap: (_) {},
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'ap');
    await tester.pump();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Pineapple'), findsOneWidget);
    expect(find.text('APPLE'), findsOneWidget);
    expect(find.text('Apricot'), findsNothing);
    expect(find.text('Grape'), findsNothing);
  });

  testWidgets('notifies when a suggestion is tapped', (tester) async {
    final controller = TextEditingController(text: 'ap');
    final focusNode = FocusNode();
    String? selectedTag;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TagEditPanel(
            tags: const ['現在のタグ'],
            editingIndex: 0,
            isEditing: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            tagController: controller,
            tagFocusNode: focusNode,
            onToggleEditing: () {},
            onTagChanged: (_) {},
            onTagButtonTap: (_) {},
            onSubmit: () {},
            onTagTap: (_) {},
            suggestionTags: const ['Apple'],
            onTagSuggestionTap: (tag) => selectedTag = tag,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apple'));
    expect(selectedTag, 'Apple');
  });
}
