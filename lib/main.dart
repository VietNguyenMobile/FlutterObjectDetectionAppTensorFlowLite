import 'package:flutter/material.dart';
import 'package:object_detection_app_tensorflowlite/MySplashPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Object Detection', home: MySplashPage());
  }
}
