import 'package:flutter/material.dart';
import 'dart:async';
import 'package:page_view_indicators/page_view_indicators.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DotLive++',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'DotLive++'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Timer _timer;

  List<String> birthWeekday = ['월', '화', '수', '목', '금', '토', '일'] ;
  List<String> diffBirth = [];
  List<String> liellaWeekday = [];

  final _pageController = PageController();
  final _currentPageNotifier = ValueNotifier<int>(0);

  var liellaList = [
    {
      'name': 'Arashi Chisato',
      'birthM': 2,
      'birthD': 25,
      'image': 'assets/liella_chisato1@2x.png'
    },
    {
      'name': 'Shibuya Kanon',
      'birthM': 5,
      'birthD': 1,
      'image': 'assets/liella_kanon1@2x.png'
    },
    {
      'name': 'Tang Keke',
      'birthM': 7,
      'birthD': 17,
      'image': 'assets/liella_keke1@2x.png'
    },
    {
      'name': 'Heanna Sumire',
      'birthM': 9,
      'birthD': 28,
      'image': 'assets/liella_sumire1@2x.png'
    },
    {
      'name': 'Hazuki Ren',
      'birthM': 11,
      'birthD': 24,
      'image': 'assets/liella_ren1@2x.png'
    }
  ];

  void BetweenDate() {
    var tempString = '';
    final date2 = DateTime.now();
    final year = date2.year;

    diffBirth = [];
    liellaWeekday = [];
    for (int i = 0; i < liellaList.length; i++) {
      var birthday = DateTime(year, liellaList[i]['birthM'], liellaList[i]['birthD']);
      var difference = date2.difference(birthday);
      var diffDay = difference.inDays;
      var diffHour = difference.inHours % 24 == 0 ? 0 : 24 - (difference.inHours % 24);
      var diffMinute = difference.inMinutes % 60 == 0 ? 0 : 60 - (difference.inMinutes % 60);
      var diffSecond = difference.inSeconds % 60 == 0 ? 0 : 60 - (difference.inSeconds % 60);
      if (difference.inSeconds < 86400 && difference.inSeconds >= 0) {
        tempString = '생일이에요!\n축하합니다!';
      }
      else if (difference.inSeconds < 0) {
        diffDay *= -1;

        tempString = diffDay.toString() + '일 ' + diffHour.toString().padLeft(2, '0') + ':' + diffMinute.toString().padLeft(2, '0') + ':' + diffSecond.toString().padLeft(2, '0');
      }
      else {
        birthday = DateTime(year + 1, liellaList[i]['birthM'], liellaList[i]['birthD']);
        difference = date2.difference(birthday);
        diffDay = difference.inDays * -1;
        diffHour = difference.inHours % 24 == 0 ? 0 : 24 - (difference.inHours % 24);
        diffMinute = difference.inMinutes % 60 == 0 ? 0 : 60 - (difference.inMinutes % 60);
        diffSecond = difference.inSeconds % 60 == 0 ? 0 : 60 - (difference.inSeconds % 60);

        tempString = diffDay.toString() + '일 ' + diffHour.toString().padLeft(2, '0') + ':' + diffMinute.toString().padLeft(2, '0') + ':' + diffSecond.toString().padLeft(2, '0');
      }
      setState(() {
        diffBirth.add(tempString);
        liellaWeekday.add(birthWeekday[birthday.weekday - 1]);
      });
    }
  }

  @override
  initState() {
    super.initState();
    BetweenDate();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      BetweenDate();
    });
  }

  List<Center> WidgetList() {
    List<Center> res = [];
    // 캐릭터 데이터 추가.
    for (int i = 0; i < liellaList.length; i++) {
      Center box = Center(
          child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Image.asset(
                    liellaList[i]['image'],
                    width: 1000,
                    height: 1000,
                    fit: BoxFit.cover,
                    color: Color.fromRGBO(255, 255, 255, 0.5),
                    colorBlendMode: BlendMode.modulate
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Image.asset(
                            liellaList[i]['image']
                        ),
                        Text(
                          '${liellaList[i]['birthM']}월\n${liellaList[i]['birthD']}일\n(${liellaWeekday[i]})',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 45,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      diffBirth[i],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 48,
                      ),
                    ),
                  ],
                ),
              ]
          )
      );
      res.add(box);
    }
    // 개인 프로필 추가.
    Center box = Center(
      child: Container(
        alignment: Alignment(0.0, 0.0),
        color: Color.fromARGB(255, 23, 63, 123),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'tomriddle7',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 45,
              ),
            ),
            InkWell(
              onTap: () async {
                await launch('https://twitter.com/tomriddle7', forceWebView: true, enableJavaScript: true, forceSafariVC: true);
              },
              child: Text(
                '@tomriddle7',
                style: TextStyle(
                  color: Colors.lightBlueAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    res.add(box);
    return res;
  }

  _buildCircleIndicator() {
    return Positioned(
      left: 0.0,
      right: 0.0,
      bottom: 50.0,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CirclePageIndicator(
          dotColor: Colors.white70,
          selectedDotColor: Colors.redAccent,
          itemCount: liellaList.length + 1,
          currentPageNotifier: _currentPageNotifier,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Stack(
          children: <Widget>[
            PageView(
              children: WidgetList(),
              onPageChanged: (int index) {
                _currentPageNotifier.value = index;
              },
            ),
            _buildCircleIndicator(),
          ],
        ),
      ),
    );
  }
}
