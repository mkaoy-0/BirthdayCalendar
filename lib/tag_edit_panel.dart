import 'package:flutter/material.dart';

class TagEditPanel extends StatefulWidget {
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
    required this.suggestionTags,
    required this.onTagSuggestionTap,
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
  final List<String> suggestionTags;
  final ValueChanged<String> onTagSuggestionTap;

  @override
  State<TagEditPanel> createState() => _TagEditPanelState();
}

class _TagEditPanelState extends State<TagEditPanel> {
  List<String> get _suggestions {
    final query = widget.tagController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final suggestions = <String>[];
    for (final tag in widget.suggestionTags) {
      if (tag.isEmpty ||
          !tag.toLowerCase().contains(query) ||
          suggestions.contains(tag)) {
        continue;
      }
      suggestions.add(tag);
      if (suggestions.length == 3) break;
    }
    return suggestions;
  }

  @override
  Widget build(BuildContext context) {
    const tagFontsize = 11.0;

    Widget buildTagItem(int index) {
      final isBlank = index == widget.tags.length;
      final isSelected = widget.editingIndex == index;
      final text = isBlank ? '' : widget.tags[index];

      if (isSelected) {
        return Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: widget.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: IntrinsicWidth(
              child: TextField(
                controller: widget.tagController,
                focusNode: widget.tagFocusNode,
                autofocus: false,
                cursorColor: widget.colorScheme.onPrimaryContainer,
                style: TextStyle(
                  color: widget.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                  fontSize: tagFontsize,
                ),
                decoration: const InputDecoration.collapsed(hintText: ''),
                onChanged: (value) {
                  widget.onTagChanged(value);
                  setState(() {});
                },
                onSubmitted: (_) => widget.onSubmit(),
              ),
            ),
          ),
        );
      }

      return InkWell(
        onTap: () => widget.onTagButtonTap(index),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 28,
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: widget.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: text.isEmpty
                    ? widget.colorScheme.onTertiary
                    : widget.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
                fontSize: tagFontsize,
              ),
            ),
          ),
        ),
      );
    }

    final suggestions = widget.isEditing ? _suggestions : const <String>[];

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: widget.isEditing
                ? widget.colorScheme.tertiaryContainer
                : widget.colorScheme.primary.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
          ),
          child: IconButton(
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            iconSize: 14,
            icon: Icon(
              widget.isEditing ? Icons.check : Icons.label,
              color: widget.isEditing
                  ? widget.colorScheme.onTertiaryContainer.withValues(
                      alpha: 0.6,
                    )
                  : widget.colorScheme.onPrimary,
            ),
            onPressed: widget.onToggleEditing,
            tooltip: widget.isEditing ? 'タグ編集を終了' : 'タグを編集',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: widget.isEditing
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (suggestions.isNotEmpty)
                      SizedBox(
                        height: 28,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: suggestions
                                .map(
                                  (suggestion) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: InkWell(
                                      onTap: () => widget
                                          .onTagSuggestionTap(suggestion),
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        height: 24,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: widget
                                              .colorScheme.tertiaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            suggestion,
                                            style: TextStyle(
                                              color: widget.colorScheme
                                                  .onTertiaryContainer,
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
                    SizedBox(
                      height: 30,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List<Widget>.generate(
                            widget.tags.length + 1,
                            buildTagItem,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : widget.tags.isEmpty
              ? const SizedBox(height: 30)
              : SizedBox(
                  height: 30,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.tags
                          .map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => widget.onTagTap(tag),
                                child: Container(
                                  height: 28,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.colorScheme.tertiary.withValues(
                                      alpha: 0.82,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: widget.colorScheme.onTertiary,
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
