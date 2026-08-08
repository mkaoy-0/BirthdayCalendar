import 'package:flutter/material.dart';

class TagSearchPanel extends StatelessWidget {
  const TagSearchPanel({
    super.key,
    required this.tag,
    required this.dateTags,
    required this.dateMemos,
    required this.onClose,
    required this.colorScheme,
  });

  final String tag;
  final Map<String, String> dateTags;
  final Map<String, String> dateMemos;
  final VoidCallback onClose;
  final ColorScheme colorScheme;

  List<String> _matchingKeys() {
    final List<String> keys = [];
    dateTags.forEach((k, v) {
      if (v == tag) keys.add(k);
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
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.label,
                            color: colorScheme.onPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                          padding: const EdgeInsets.all(12),
                          itemCount: keys.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final key = keys[index];
                            final mmdd = _formatKey(key);
                            final memo = dateMemos[key] ?? '';
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 76,
                                  child: Text(
                                    mmdd,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    memo,
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(0.9),
                                    ),
                                  ),
                                ),
                              ],
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
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      onPressed: onClose,
                      child: const Text('閉じる'),
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
