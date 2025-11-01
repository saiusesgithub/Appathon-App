import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shadowmesh/pages/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Wait 3 seconds, then navigate
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(11, 11, 13, 1.0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo/logo.jpg', width: 120),
            SizedBox(height: 20),
            Text(
              "ShadowMesh",
              style: TextStyle(
                color: Colors.red,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: "Orbitron",
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Secure. Offline. Untraceable.",
              style: TextStyle(
                color: Color.fromARGB(255, 94, 93, 93),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
