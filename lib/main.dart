import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'workday_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workday App',
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/workday': (context) => WorkdayScreen(),
      },
    );
  }
}
