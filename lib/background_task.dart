// バックグラウンドでの壁紙変更処理などを行うためのコード

import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'notification_service.dart';

const String wallpaperTaskName = 'com.example.dailyWallpaperTask';
const String defaultWallpaperKey = 'default_wallpaper_path';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    await NotificationService.init(requestPermission: false);

    final now = DateTime.now();
    final key = '${now.month}-${now.day}'; // 現在の月日を「月-日」の文字列キーとして生成する
    const lastUpdatedKey = 'last_updated_date';
    final prefs = await SharedPreferences.getInstance();

    final lastUpdated = prefs.getString(lastUpdatedKey); // 本日すでに壁紙の更新処理が完了しているかチェックする
    if (lastUpdated == key) {
      return Future.value(true);
    }

    final todayMemo = prefs.getString('memo_$key'); // 本日の日付に紐づくメモを取得
    if (todayMemo != null && todayMemo.isNotEmpty) {
      const targetHour = 0;
      const targetMinute = 0;
      final formattedDate = '${now.month}/${now.day}';
      final notificationText = '$formattedDateは$todayMemoの誕生日です！おめでとう🎉';
      // 現在時刻が目標時刻（00:00）を過ぎているか判定し、通知を即時表示またはスケジュール登録する
      if (now.hour > targetHour ||
          (now.hour == targetHour && now.minute >= targetMinute)) {
        await NotificationService.showMemoNotification(notificationText);
      } else {
        await NotificationService.scheduleDailyNotification(
          'HAPPY BIRTHDAY🎉',
          notificationText,
          targetHour,
          targetMinute,
        );
      }
    }

    var imagePath = prefs.getString(key); // 本日の日付に設定された個別画像のパスを読み込む
    if (imagePath == null || imagePath.isEmpty) {
      imagePath = prefs.getString(defaultWallpaperKey);
    }

    if (imagePath != null && imagePath.isNotEmpty) { // 有効な画像パスが存在する場合、デバイスの壁紙を自動で変更
      try {
        await AsyncWallpaper.setWallpaper(
          WallpaperRequest(
            target: WallpaperTarget.home,
            sourceType: WallpaperSourceType.file,
            source: imagePath,
            goToHome: false,
          ),
        );
        // 本日の更新が成功したことを記録する
        await prefs.setString(lastUpdatedKey, key);
      } catch (error) {
        debugPrint('自動壁紙変更に失敗しました: $error');
      }
    }
    // タスクが正常に完了したことをWorkmanagerに伝える
    return Future.value(true);
  });
}
