import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin localNotifications =
FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings =
  DarwinInitializationSettings();
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(settings: initSettings);

  // 안드로이드 12, 13+ 권한 요청
  final androidImplementation = localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidImplementation != null) {
    await androidImplementation.requestNotificationsPermission();
    await androidImplementation.requestExactAlarmsPermission();
  }
}

// ✨ 에셋 이미지를 임시 파일로 복사하는 헬퍼 함수
Future<String> _saveImageToFile(String assetPath) async {
  final ByteData byteData = await rootBundle.load(assetPath);
  final Directory tempDir = await getTemporaryDirectory();
  final String fileName = assetPath.split('/').last; // 파일명만 추출
  final File file = File('${tempDir.path}/$fileName');

  await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
  return file.path;
}

// 즉시 발송 테스트용
Future<void> fireNotification(String name) async {
  await localNotifications.show(
    id: name.hashCode,
    title: '생일 축하드려요! 🎉',
    body: '오늘은 $name님의 생일입니다. 행복한 하루 보내세요!',
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'birthday_channel', '생일 알림',
        importance: Importance.max, priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

// ✨ 고유 텍스트와 이미지를 받도록 네임드 파라미터로 변경
Future<void> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required String imagePath,
  required tz.TZDateTime scheduledDate,
}) async {

  // 1. 이미지를 기기 임시 폴더로 복사
  final String localImagePath = await _saveImageToFile(imagePath);

  // 2. 안드로이드 알림 스타일 설정 (펼쳤을 땐 큰 이미지, 접혔을 땐 작은 아이콘)
  final BigPictureStyleInformation bigPictureStyle = BigPictureStyleInformation(
    FilePathAndroidBitmap(localImagePath), // 큰 이미지
    largeIcon: FilePathAndroidBitmap(localImagePath), // 우측 작은 아이콘
    contentTitle: title,
    summaryText: body,
    hideExpandedLargeIcon: true,
  );

  await localNotifications.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: scheduledDate,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        'birthday_channel', 'Birthday Notifications',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: bigPictureStyle, // ✨ 이미지 스타일 적용
      ),
      iOS: DarwinNotificationDetails(
        attachments: [DarwinNotificationAttachment(localImagePath)], // iOS 이미지 처리
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents: DateTimeComponents.dateAndTime,
  );
}