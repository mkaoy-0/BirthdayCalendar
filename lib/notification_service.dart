import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 初期設定
  static Future<void> init({bool requestPermission = true}) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    WidgetsFlutterBinding.ensureInitialized();

    await _notificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    // Android システムに通知チャンネルを作成・登録する処理を追加
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_memo_channel', // AndroidNotificationDetails で使っているIDと同じにする
        '誕生日通知', // 設定画面に表示される名前
        description: '今日誕生日の子を通知します',
        importance: Importance.max,
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      // チャンネルを OS に登録（これで設定画面に「誕生日通知」というカテゴリが出現します）
      await androidImplementation?.createNotificationChannel(channel);

      if (requestPermission) {
        final bool? grantedNotificationPermission = await androidImplementation
            ?.requestNotificationsPermission();
        if (grantedNotificationPermission != true) {
          debugPrint('通知権限が付与されませんでした。通知が届かない可能性があります。');
        }
        // アラームとリマインダーの許可
        await androidImplementation?.requestExactAlarmsPermission();
      }
    }
  }

  /// 時間指定関数
  static Future<void> scheduleDailyNotification(
    String memoTitle,
    String memoText,
    int hour,
    int minute,
  ) async {
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    await _notificationsPlugin.zonedSchedule(
      0,
      memoTitle,
      memoText,
      scheduledDate, // 計算した時間を渡す
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_memo_channel',
          '誕生日通知',
          channelDescription: '今日誕生日の子を通知します',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 次の指定時間のタイミングを計算する関数
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // 指定された「時」「分」で時間オブジェクトを作成
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // もし計算した時間が「今の瞬間」よりも前（過去）なら、明日のその時間にセットする
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 即時通知用
  static Future<void> showMemoNotification(String memoText) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'daily_memo_channel',
          '毎日のメモ通知',
          importance: Importance.max,
          priority: Priority.high,
        );
    await _notificationsPlugin.show(
      1,
      null,
      memoText,
      const NotificationDetails(android: androidDetails),
    );
  }
}
