import 'package:flutter/material.dart';

class TagEditPanel extends StatelessWidget {
  const TagEditPanel({
    super.key,
    required this.tags,
    required this.editingIndex,
    required this.isEditing,
    required this.colorScheme,
    required this.tagController,
    required this.tagFocusNode,
    required this.onToggleEditing,
    required this.onTagChanged,
    required this.onTagButtonTap,
    required this.onSubmit,
    required this.onTagTap,
  });

  final List<String> tags;
  final int? editingIndex;
  final bool isEditing;
  final ColorScheme colorScheme;
  final TextEditingController tagController;
  final FocusNode tagFocusNode;
  final VoidCallback onToggleEditing;
  final ValueChanged<String> onTagChanged;
  final ValueChanged<int> onTagButtonTap;
  final VoidCallback onSubmit;
  final ValueChanged<String> onTagTap;

  @override
  Widget build(BuildContext context) {
    double tagFontsize = 11.0;

    Widget buildTagItem(int index) {
      final isBlank = index == tags.length;
      final isSelected = editingIndex == index;
      final text = isBlank ? '' : tags[index];

      if (isSelected) {
        return Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: IntrinsicWidth(
              child: TextField(
                controller: tagController,
                focusNode: tagFocusNode,
                autofocus: false,
                cursorColor: colorScheme.onPrimaryContainer,
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                  fontSize: tagFontsize,
                ),
                decoration: const InputDecoration.collapsed(hintText: ''),
                onChanged: onTagChanged,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
          ),
        );
      }

      return InkWell(
        onTap: () => onTagButtonTap(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              text.isEmpty ? '' : text,
              style: TextStyle(
                color: text.isEmpty
                    ? colorScheme.onTertiary
                    : colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
                fontSize: tagFontsize,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isEditing
                ? colorScheme.tertiaryContainer
                : colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            iconSize: 14,
            icon: Icon(
              isEditing ? Icons.check : Icons.label,
              color: isEditing
                  ? colorScheme.onTertiaryContainer
                  : colorScheme.onPrimary,
            ),
            onPressed: onToggleEditing,
            tooltip: isEditing ? 'タグ編集を終了' : 'タグを編集',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isEditing
              ? SizedBox(
                  height: 40,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List<Widget>.generate(
                        tags.length + 1,
                        (index) => buildTagItem(index),
                      ),
                    ),
                  ),
                )
              : tags.isEmpty
              ? const SizedBox(height: 40)
              : SizedBox(
                  height: 40,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tags
                          .map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => onTagTap(tag),
                                child: Container(
                                  height: 28,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiary.withValues(
                                      alpha: 0.82,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: colorScheme.onTertiary,
                                        fontWeight: FontWeight.w500,
                                        fontSize: tagFontsize,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
