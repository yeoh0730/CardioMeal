import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Manage your profile, update health metrics, and view personalized recommendations based on your cardiovascular health needs.",
            style: TextStyle(fontSize: 18, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
