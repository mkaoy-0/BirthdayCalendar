import 'package:flutter/material.dart';

class TagSearchPanel extends StatelessWidget {
  const TagSearchPanel({
    super.key,
    required this.tag,
    required this.dateTags,
    required this.dateMemos,
    required this.onClose,
    required this.onDateTap,
    required this.colorScheme,
  });

  final String tag;
  final Map<String, List<String>> dateTags;
  final Map<String, String> dateMemos;
  final VoidCallback onClose;
  final ValueChanged<String> onDateTap;
  final ColorScheme colorScheme;

  List<String> _matchingKeys() {
    final List<String> keys = [];
    dateTags.forEach((k, v) {
      if (v.contains(tag)) keys.add(k);
    });
    keys.sort((a, b) {
      // sort by MMDD numeric
      int toNum(String key) {
        final parts = key.split('-');
        final m = int.tryParse(parts[0]) ?? 0;
        final d = int.tryParse(parts[1]) ?? 0;
        return m * 100 + d;
      }
      return toNum(a).compareTo(toNum(b));
    });
    return keys;
  }

  String _formatKey(String key) {
    final parts = key.split('-');
    final m = int.tryParse(parts[0]) ?? 0;
    final d = int.tryParse(parts[1]) ?? 0;
    return '${m.toString().padLeft(2, '0')}${d.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final keys = _matchingKeys();
    final double width = MediaQuery.of(context).size.width * 0.78;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        elevation: 12,
        color: colorScheme.surface,
        child: SizedBox(
          width: width,
          height: MediaQuery.of(context).size.height,
          child: SafeArea(
            child: Column(
              children: [
                // Header: tag display
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 30.0, 12.0, 15.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.tertiary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.label,
                          color: colorScheme.onTertiary,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: colorScheme.onTertiary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                // List of matches
                Expanded(
                  child: keys.isEmpty
                      ? Center(
                          child: Text(
                            '該当する日付がありません',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 20.0),
                          itemCount: keys.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final key = keys[index];
                            final mmdd = _formatKey(key);
                            final memo = dateMemos[key] ?? '';
                            return InkWell(
                              onTap: () => onDateTap(key),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 55,
                                      child: Text(
                                        mmdd,
                                        style: TextStyle(
                                          color: colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          fontFamily: 'fantasy',
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 0),
                                    Expanded(
                                      child: Text(
                                        memo,
                                        style: TextStyle(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.9),
                                          fontSize: 12,
                                          fontFamily: 'sans-serif',
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Close button
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.tertiary.withValues(alpha: 0.85),
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      onPressed: onClose,
                      child: const Text(
                        '閉じる',
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
