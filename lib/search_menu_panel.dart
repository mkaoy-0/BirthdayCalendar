import 'package:flutter/material.dart';

class MenuSearchPanel extends StatefulWidget {
  const MenuSearchPanel({
    super.key,
    required this.defaultImagePath,
    required this.onPickDefaultWallpaper,
    required this.dateMemos,
    required this.dateTags,
    required this.onTagTap,
    required this.onDateTap,
    required this.showSearch,
    required this.colorScheme,
  });

  final String defaultImagePath;
  final Future<void> Function() onPickDefaultWallpaper;
  final Map<String, String> dateMemos;
  final Map<String, List<String>> dateTags;
  final ValueChanged<String> onTagTap;
  final ValueChanged<String> onDateTap;
  final bool showSearch;
  final ColorScheme colorScheme;

  @override
  State<MenuSearchPanel> createState() => _MenuSearchPanelState();
}

class _MenuSearchPanelState extends State<MenuSearchPanel> {
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  List<Map<String, String>> searchResults = [];

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    final lowerQuery = query.toLowerCase();
    final List<Map<String, String>> results = [];

    if (lowerQuery.isNotEmpty) {
      final seenTags = <String>{};
      for (final tagList in widget.dateTags.values) {
        for (final tag in tagList) {
          if (tag.isEmpty || seenTags.contains(tag)) continue;
          if (tag.toLowerCase().contains(lowerQuery)) {
            seenTags.add(tag);
            results.add({'kind': 'tag', 'text': tag});
          }
        }
      }

      widget.dateMemos.forEach((key, memo) {
        if (memo.toLowerCase().contains(lowerQuery)) {
          final parts = key.split('-');
          final paddedDate = parts.length == 2
              ? '${parts[0].padLeft(2, '0')}${parts[1].padLeft(2, '0')}'
              : key.replaceAll('-', '');
            results.add({
              'kind': 'memo',
              'key': key,
              'date': paddedDate,
              'text': memo,
            });
        }
      });

      results.sort((a, b) {
        final kindA = a['kind'] ?? '';
        final kindB = b['kind'] ?? '';
        if (kindA != kindB) {
          return kindA == 'tag' ? -1 : 1;
        }
        if (kindA == 'memo') {
          return (a['date'] ?? '').compareTo(b['date'] ?? '');
        }
        return (a['text'] ?? '').compareTo(b['text'] ?? '');
      });
    }

    setState(() {
      searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    double searchResultFontsize = 12.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        searchFocusNode.unfocus();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          if (!widget.showSearch)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextButton.icon(
                icon: Icon(Icons.image, color: widget.colorScheme.onPrimaryContainer.withValues(alpha: 0.75)),
                label: Text(
                  widget.defaultImagePath.isNotEmpty
                      ? 'デフォルト壁紙を変更'
                      : 'デフォルト壁紙を設定',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: widget.colorScheme.primaryContainer.withValues(alpha: 0.8),
                  foregroundColor: widget.colorScheme.onPrimaryContainer.withValues(alpha: 0.75),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                onPressed: widget.onPickDefaultWallpaper,
              ),
            ),
          if (widget.showSearch) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                focusNode: searchFocusNode,
                controller: searchController,
                style: TextStyle(
                  color: widget.colorScheme.onPrimary,
                  fontFamily: 'OpenSans',
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: '検索キーワードを入力',
                  hintStyle: TextStyle(
                    color: widget.colorScheme.onPrimary.withValues(alpha: 0.7),
                    fontFamily: 'OpenSans',
                  ),
                  filled: true,
                  fillColor: widget.colorScheme.onPrimary.withValues(alpha: 0.12),
                  prefixIcon: Icon(
                    Icons.search,
                    color: widget.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _runSearch,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: searchController.text.isEmpty
                  ? const SizedBox.shrink()
                  : searchResults.isEmpty
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '一致する結果はありません',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.colorScheme.onPrimary.withValues(
                              alpha: 0.75,
                            ),
                            fontSize: searchResultFontsize,
                            fontFamily: 'OpenSans',
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 104.0),
                      itemCount: searchResults.length,
                      // アイテム間のスペースを設定
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final result = searchResults[index];
                        final isTag = result['kind'] == 'tag';
                        final cardWidth =
                            MediaQuery.of(context).size.width * 0.82;
                        return Align(
                          alignment: Alignment.topCenter,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12.0),
                            onTap: () {
                              searchFocusNode.unfocus();
                              if (isTag) {
                                widget.onTagTap(result['text'] ?? '');
                              } else {
                                widget.onDateTap(result['key'] ?? '');
                              }
                            },
                            child: Container(
                              width: cardWidth,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 13.0,
                              ),
                              decoration: BoxDecoration(
                                color: isTag
                                    ? widget.colorScheme.primaryContainer.withValues(alpha: 0.6) // タグの背景色
                                    : widget.colorScheme.onPrimary.withValues(
                                        alpha: 0.12,
                                      ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: isTag
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.label,
                                          color: widget.colorScheme.onPrimary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            result['text'] ?? '',
                                            style: TextStyle(
                                              color:
                                                  widget.colorScheme.onPrimary,
                                              fontFamily: 'Georgia',
                                              fontSize: searchResultFontsize,
                                            ),
                                            softWrap: true,
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${result['date'] ?? ''}    ',
                                            style: TextStyle(
                                              color:
                                                  widget.colorScheme.onPrimary,
                                              fontFamily: 'Times New Roman',
                                              fontSize:
                                                  searchResultFontsize + 2,
                                              fontWeight: FontWeight.bold,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          TextSpan(
                                            text: (result['text'] ?? '')
                                                .replaceAll(
                                              '\n',
                                              ' ',
                                            ),
                                            style: TextStyle(
                                              color:
                                                  widget.colorScheme.onPrimary,
                                              fontFamily: 'Georgia',
                                              fontSize: searchResultFontsize,
                                            ),
                                          ),
                                        ],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left,
                                    ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
