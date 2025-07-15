import 'package:flutter/material.dart';
import 'screens/demo_page_screen.dart';

void main() {
  runApp(TestDemoApp());
}

class TestDemoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue[800],
      ),
      home: DemoPageScreen(),
    );
  }
} 