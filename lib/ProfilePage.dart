import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'EditProfilePage.dart';
import 'EditDietPreferencePage.dart';
import 'FavouriteRecipesPage.dart';
import 'LoginPage.dart';
import 'models/custom_button.dart';

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
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

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
      backgroundColor: const Color(0xFFF8F8F8),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1) Page Title
                Text(
                  "Profile",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // 2) Redesigned Top Card (Name/Email on accent background, stats below)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Top portion with accent background
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // subtle accent color
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              userData?['name'] ?? 'User Name',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider line to separate accent area from stats
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFECECEC),
                        indent: 0,
                        endIndent: 0,
                      ),

                      // Bottom portion: stats row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatItem(
                              label: "Weight",
                              value: "${userData?['weight'] ?? '-'} kg",
                            ),
                            _verticalDivider(),
                            _buildStatItem(
                              label: "Height",
                              value: "${userData?['height'] ?? '-'} cm",
                            ),
                            _verticalDivider(),
                            _buildStatItem(
                              label: "Age",
                              value: "${userData?['age'] ?? '-'}",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3) Main options card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildOption(
                        icon: Icons.person_2_outlined,
                        title: "Personal Details",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfilePage(userData: userData),
                            ),
                          ).then((_) => _fetchUserData());
                        },
                      ),
                      _dividerLine(),
                      _buildOption(
                        icon: Icons.restaurant_menu,
                        title: "Dietary Preferences",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDietPreferencePage(
                                userData: userData,
                              ),
                            ),
                          ).then((updated) {
                            if (updated == true) {
                              _fetchUserData();
                            }
                          });
                        },
                      ),
                      _dividerLine(),
                      _buildOption(
                        icon: Icons.favorite_border,
                        title: "Favourite Recipes",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => FavoriteRecipesPage()),
                          );
                        },
                      ),
                      _dividerLine(),
                      _buildOption(
                        icon: Icons.notifications_none,
                        title: "Notifications",
                        onTap: () {
                          // TODO: Navigate
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 4) HELP Section title
                Text(
                  "HELP",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),

                // 5) Help section card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildOption(
                        icon: Icons.help_outline,
                        title: "About CardioMeal",
                        onTap: () {
                          // TODO: Navigate
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 6) Log Out Button
                SizedBox(
                  width: double.infinity,
                  child: CustomButton(
                    text: "Log Out",
                    onPressed: _showLogoutConfirmationDialog,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// For weight, height, age items
  Widget _buildStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  /// Simple vertical divider for stats row
  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.grey[300],
    );
  }

  /// Reusable list option widget
  Widget _buildOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.red),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing:
      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  /// Divider line between ListTiles
  Widget _dividerLine() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 72, // Indent so the divider starts after the icon
      endIndent: 16,
      color: Color(0xFFECECEC),
    );
  }

  /// Show confirmation before logout
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Log Out"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _logout();
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}
