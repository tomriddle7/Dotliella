import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'notification_service_mobile.dart'
if (dart.library.html) 'notification_service_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  await initNotifications();
  await checkAndShowBirthdayNotifications();

  runApp(const MyApp());
}

Future<void> checkAndShowBirthdayNotifications() async {
  try {
    final String response =
    await rootBundle.loadString('assets/data/members.json');
    final List<dynamic> data = json.decode(response);

    DateTime now = DateTime.now();

    for (var member in data) {
      String name = member['name'];
      String birthdayStr = member['birthday'];

      List<String> dateParts = birthdayStr.split('-');
      int month = int.parse(dateParts[dateParts.length - 2]);
      int day = int.parse(dateParts.last);

      if (now.month == month && now.day == day) {
        await fireNotification(name);
      }
    }
  } catch (e) {
    debugPrint('데이터 불러오기 실패: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DotLive*',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'DotLive*'),
    );
  }
}

class IdolMember {
  final String name;
  final int birthMonth;
  final int birthDay;
  final String image;
  final String body;

  IdolMember({
    required this.name,
    required this.birthMonth,
    required this.birthDay,
    required this.image,
    required this.body,
  });

  factory IdolMember.fromJson(Map<String, dynamic> json) {
    return IdolMember(
      name: json['name'],
      birthMonth: json['month'],
      birthDay: json['day'],
      image: json['image'],
      body: json['body'] ?? '${json['name']}의 생일을 축하해 주세요! 🎉',
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> birthWeekday = ['월', '화', '수', '목', '금', '토', '일'];

  List<IdolMember> nijidongList = [];
  bool isLoading = true;

  late PageController _pageController;
  final ValueNotifier<int> _currentPageNotifier = ValueNotifier<int>(0);
  final ValueNotifier<DateTime> _currentTimeNotifier =
  ValueNotifier<DateTime>(DateTime.now());
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadMembersData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _currentPageNotifier.dispose();
    _currentTimeNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadMembersData() async {
    try {
      final String jsonString =
      await rootBundle.loadString('assets/data/members.json');
      final List<dynamic> jsonData = jsonDecode(jsonString);

      nijidongList =
          jsonData.map((data) => IdolMember.fromJson(data)).toList();

      int nearestIndex = _getNearestBirthdayIndex();
      _pageController = PageController(initialPage: nearestIndex);
      _currentPageNotifier.value = nearestIndex;

      setState(() {
        isLoading = false;
      });

      _startTimer();
      _scheduleBirthdayNotifications();
    } catch (e) {
      debugPrint('데이터를 불러오는데 실패했습니다: $e');
    }
  }

  int _getNearestBirthdayIndex() {
    if (nijidongList.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int nearestIndex = 0;
    int minDays = 9999;

    for (int i = 0; i < nijidongList.length; i++) {
      final member = nijidongList[i];
      DateTime nextBirthday =
      DateTime(now.year, member.birthMonth, member.birthDay);

      if (nextBirthday.isBefore(today)) {
        nextBirthday =
            DateTime(now.year + 1, member.birthMonth, member.birthDay);
      }

      final difference = nextBirthday.difference(today).inDays;

      if (difference < minDays) {
        minDays = difference;
        nearestIndex = i;
      }
    }
    return nearestIndex;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentTimeNotifier.value = DateTime.now();
    });
  }

  String _getDDayString(IdolMember member, DateTime now) {
    var birthday = DateTime(now.year, member.birthMonth, member.birthDay);
    var difference = now.difference(birthday);

    if (difference.inSeconds >= 0 && difference.inSeconds < 86400) {
      return '생일이에요!\n축하합니다!';
    }

    if (difference.inSeconds >= 86400) {
      birthday = DateTime(now.year + 1, member.birthMonth, member.birthDay);
      difference = now.difference(birthday);
    }

    int diffDay = difference.inDays.abs();
    int diffHour = 23 - now.hour;
    int diffMinute = 59 - now.minute;
    int diffSecond = 59 - now.second;

    return '${diffDay}일 ${diffHour.toString().padLeft(2, '0')}:${diffMinute.toString().padLeft(2, '0')}:${diffSecond.toString().padLeft(2, '0')}';
  }

  Future<void> _scheduleBirthdayNotifications() async {
    for (int i = 0; i < nijidongList.length; i++) {
      final member = nijidongList[i];
      final now = tz.TZDateTime.now(tz.local);

      var scheduledDate = tz.TZDateTime(
          tz.local, now.year, member.birthMonth, member.birthDay, 0, 0);

      if (scheduledDate.isBefore(now)) {
        scheduledDate = tz.TZDateTime(
            tz.local, now.year + 1, member.birthMonth, member.birthDay, 0, 0);
      }

      // ✨ 변경된 부분: JSON에서 파싱해 온 body와 image 변수를 바로 넣습니다.
      await scheduleNotification(
        id: i,
        title: '생일 축하해, ${member.name}!🎂', // 타이틀도 원하시면 JSON으로 뺄 수 있어요!
        body: member.body,        // members.json에서 가져온 고유 텍스트
        imagePath: member.image,  // members.json에서 가져온 이미지 경로
        scheduledDate: scheduledDate,
      );
    }
  }

  Widget _buildCircleIndicator() {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPageNotifier,
      builder: (context, currentPage, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(nijidongList.length + 1, (index) {
            bool isSelected = currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: isSelected ? 12.0 : 8.0,
              height: isSelected ? 12.0 : 8.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.redAccent : Colors.white70,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildProfilePage() {
    return Container(
      color: const Color.fromARGB(255, 23, 63, 123),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text(
            'tomriddle7',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 45),
          ),
          InkWell(
            onTap: () async {
              final url = Uri.parse('https://x.com/tomriddle7');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text(
              '@tomriddle7',
              style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 32),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.lightBlueAccent,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Stack(
        children: <Widget>[
          PageView.builder(
            controller: _pageController,
            itemCount: nijidongList.length + 1,
            onPageChanged: (int index) {
              _currentPageNotifier.value = index;
            },
            itemBuilder: (context, index) {
              if (index == nijidongList.length) {
                return _buildProfilePage();
              }

              final member = nijidongList[index];
              final dummyDate =
              DateTime(2024, member.birthMonth, member.birthDay);
              final weekdayStr = birthWeekday[dummyDate.weekday - 1];

              return Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    member.image,
                    fit: BoxFit.cover,
                    color: const Color.fromRGBO(255, 255, 255, 0.5),
                    colorBlendMode: BlendMode.modulate,
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Image.asset(member.image),
                          Text(
                            '${member.birthMonth}월\n${member.birthDay}일\n($weekdayStr)',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      ValueListenableBuilder<DateTime>(
                        valueListenable: _currentTimeNotifier,
                        builder: (context, now, child) {
                          return Text(
                            _getDDayString(member, now),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 48),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 50.0,
            left: 0,
            right: 0,
            child: _buildCircleIndicator(),
          ),
        ],
      ),
    );
  }
}
