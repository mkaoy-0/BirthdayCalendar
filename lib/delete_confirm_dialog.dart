// 画像削除時の確認ダイアログ表示

import 'package:flutter/material.dart';

class DeleteConfirmDialog extends StatelessWidget {
  const DeleteConfirmDialog({
    super.key,
    required this.colorScheme,
  });

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // 角をとがらせる
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(5.0),
        // ウィンドウの枠線はタイトルの文字色と揃える
        side: BorderSide(
          color: colorScheme.onSurface,
          width: 1.0,
        ),
      ),
      // タイトルの文字サイズを変更
      title: Text(
        '画像を削除しますか？',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      // ボタンを横幅いっぱい、半分ずつに配置する
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: const Text('YES'),
              ),
            ),
            const SizedBox(width: 12), // ボタンとボタンの間のすき間
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: const Text('NO'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}