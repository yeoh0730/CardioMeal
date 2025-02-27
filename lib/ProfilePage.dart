import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project/LoginPage.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>?;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: userData == null
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Profile Header Section
          Container(
            padding: EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: userData?['profileImage'] != null
                      ? NetworkImage(userData!['profileImage'])
                      : AssetImage('assets/default_profile.png') as ImageProvider,
                ),
                SizedBox(height: 10),
                Text(
                  userData?['name'] ?? 'User Name',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildUserInfo("Weight", "${userData?['weight'] ?? '-'} kg"),
                    _divider(),
                    _buildUserInfo("Height", "${userData?['height'] ?? '-'} cm"),
                    _divider(),
                    _buildUserInfo("Age", "${userData?['age'] ?? '-'}"),
                  ],
                ),
              ],
            ),
          ),

          // Account Options Section
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildOption(Icons.person, "Edit Profile"),
                  _buildOption(Icons.notifications, "Notification"),
                  _buildOption(Icons.restaurant_menu, "Edit Diet Preference"),
                  _buildOption(Icons.logout, "Logout", isLogout: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(String title, String value) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Container(height: 30, width: 1, color: Colors.grey),
    );
  }

  Widget _buildOption(IconData icon, String title, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.black),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        if (isLogout) _logout();
      },
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }
}
