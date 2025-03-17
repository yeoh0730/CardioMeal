import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For Graphs
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardView extends StatefulWidget {
  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<FlSpot>> healthData = {
    "Cholesterol": [],
    "Systolic BP": [],
    "Diastolic BP": [],
    "Blood Glucose": [],
    "Heart Rate": [],
  };

  @override
  void initState() {
    super.initState();
    _fetchHealthHistory();
  }

  // ✅ Fetch user health metrics history from Firestore
  void _fetchHealthHistory() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    QuerySnapshot snapshot = await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("healthMetrics")
        .orderBy("timestamp", descending: false)
        .get();

    if (snapshot.docs.isNotEmpty) {
      Map<String, List<FlSpot>> newHealthData = {
        "Cholesterol": [],
        "Systolic BP": [],
        "Diastolic BP": [],
        "Blood Glucose": [],
        "Heart Rate": [],
      };

      for (int i = 0; i < snapshot.docs.length; i++) {
        var data = snapshot.docs[i].data() as Map<String, dynamic>;
        newHealthData["Cholesterol"]!.add(FlSpot(i.toDouble(), data["cholesterol"].toDouble()));
        newHealthData["Systolic BP"]!.add(FlSpot(i.toDouble(), data["systolicBP"].toDouble()));
        newHealthData["Diastolic BP"]!.add(FlSpot(i.toDouble(), data["diastolicBP"].toDouble()));
        newHealthData["Blood Glucose"]!.add(FlSpot(i.toDouble(), data["bloodGlucose"].toDouble()));
        newHealthData["Heart Rate"]!.add(FlSpot(i.toDouble(), data["heartRate"].toDouble()));
      }

      setState(() {
        healthData = newHealthData;
      });
    }
  }

  // ✅ Show Dialog for Updating Health Metrics
  void _showUpdateDialog() {
    TextEditingController cholesterolController = TextEditingController();
    TextEditingController systolicBPController = TextEditingController();
    TextEditingController diastolicBPController = TextEditingController();
    TextEditingController bloodGlucoseController = TextEditingController();
    TextEditingController heartRateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Health Metrics"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField("Cholesterol", cholesterolController),
              _buildTextField("Systolic BP", systolicBPController),
              _buildTextField("Diastolic BP", diastolicBPController),
              _buildTextField("Blood Glucose", bloodGlucoseController),
              _buildTextField("Heart Rate", heartRateController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateHealthMetrics(
                  double.tryParse(cholesterolController.text) ?? 0,
                  double.tryParse(systolicBPController.text) ?? 0,
                  double.tryParse(diastolicBPController.text) ?? 0,
                  double.tryParse(bloodGlucoseController.text) ?? 0,
                  double.tryParse(heartRateController.text) ?? 0,
                );
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // ✅ Function to Save Health Metrics in Firestore
  void _updateHealthMetrics(double cholesterol, double systolicBP, double diastolicBP, double bloodGlucose, double heartRate) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String timestamp = DateTime.now().toIso8601String();
    await _firestore.collection("users").doc(user.uid).collection("healthMetrics").doc(timestamp).set({
      "cholesterol": cholesterol,
      "systolicBP": systolicBP,
      "diastolicBP": diastolicBP,
      "bloodGlucose": bloodGlucose,
      "heartRate": heartRate,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _fetchHealthHistory();
  }

  // ✅ Helper Widget for Text Input Fields
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ✅ Build Graph UI for each Metric
  Widget _buildMetricGraph(String title, String metricKey) {
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
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                // ElevatedButton(
                //   onPressed: _showUpdateDialog,
                //   style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                //   child: const Text("Update", style: TextStyle(fontSize: 12)),
                // ),
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
                      spots: healthData[metricKey]!,
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

  // ✅ Progress Card Widget
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
                  'assets/logo.png', // Ensure this asset exists
                  width: 50,
                  height: 50,
                ),
                const SizedBox(width: 10),

                // ✅ Circular Progress Indicators
                Expanded(
                  child: Wrap(
                    spacing: 20,
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
                ElevatedButton(
                  onPressed: _showUpdateDialog,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: const Text("Update health metrics", style: TextStyle(fontSize: 12)),
                ),
                _buildMetricGraph("Cholesterol Level", "Cholesterol"),
                const SizedBox(height: 16),
                _buildMetricGraph("Systolic BP", "Systolic BP"),
                const SizedBox(height: 16),
                _buildMetricGraph("Diastolic BP", "Diastolic BP"),
                const SizedBox(height: 16),
                _buildMetricGraph("Blood Glucose", "Blood Glucose"),
                const SizedBox(height: 16),
                _buildMetricGraph("Heart Rate", "Heart Rate"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
