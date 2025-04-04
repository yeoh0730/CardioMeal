import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For Graphs
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Import your daily nutrient calculation service
import 'services/daily_nutrient_calculation.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, List<FlSpot>> healthData = {
    "Cholesterol": [],
    "Systolic BP": [],
    "Diastolic BP": [],
    "Blood Glucose": [],
    "Heart Rate": [],
  };

  // List of dates for the X-axis
  List<DateTime> metricDates = [];
  bool _isChartLoading = true;

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
      // Temp containers
      Map<String, List<FlSpot>> newHealthData = {
        "Cholesterol": [],
        "Systolic BP": [],
        "Diastolic BP": [],
        "Blood Glucose": [],
        "Heart Rate": [],
      };

      // Clear old dates
      List<DateTime> newDates = [];

      for (int i = 0; i < snapshot.docs.length; i++) {
        var data = snapshot.docs[i].data() as Map<String, dynamic>;

        // Convert Firestore Timestamp to DateTime
        Timestamp? ts = data["timestamp"];
        DateTime date = DateTime.now();
        if (ts != null) {
          date = ts.toDate();
        }
        newDates.add(date);

        // Convert each metric to double & create FlSpot
        newHealthData["Cholesterol"]!
            .add(FlSpot(i.toDouble(), (data["cholesterol"] ?? 0).toDouble()));
        newHealthData["Systolic BP"]!
            .add(FlSpot(i.toDouble(), (data["systolicBP"] ?? 0).toDouble()));
        newHealthData["Diastolic BP"]!
            .add(FlSpot(i.toDouble(), (data["diastolicBP"] ?? 0).toDouble()));
        newHealthData["Blood Glucose"]!
            .add(FlSpot(i.toDouble(), (data["bloodGlucose"] ?? 0).toDouble()));
        newHealthData["Heart Rate"]!
            .add(FlSpot(i.toDouble(), (data["heartRate"] ?? 0).toDouble()));
      }

      setState(() {
        healthData = newHealthData;
        metricDates = newDates; // store date list for X-axis labels
        _isChartLoading = false;
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
          backgroundColor: Colors.white,
          title: const Text("Update Health Metrics"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField("Cholesterol", cholesterolController),
                _buildTextField("Systolic BP", systolicBPController),
                _buildTextField("Diastolic BP", diastolicBPController),
                _buildTextField("Blood Glucose", bloodGlucoseController),
                _buildTextField("Heart Rate", heartRateController),
              ],
            ),
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

  void _updateHealthMetrics(
      double cholesterol,
      double systolicBP,
      double diastolicBP,
      double bloodGlucose,
      double heartRate,
      ) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String timestamp = DateTime.now().toIso8601String();

    // 1. Save to healthMetrics subcollection only.
    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("healthMetrics")
        .doc(timestamp)
        .set({
      "cholesterol": cholesterol,
      "systolicBP": systolicBP,
      "diastolicBP": diastolicBP,
      "bloodGlucose": bloodGlucose,
      "heartRate": heartRate,
      "timestamp": FieldValue.serverTimestamp(),
    });

    // 2. Remove the code that updated the main user doc:
    //    (We do NOT want to store these fields in the main doc)
    // await _firestore.collection("users").doc(user.uid).update({...});

    // 3. Fetch the main user doc for weight, height, age, etc.
    DocumentSnapshot userDocSnap =
    await _firestore.collection("users").doc(user.uid).get();
    Map<String, dynamic>? userDocData =
    userDocSnap.data() as Map<String, dynamic>?;

    if (userDocData != null) {
      // 4. Combine user doc data with new health metrics (in memory).
      final combinedData = {
        ...userDocData,
        "cholesterol": cholesterol,
        "systolicBP": systolicBP,
        "diastolicBP": diastolicBP,
        "bloodGlucose": bloodGlucose,
        "heartRate": heartRate,
      };

      // 5. Recalculate new nutrient limits
      Map<String, dynamic> newLimits =
      await calculateNutrientLimitsWithoutStoring(combinedData);

      // 6. Retrieve the latest nutrientHistory entry
      QuerySnapshot lastNutrientSnap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('nutrientHistory')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      bool shouldUpdate = true;
      if (lastNutrientSnap.docs.isNotEmpty) {
        DocumentSnapshot lastDoc = lastNutrientSnap.docs.first;
        Map<String, dynamic>? lastData =
        lastDoc.data() as Map<String, dynamic>?;
        if (lastData != null) {
          // Compare new data with the last entry.
          shouldUpdate = nutrientDataHasChanged(lastData, newLimits);
        }
      }

      if (shouldUpdate) {
        // 7. Store new nutrient limits & risk category
        await storeNutrientLimits(user.uid, newLimits);
      } else {
        print("No changes in nutrient limits. Not storing a new document.");
      }
    }

    // 8. Refresh the health history (to update the chart)
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
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  backgroundColor: Colors.white,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(
                      show: true, border: Border.all(color: Colors.white)),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= metricDates.length) {
                            return const SizedBox.shrink();
                          }
                          DateTime date = metricDates[index];
                          String formatted = DateFormat('MM/dd').format(date);
                          return Text(formatted,
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      spots: healthData[metricKey]!,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0.3),
                            Colors.red.withOpacity(0.005),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
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
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 50,
                  height: 50,
                ),
                const SizedBox(width: 10),
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
                child: Text("${(value * 100).toInt()}%",
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      body: Padding(
        padding: EdgeInsets.all(16),
            child: Center(child: Text("Dashboard", style: TextStyle(fontSize: 28),)),
      )
    );
  }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: Color(0xFFF8F8F8),
  //     body: SafeArea(
  //       child: Padding(
  //         padding: const EdgeInsets.only(
  //           left: 16.0,
  //           top: 16.0,
  //           right: 16.0,
  //           bottom: 0,
  //         ),
  //         child: SingleChildScrollView(
  //           child: _isChartLoading
  //               ? Center(
  //             child: Padding(
  //               padding: const EdgeInsets.only(top: 50.0),
  //               child: CircularProgressIndicator(),
  //             ),
  //           )
  //               : Column(
  //             children: [
  //               _buildProgressCard("Today's Progress"),
  //               const SizedBox(height: 16),
  //               _buildProgressCard("Weekly Progress"),
  //               const SizedBox(height: 16),
  //               ElevatedButton(
  //                 onPressed: _showUpdateDialog,
  //                 style: ElevatedButton.styleFrom(
  //                     backgroundColor: Colors.red,
  //                     foregroundColor: Colors.white),
  //                 child: const Text("Update health metrics",
  //                     style: TextStyle(fontSize: 12)),
  //               ),
  //               _buildMetricGraph("Cholesterol Level", "Cholesterol"),
  //               const SizedBox(height: 16),
  //               _buildMetricGraph("Systolic BP", "Systolic BP"),
  //               const SizedBox(height: 16),
  //               _buildMetricGraph("Diastolic BP", "Diastolic BP"),
  //               const SizedBox(height: 16),
  //               _buildMetricGraph("Blood Glucose", "Blood Glucose"),
  //               const SizedBox(height: 16),
  //               _buildMetricGraph("Heart Rate", "Heart Rate"),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
