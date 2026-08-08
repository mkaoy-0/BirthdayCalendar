import 'package:flutter/material.dart';

class TagEditPanel extends StatelessWidget {
  const TagEditPanel({
    super.key,
    required this.tagText,
    required this.isEditing,
    required this.colorScheme,
    required this.tagController,
    required this.tagFocusNode,
    required this.onToggleEditing,
    required this.onTagChanged,
    required this.onSubmit,
  });

  final String tagText;
  final bool isEditing;
  final ColorScheme colorScheme;
  final TextEditingController tagController;
  final FocusNode tagFocusNode;
  final VoidCallback onToggleEditing;
  final ValueChanged<String> onTagChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    double tagFontsize = 11.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            constraints: const BoxConstraints.tightFor(
              width: 24,
              height: 24,
            ),
            padding: EdgeInsets.zero,
            iconSize: 14,
            icon: Icon(
              isEditing ? Icons.check : Icons.label,
              color: colorScheme.onSecondary,
            ),
            onPressed: onToggleEditing,
            tooltip: isEditing ? 'タグ編集を終了' : 'タグを編集',
          ),
        ),
        if (isEditing) ...[
          const SizedBox(width: 8),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: IntrinsicWidth(
              stepWidth: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 12,
                  maxWidth: 240,
                ),
                child: TextField(
                  controller: tagController,
                  focusNode: tagFocusNode,
                  autofocus: true,
                  cursorColor: colorScheme.onSecondaryContainer,
                  style: TextStyle(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w500,
                    fontSize: tagFontsize,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: const InputDecoration.collapsed(
                    hintText: '',
                  ),
                  onChanged: onTagChanged,
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
            ),
          ),
        ] else if (tagText.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                tagText,
                style: TextStyle(
                  color: colorScheme.onSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: tagFontsize,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
