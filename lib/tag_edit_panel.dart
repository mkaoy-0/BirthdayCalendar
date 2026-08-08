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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            icon: Icon(
              isEditing ? Icons.check : Icons.label,
              color: colorScheme.onPrimary,
            ),
            onPressed: onToggleEditing,
            tooltip: isEditing ? 'タグ編集を終了' : 'タグを編集',
          ),
        ),
        if (isEditing) ...[
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(
              minWidth: 48,
              maxWidth: 240,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IntrinsicWidth(
              child: TextField(
                controller: tagController,
                focusNode: tagFocusNode,
                autofocus: true,
                cursorColor: colorScheme.onPrimary,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration.collapsed(
                  hintText: '',
                ),
                onChanged: onTagChanged,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
          ),
        ] else if (tagText.isNotEmpty) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              tagText,
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
