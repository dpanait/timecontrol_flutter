import 'package:flutter/material.dart';
import 'package:timecontrol/service_locator.dart';
import 'feature/login/presentation/login_screen.dart';
import 'feature/workday/presentation/workday_screen.dart';

void main() {
  setupServiceLocator();
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
