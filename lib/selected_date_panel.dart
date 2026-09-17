import 'package:flutter/material.dart';

import 'tag_edit_panel.dart';

class SelectedDatePanel extends StatelessWidget {
  const SelectedDatePanel({
    super.key,
    required this.month,
    required this.day,
    required this.memo,
    required this.tags,
    required this.hasImage,
    required this.isEditingMemo,
    required this.isEditingTags,
    required this.editingTagIndex,
    required this.colorScheme,
    required this.memoController,
    required this.tagController,
    required this.tagFocusNode,
    required this.suggestionTags,
    required this.onToggleMemoEditing,
    required this.onMemoChanged,
    required this.onMemoSubmitted,
    required this.onSaveMemo,
    required this.onUpdateImage,
    required this.onDeleteImage,
    required this.onToggleTagEditing,
    required this.onTagChanged,
    required this.onTagButtonTap,
    required this.onTagSuggestionTap,
    required this.onTagTap,
    required this.onSubmitTag,
  });

  final int month;
  final int day;
  final String memo;
  final List<String> tags;
  final bool hasImage;
  final bool isEditingMemo;
  final bool isEditingTags;
  final int? editingTagIndex;
  final ColorScheme colorScheme;
  final TextEditingController memoController;
  final TextEditingController tagController;
  final FocusNode tagFocusNode;
  final List<String> suggestionTags;
  final VoidCallback onToggleMemoEditing;
  final ValueChanged<String> onMemoChanged;
  final ValueChanged<String> onMemoSubmitted;
  final Future<void> Function() onSaveMemo;
  final VoidCallback onUpdateImage;
  final VoidCallback onDeleteImage;
  final VoidCallback onToggleTagEditing;
  final ValueChanged<String> onTagChanged;
  final ValueChanged<int> onTagButtonTap;
  final ValueChanged<String> onTagSuggestionTap;
  final ValueChanged<String> onTagTap;
  final VoidCallback onSubmitTag;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${month.toString().padLeft(2, '0')}${day.toString().padLeft(2, '0')}';

    return Column(
      children: [
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.onSurface, width: 0.6),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: isEditingMemo
                            ? colorScheme.primary
                            : colorScheme.secondary,
                      ),
                      onPressed: onToggleMemoEditing,
                    ),
                    IconButton(
                      icon: Icon(Icons.image, color: colorScheme.secondary),
                      onPressed: onUpdateImage,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: hasImage
                            ? colorScheme.error.withValues(alpha: 0.8)
                            : colorScheme.surfaceVariant,
                      ),
                      onPressed: hasImage ? onDeleteImage : null,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'fantasy',
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isEditingMemo)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4, right: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: memoController,
                    autofocus: true,
                    style: const TextStyle(fontFamily: 'sans-serif', fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'メモを入力',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      border: const UnderlineInputBorder(),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: colorScheme.outline,
                          width: 1.5,
                        ),
                      ),
                    ),
                    onChanged: onMemoChanged,
                    onSubmitted: onMemoSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.check, color: colorScheme.primary),
                  onPressed: onSaveMemo,
                ),
              ],
            ),
          ),
        if (!isEditingMemo && memo.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 4),
              child: Text(
                memo,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: 'serif',
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: TagEditPanel(
              tags: tags,
              editingIndex: editingTagIndex,
              isEditing: isEditingTags,
              colorScheme: colorScheme,
              tagController: tagController,
              tagFocusNode: tagFocusNode,
              onToggleEditing: onToggleTagEditing,
              onTagChanged: onTagChanged,
              onTagButtonTap: onTagButtonTap,
              onSubmit: onSubmitTag,
              onTagTap: onTagTap,
              suggestionTags: suggestionTags,
              onTagSuggestionTap: onTagSuggestionTap,
            ),
          ),
        ],
      ],
    );
  }
}
