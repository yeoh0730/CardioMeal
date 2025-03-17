import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'EditProfilePage.dart';
import 'EditDietPreferencePage.dart';
import 'LoginPage.dart';

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
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Profile Header Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: userData?['profileImage'] != null
                      ? NetworkImage(userData!['profileImage'])
                      : const AssetImage('assets/logo.png') as ImageProvider,
                ),
                const SizedBox(height: 10),
                Text(
                  userData?['name'] ?? 'User Name',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildOption(Icons.person, "View Profile", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfilePage(userData: userData),
                      ),
                    ).then((_) {  // Refresh data after returning
                      _fetchUserData();  // Fetch updated data when coming back
                    });
                  }),
                  _buildOption(Icons.notifications, "Notification", () {}),
                  _buildOption(Icons.restaurant_menu, "View Dietary Preferences", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditDietPreferencePage(userData: userData),
                      ),
                    ).then((updated) {  // ✅ Refresh data after returning
                      if (updated == true) {
                        _fetchUserData();  // Fetch updated data when coming back
                      }
                    });
                  }),
                  _buildOption(Icons.logout, "Logout", _showLogoutConfirmationDialog, isLogout: true),
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
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(height: 30, width: 1, color: Colors.grey),
    );
  }

  Widget _buildOption(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.black),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  // ✅ Confirmation Dialog Before Logging Out
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog first
                _logout(); // Perform logout
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Logout", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
  }
}
