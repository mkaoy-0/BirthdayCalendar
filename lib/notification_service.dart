import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 初期設定（Android & iOS対応）
  static Future<void> init({bool requestPermission = true}) async {
    // Android用の初期設定
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS（Darwin）用の初期設定
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false, // 後から個別にリクエストするため一旦false
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // 両方のプラットフォームの設定をまとめる
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    WidgetsFlutterBinding.ensureInitialized();

    await _notificationsPlugin.initialize(initializationSettings);

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));

    // --- Android固有の設定・権限リクエスト ---
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'daily_memo_channel',
        '誕生日通知',
        description: '今日誕生日の子を通知します',
        importance: Importance.max,
      );

      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
          >();

      await androidImplementation?.createNotificationChannel(channel);

      if (requestPermission) {
        final bool? grantedNotificationPermission = await androidImplementation
            ?.requestNotificationsPermission();
        if (grantedNotificationPermission != true) {
          debugPrint('Androidの通知権限が付与されませんでした。');
        }
        await androidImplementation?.requestExactAlarmsPermission();
      }
    }

    // --- iOS固有の権限リクエスト ---
    if (Platform.isIOS && requestPermission) {
      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
          >();
      
      final bool? grantedIOSPermission = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      if (grantedIOSPermission != true) {
        debugPrint('iOSの通知権限が付与されませんでした。');
      }
    }
  }

  /// 時間指定関数（Android & iOS対応）
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
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_memo_channel',
          '誕生日通知',
          channelDescription: '今日誕生日の子を通知します',
          importance: Importance.max,
          priority: Priority.high,
        ),
        // iOS用の通知詳細設定を追加
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
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

    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 即時通知（Android & iOS対応）
  static Future<void> showMemoNotification(String memoText) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'daily_memo_channel',
      '毎日のメモ通知',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notificationsPlugin.show(
      1,
      null,
      memoText,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }
}