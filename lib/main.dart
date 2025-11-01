import 'package:flutter/material.dart';
import 'package:shadowmesh/pages/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShadowMesh',
      theme: ThemeData(
        fontFamily: "Mozilla_Headline",
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Color.fromRGBO(11, 11, 13, 1.0),
      ),
      home: SplashScreen(),
    );
  }
}
