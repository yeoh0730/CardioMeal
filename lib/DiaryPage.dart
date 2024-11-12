import 'package:flutter/material.dart';
import 'package:project/DashboardPage.dart';

class DiaryPage extends StatefulWidget {
  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  bool isLogMealSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Diary',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle Buttons for "Log Meal" and "Dashboard"
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLogMealSelected = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLogMealSelected ? Colors.red : Colors.grey[300],
                      foregroundColor: isLogMealSelected ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                    ),
                    child: Text('Log Meal'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isLogMealSelected = false;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => DashboardPage()),
                        );
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !isLogMealSelected ? Colors.red : Colors.grey[300],
                      foregroundColor: !isLogMealSelected ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                    ),
                    child: Text('Dashboard'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            // Today Label and Edit Icon
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.grey),
                  onPressed: () {
                    // Edit action
                  },
                ),
              ],
            ),
            // Meal Sections
            Expanded(
              child: ListView(
                children: [
                  buildMealSection('Breakfast', Colors.red, [
                    'Coffee with milk 100 g',
                    'Sandwich 100 g',
                    'Walnuts 20 g'
                  ], 'Sodium: 800 mg', 'Fat: 10 g', 'Carb: 30 g'),
                  buildMealSection('Lunch', Colors.orange, [], '', '', ''),
                  buildMealSection('Dinner', Colors.teal, [], '', '', ''),
                  buildMealSection('Snacks', Colors.purple, [], '', '', ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to create meal sections
  Widget buildMealSection(
      String mealTitle, Color color, List<String> items, String sodium, String fat, String carb) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 5,
                    height: 40,
                    color: color,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      mealTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: Colors.red),
                    onPressed: () {
                      // Add meal action
                    },
                  ),
                ],
              ),
              // Food items for the meal
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              )),
              if (items.isNotEmpty) Divider(),
              if (items.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(sodium, style: TextStyle(color: Colors.grey)),
                      Text(fat, style: TextStyle(color: Colors.grey)),
                      Text(carb, style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
