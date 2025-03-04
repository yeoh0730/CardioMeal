import 'package:flutter/material.dart';
import 'package:project/models/custom_toggle_bar.dart'; // Import toggle bar
import 'models/DashboardView.dart'; // Import Dashboard as a view, not a page

class DiaryPage extends StatefulWidget {
  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  bool isLogMealSelected = true; // Default to Log Meal

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Custom Toggle Bar
          CustomToggleBar(
            isSelected: isLogMealSelected,
            onToggle: (bool isSelected) {
              setState(() {
                isLogMealSelected = isSelected; // Toggle between Log Meal & Dashboard
              });
            },
          ),
          SizedBox(height: 5),

          // ✅ Switch between Log Meal and Dashboard
          Expanded(
            child: isLogMealSelected ? _buildLogMealView() : DashboardView(),
          ),
        ],
      ),
    );
  }

  // ✅ Log Meal View (Original Content)
  Widget _buildLogMealView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(
            "Today",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _buildMealSection('Breakfast', Colors.red, [
            'Coffee with milk 100 g',
            'Sandwich 100 g',
            'Walnuts 20 g'
          ], 'Sodium: 800 mg', 'Fat: 10 g', 'Carb: 30 g'),
          _buildMealSection('Lunch', Colors.orange, [], '', '', ''),
          _buildMealSection('Dinner', Colors.teal, [], '', '', ''),
          _buildMealSection('Snacks', Colors.purple, [], '', '', ''),
        ],
      ),
    );
  }

  // ✅ Meal Section UI
  Widget _buildMealSection(
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
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Text(
                  item,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
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
