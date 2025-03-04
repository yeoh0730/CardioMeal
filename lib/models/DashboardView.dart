import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Import for the graph

class DashboardView extends StatefulWidget {
  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildProgressCard("Today's Progress"),
                const SizedBox(height: 16),
                _buildProgressCard("Weekly Progress"),
                const SizedBox(height: 16),
                _buildCholesterolChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Progress Card with Circular Charts
  Widget _buildProgressCard(String title) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Image.asset(
                  'assets/logo.png', // Ensure you have this asset
                  width: 50,
                  height: 50,
                ),
                const SizedBox(width: 10),

                // ✅ Wrap progress indicators to ensure proper spacing
                Expanded(
                  child: Wrap(
                    spacing: 20, // ✅ Space between progress indicators
                    alignment: WrapAlignment.center,
                    children: [
                      _buildCircularProgress(0.28, "Sodium"),
                      _buildCircularProgress(0.65, "Fat"),
                      _buildCircularProgress(0.85, "Carb"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Circular Progress Bar for Nutrients
  Widget _buildCircularProgress(double value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                    value > 0.6 ? Colors.blue : Colors.orange),
                strokeWidth: 6,
              ),
              Center(
                child: Text("${(value * 100).toInt()}%", style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // ✅ Cholesterol Level Chart
  Widget _buildCholesterolChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Cholesterol Level", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Update", style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      spots: [const FlSpot(1, 50), const FlSpot(2, 60), const FlSpot(3, 70), const FlSpot(4, 75), const FlSpot(5, 90), const FlSpot(6, 100)],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
