import 'package:universal_html/html.dart' as html;

Future<void> initNotifications() async {}  // no-op on web

Future<void> fireNotification(String name) async {
  String? permission = html.Notification.permission;
  if (permission != 'granted') {
    permission = await html.Notification.requestPermission();
  }
  if (permission == 'granted') {
    html.Notification(
      '생일 축하드려요! 🎉',
      body: '오늘은 $name님의 생일입니다. 행복한 하루 보내세요!',
    );
  }
}

Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required String imagePath,
  required dynamic scheduledDate,
}) async {}  // no-op on web