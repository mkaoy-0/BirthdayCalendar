import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// 初期設定
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(initializationSettings);
    
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
  }

  /// 💡 解説サイトのロジックを組み込んだ時間指定関数
  static Future<void> scheduleDailyNotification(String memoTitle, String memoText, int hour, int minute) async {
    // 💡 予約する瞬間に、指定された時間の「次の出現タイミング」を正確に計算する
    final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

    await _notificationsPlugin.zonedSchedule(
      0,
      memoTitle,
      memoText,
      scheduledDate, // 💡 ここで計算した時間を渡す
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_memo_channel',
          '誕生日通知',
          channelDescription: '今日誕生日の子を通知します',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 💡 【解説サイトの肝】次の指定時間のタイミングを計算する関数
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    
    // 指定された「時」「分」で時間オブジェクトを作成
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        
    // もし計算した時間が「今の瞬間」よりも前（過去）なら、明日のその時間にセットする
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    return scheduledDate;
  }

  /// 即時通知用（5秒後テストで使ったものも一応残しておきます）
  static Future<void> showMemoNotification(String memoText) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_memo_channel', '毎日のメモ通知',
      importance: Importance.max, priority: Priority.high,
    );
    await _notificationsPlugin.show(1, '本日の予定・メモがあります', memoText, const NotificationDetails(android: androidDetails));
  }
}