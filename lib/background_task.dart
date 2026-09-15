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
    final key = '${now.month}-${now.day}';
    const lastUpdatedKey = 'last_updated_date';
    final prefs = await SharedPreferences.getInstance();

    final lastUpdated = prefs.getString(lastUpdatedKey);
    if (lastUpdated == key) {
      return Future.value(true);
    }

    final todayMemo = prefs.getString('memo_$key');
    if (todayMemo != null && todayMemo.isNotEmpty) {
      const targetHour = 0;
      const targetMinute = 0;
      final formattedDate = '${now.month}/${now.day}';
      final notificationText = '$formattedDateは$todayMemoの誕生日です！おめでとう🎉';
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

    var imagePath = prefs.getString(key);
    if (imagePath == null || imagePath.isEmpty) {
      imagePath = prefs.getString(defaultWallpaperKey);
    }

    if (imagePath != null && imagePath.isNotEmpty) {
      try {
        await AsyncWallpaper.setWallpaper(
          WallpaperRequest(
            target: WallpaperTarget.home,
            sourceType: WallpaperSourceType.file,
            source: imagePath,
            goToHome: false,
          ),
        );
        await prefs.setString(lastUpdatedKey, key);
      } catch (error) {
        debugPrint('自動壁紙変更に失敗しました: $error');
      }
    }
    return Future.value(true);
  });
}
