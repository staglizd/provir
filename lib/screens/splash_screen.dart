import 'package:flutter/material.dart';
import 'package:provir_search/screens/login_screen.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });

    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Text(
          'Provir SEA.R.C.H',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}
