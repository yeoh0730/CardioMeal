import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/daily_nutrient_calculation.dart';
import 'NutrientTrackingPage.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, Color> metricColors = {
    "Cholesterol": Colors.deepOrange,
    "SystolicBP": Colors.orangeAccent,
    "DiastolicBP": Colors.teal,
    "BloodGlucose": Colors.blue,
    "HeartRate": Colors.deepPurpleAccent,
  };

  Map<String, List<FlSpot>> healthData = {
    "Cholesterol": [],
    "SystolicBP": [],
    "DiastolicBP": [],
    "BloodGlucose": [],
    "HeartRate": [],
  };

  Map<String, List<DateTime>> _metricDateMap = {}; // ✅ for x-axis labels

  bool _isChartLoading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = now;
    _startDate = DateTime(now.year, now.month - 1, now.day);
    _fetchHealthHistory();
  }

  void _fetchHealthHistory() async {
    User? user = _auth.currentUser;
    if (user == null || _startDate == null || _endDate == null) return;

    Map<String, List<FlSpot>> newHealthData = {
      "Cholesterol": [],
      "SystolicBP": [],
      "DiastolicBP": [],
      "BloodGlucose": [],
      "HeartRate": [],
    };

    Map<String, List<DateTime>> newMetricDates = {
      "Cholesterol": [],
      "SystolicBP": [],
      "DiastolicBP": [],
      "BloodGlucose": [],
      "HeartRate": [],
    };

    final metricKeys = newHealthData.keys.toList();

    for (String metric in metricKeys) {
      final metricKey = metric.toLowerCase();
      final snapshot = await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("${metricKey}Metrics")
          .orderBy("timestamp", descending: false)
          .get();

      int index = 0;
      for (var doc in snapshot.docs) {
        Timestamp? ts = doc["timestamp"];
        double value = (doc["value"] ?? 0).toDouble();
        if (ts != null) {
          DateTime date = ts.toDate();
          if (date.isAfter(_startDate!) && date.isBefore(_endDate!.add(const Duration(days: 1)))) {
            newHealthData[metric]!.add(FlSpot(index.toDouble(), value));
            newMetricDates[metric]!.add(date);
            index++;
          }
        }
      }
    }

    setState(() {
      healthData = newHealthData;
      _metricDateMap = newMetricDates; // ✅ assign correctly
      _isChartLoading = false;
    });
  }

  void _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate!, end: _endDate!),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            dialogBackgroundColor: Colors.white,
            scaffoldBackgroundColor: Colors.white,
            colorScheme: const ColorScheme.light(
              primary: Colors.red,       // Header and selected dates
              onPrimary: Colors.white,   // Text on selected date
              onSurface: Colors.black,   // Default text color
              surface: Colors.white,     // Month/year row background
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.white,
              rangeSelectionBackgroundColor: Colors.red.withOpacity(0.2),
              todayBackgroundColor: WidgetStateProperty.all(Colors.red.shade100),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24), // Rounded corners
              ),
              dayStyle: TextStyle(
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              rangePickerHeaderHeadlineStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black,
              ),
              rangePickerHeaderHelpStyle: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _isChartLoading = true;
      });
      _fetchHealthHistory();
    }
  }

  void _showSingleMetricDialog(String metricKey) {
    TextEditingController valueController = TextEditingController();
    _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Update $metricKey",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "$metricKey Value",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        TextButton(
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Colors.red, // Header background and selected date
                                      onPrimary: Colors.white, // Text on selected date
                                      onSurface: Colors.black, // Default text color
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red, // "OK" and "Cancel" button text color
                                      ),
                                    ),
                                    dialogBackgroundColor: Colors.white,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                          child: const Text("Change", style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel", style: TextStyle(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            double? value = double.tryParse(valueController.text);
                            if (value != null) {
                              _saveSingleMetric(metricKey, value, _selectedDate);
                            }
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text("Save", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getLatestHealthMetrics(User user) async {
    final keys = ["cholesterol", "systolicbp", "diastolicbp", "bloodglucose", "heartrate"];
    final latestMetrics = <String, dynamic>{};

    for (String key in keys) {
      final snapshot = await _firestore
          .collection("users")
          .doc(user.uid)
          .collection("${key}Metrics")
          .orderBy("timestamp", descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        latestMetrics[key] = snapshot.docs.first.data()['value'] ?? 0.0;
      } else {
        latestMetrics[key] = 0.0;
      }
    }

    return latestMetrics;
  }

  Future<void> _saveSingleMetric(String metricKey, double value, DateTime selectedDate) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String selectedTimestamp = selectedDate.toIso8601String();

    await _firestore
        .collection("users")
        .doc(user.uid)
        .collection("${metricKey.toLowerCase().replaceAll(' ', '')}Metrics")
        .doc(selectedTimestamp)
        .set({
      "value": value,
      "timestamp": Timestamp.fromDate(selectedDate), // ✅ store correct timestamp
    });

    // Recalculate nutrient limits
    DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();
    Map<String, dynamic> profileData = userDoc.data() as Map<String, dynamic>;
    Map<String, dynamic> latestMetrics = await _getLatestHealthMetrics(user);

    Map<String, dynamic> nutrientData = {
      "weight": profileData["weight"],
      "height": profileData["height"],
      "age": profileData["age"],
      "gender": profileData["gender"],
      "activityLevel": profileData["activityLevel"],
      "cholesterol": latestMetrics["cholesterol"],
      "systolicBP": latestMetrics["systolicbp"],
      "diastolicBP": latestMetrics["diastolicbp"],
      "bloodGlucose": latestMetrics["bloodglucose"],
      "heartRate": latestMetrics["heartrate"],
    };

    await calculateAndStoreNutrientLimits(nutrientData);

    _fetchHealthHistory(); // Refresh chart
  }

  Widget _buildMetricGraph(String title, String metricKey) {
    final List<DateTime> dates = _metricDateMap[metricKey] ?? [];

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    onPressed: () => _showSingleMetricDialog(metricKey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          int index = value.toInt();
                          if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                          return Text(DateFormat('MM/dd').format(dates[index]), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: metricColors[metricKey] ?? Colors.red,
                      barWidth: 2,
                      spots: healthData[metricKey]!,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            (metricColors[metricKey] ?? Colors.red).withOpacity(0.3),
                            (metricColors[metricKey] ?? Colors.red).withOpacity(0.005),
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

  Widget _buildDateFilterBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: _selectDateRange,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                spreadRadius: 2,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.filter_alt, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    "Filter Date",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Text(
                "${DateFormat('MMM d').format(_startDate!)} - ${DateFormat('MMM d').format(_endDate!)}",
                style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthProgressTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isChartLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildDateFilterBar(),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.end,
            //   children: [
            //     TextButton.icon(
            //       onPressed: _selectDateRange,
            //       icon: const Icon(Icons.filter_alt, color: Colors.red),
            //       label: const Text("Filter Date", style: TextStyle(color: Colors.red)),
            //     ),
            //   ],
            // ),
            _buildMetricGraph("Cholesterol (mg/dl)", "Cholesterol"),
            const SizedBox(height: 16),
            _buildMetricGraph("Systolic BP (mmHg)", "SystolicBP"),
            const SizedBox(height: 16),
            _buildMetricGraph("Diastolic BP (mmHg)", "DiastolicBP"),
            const SizedBox(height: 16),
            _buildMetricGraph("Blood Glucose (mg/dl)", "BloodGlucose"),
            const SizedBox(height: 16),
            _buildMetricGraph("Resting Heart Rate (bpm)", "HeartRate"),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: AppBar(
            backgroundColor: const Color(0xFFF8F8F8),
            elevation: 0,
            bottom: TabBar(
              tabs: const [
                Tab(text: "Health Progress"),
                Tab(text: "Nutrient Intake"),
              ],
              labelColor: Colors.red,
              indicatorColor: Colors.red,
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildHealthProgressTab(),
            const NutrientTab(),
          ],
        ),
      ),
    );
  }
}

























// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart'; // For Graphs
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// // Import your daily nutrient calculation service
// import '../services/daily_nutrient_calculation.dart';
//
// class DashboardPage extends StatefulWidget {
//   @override
//   _DashboardPageState createState() => _DashboardPageState();
// }
//
// class _DashboardPageState extends State<DashboardPage> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   Map<String, List<FlSpot>> healthData = {
//     "Cholesterol": [],
//     "Systolic BP": [],
//     "Diastolic BP": [],
//     "Blood Glucose": [],
//     "Heart Rate": [],
//   };
//
//   // List of dates for the X-axis
//   List<DateTime> metricDates = [];
//   bool _isChartLoading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchHealthHistory();
//   }
//
//   // ✅ Fetch user health metrics history from Firestore
//   void _fetchHealthHistory() async {
//     User? user = _auth.currentUser;
//     if (user == null) return;
//
//     QuerySnapshot snapshot = await _firestore
//         .collection("users")
//         .doc(user.uid)
//         .collection("healthMetrics")
//         .orderBy("timestamp", descending: false)
//         .get();
//
//     if (snapshot.docs.isNotEmpty) {
//       // Temp containers
//       Map<String, List<FlSpot>> newHealthData = {
//         "Cholesterol": [],
//         "Systolic BP": [],
//         "Diastolic BP": [],
//         "Blood Glucose": [],
//         "Heart Rate": [],
//       };
//
//       // Clear old dates
//       List<DateTime> newDates = [];
//
//       for (int i = 0; i < snapshot.docs.length; i++) {
//         var data = snapshot.docs[i].data() as Map<String, dynamic>;
//
//         // Convert Firestore Timestamp to DateTime
//         Timestamp? ts = data["timestamp"];
//         DateTime date = DateTime.now();
//         if (ts != null) {
//           date = ts.toDate();
//         }
//         newDates.add(date);
//
//         // Convert each metric to double & create FlSpot
//         newHealthData["Cholesterol"]!
//             .add(FlSpot(i.toDouble(), (data["cholesterol"] ?? 0).toDouble()));
//         newHealthData["Systolic BP"]!
//             .add(FlSpot(i.toDouble(), (data["systolicBP"] ?? 0).toDouble()));
//         newHealthData["Diastolic BP"]!
//             .add(FlSpot(i.toDouble(), (data["diastolicBP"] ?? 0).toDouble()));
//         newHealthData["Blood Glucose"]!
//             .add(FlSpot(i.toDouble(), (data["bloodGlucose"] ?? 0).toDouble()));
//         newHealthData["Heart Rate"]!
//             .add(FlSpot(i.toDouble(), (data["heartRate"] ?? 0).toDouble()));
//       }
//
//       setState(() {
//         healthData = newHealthData;
//         metricDates = newDates; // store date list for X-axis labels
//         _isChartLoading = false;
//       });
//     }
//   }
//
//   // ✅ Show Dialog for Updating Health Metrics
//   void _showUpdateDialog() {
//     TextEditingController cholesterolController = TextEditingController();
//     TextEditingController systolicBPController = TextEditingController();
//     TextEditingController diastolicBPController = TextEditingController();
//     TextEditingController bloodGlucoseController = TextEditingController();
//     TextEditingController heartRateController = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (context) {
//         return AlertDialog(
//           backgroundColor: Colors.white,
//           title: const Text("Update Health Metrics"),
//           content: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 _buildTextField("Cholesterol", cholesterolController),
//                 _buildTextField("Systolic BP", systolicBPController),
//                 _buildTextField("Diastolic BP", diastolicBPController),
//                 _buildTextField("Blood Glucose", bloodGlucoseController),
//                 _buildTextField("Heart Rate", heartRateController),
//               ],
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text("Cancel"),
//             ),
//             ElevatedButton(
//               onPressed: () {
//                 _updateHealthMetrics(
//                   double.tryParse(cholesterolController.text) ?? 0,
//                   double.tryParse(systolicBPController.text) ?? 0,
//                   double.tryParse(diastolicBPController.text) ?? 0,
//                   double.tryParse(bloodGlucoseController.text) ?? 0,
//                   double.tryParse(heartRateController.text) ?? 0,
//                 );
//                 Navigator.pop(context);
//               },
//               child: const Text("Save"),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _updateHealthMetrics(
//       double cholesterol,
//       double systolicBP,
//       double diastolicBP,
//       double bloodGlucose,
//       double heartRate,
//       ) async {
//     User? user = _auth.currentUser;
//     if (user == null) return;
//
//     String timestamp = DateTime.now().toIso8601String();
//
//     // 1. Save to healthMetrics subcollection only.
//     await _firestore
//         .collection("users")
//         .doc(user.uid)
//         .collection("healthMetrics")
//         .doc(timestamp)
//         .set({
//       "cholesterol": cholesterol,
//       "systolicBP": systolicBP,
//       "diastolicBP": diastolicBP,
//       "bloodGlucose": bloodGlucose,
//       "heartRate": heartRate,
//       "timestamp": FieldValue.serverTimestamp(),
//     });
//
//     // 2. Remove the code that updated the main user doc:
//     //    (We do NOT want to store these fields in the main doc)
//     // await _firestore.collection("users").doc(user.uid).update({...});
//
//     // 3. Fetch the main user doc for weight, height, age, etc.
//     DocumentSnapshot userDocSnap =
//     await _firestore.collection("users").doc(user.uid).get();
//     Map<String, dynamic>? userDocData =
//     userDocSnap.data() as Map<String, dynamic>?;
//
//     if (userDocData != null) {
//       // 4. Combine user doc data with new health metrics (in memory).
//       final combinedData = {
//         ...userDocData,
//         "cholesterol": cholesterol,
//         "systolicBP": systolicBP,
//         "diastolicBP": diastolicBP,
//         "bloodGlucose": bloodGlucose,
//         "heartRate": heartRate,
//       };
//
//       // 5. Recalculate new nutrient limits
//       Map<String, dynamic> newLimits =
//       await calculateNutrientLimitsWithoutStoring(combinedData);
//
//       // 6. Retrieve the latest nutrientHistory entry
//       QuerySnapshot lastNutrientSnap = await _firestore
//           .collection('users')
//           .doc(user.uid)
//           .collection('nutrientHistory')
//           .orderBy('timestamp', descending: true)
//           .limit(1)
//           .get();
//
//       bool shouldUpdate = true;
//       if (lastNutrientSnap.docs.isNotEmpty) {
//         DocumentSnapshot lastDoc = lastNutrientSnap.docs.first;
//         Map<String, dynamic>? lastData =
//         lastDoc.data() as Map<String, dynamic>?;
//         if (lastData != null) {
//           // Compare new data with the last entry.
//           shouldUpdate = nutrientDataHasChanged(lastData, newLimits);
//         }
//       }
//
//       if (shouldUpdate) {
//         // 7. Store new nutrient limits & risk category
//         await storeNutrientLimits(user.uid, newLimits);
//       } else {
//         print("No changes in nutrient limits. Not storing a new document.");
//       }
//     }
//
//     // 8. Refresh the health history (to update the chart)
//     _fetchHealthHistory();
//   }
//
//   // ✅ Helper Widget for Text Input Fields
//   Widget _buildTextField(String label, TextEditingController controller) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: TextField(
//         controller: controller,
//         keyboardType: TextInputType.number,
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//       ),
//     );
//   }
//
//   // ✅ Build Graph UI for each Metric
//   Widget _buildMetricGraph(String title, String metricKey) {
//     return Card(
//       color: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title,
//                 style:
//                 const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 20),
//             SizedBox(
//               height: 200,
//               child: LineChart(
//                 LineChartData(
//                   backgroundColor: Colors.white,
//                   gridData: FlGridData(show: false),
//                   borderData: FlBorderData(
//                       show: true, border: Border.all(color: Colors.white)),
//                   titlesData: FlTitlesData(
//                     leftTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         reservedSize: 40,
//                         getTitlesWidget: (value, meta) {
//                           return Text(value.toInt().toString(),
//                               style: const TextStyle(fontSize: 10));
//                         },
//                       ),
//                     ),
//                     rightTitles:
//                     AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     topTitles:
//                     AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                     bottomTitles: AxisTitles(
//                       sideTitles: SideTitles(
//                         showTitles: true,
//                         interval: 1,
//                         getTitlesWidget: (value, meta) {
//                           int index = value.toInt();
//                           if (index < 0 || index >= metricDates.length) {
//                             return const SizedBox.shrink();
//                           }
//                           DateTime date = metricDates[index];
//                           String formatted = DateFormat('MM/dd').format(date);
//                           return Text(formatted,
//                               style: const TextStyle(fontSize: 10));
//                         },
//                       ),
//                     ),
//                   ),
//                   lineBarsData: [
//                     LineChartBarData(
//                       isCurved: true,
//                       color: Colors.red,
//                       barWidth: 2,
//                       spots: healthData[metricKey]!,
//                       belowBarData: BarAreaData(
//                         show: true,
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.red.withOpacity(0.3),
//                             Colors.red.withOpacity(0.005),
//                           ],
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ✅ Progress Card Widget
//   Widget _buildProgressCard(String title) {
//     return Card(
//       color: Colors.white,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title,
//                 style:
//                 const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//             const SizedBox(height: 10),
//             Row(
//               children: [
//                 Image.asset(
//                   'assets/logo.png',
//                   width: 50,
//                   height: 50,
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: Wrap(
//                     spacing: 20,
//                     alignment: WrapAlignment.center,
//                     children: [
//                       _buildCircularProgress(0.28, "Sodium"),
//                       _buildCircularProgress(0.65, "Fat"),
//                       _buildCircularProgress(0.85, "Carb"),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // ✅ Circular Progress Bar for Nutrients
//   Widget _buildCircularProgress(double value, String label) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         SizedBox(
//           width: 50,
//           height: 50,
//           child: Stack(
//             fit: StackFit.expand,
//             children: [
//               CircularProgressIndicator(
//                 value: value,
//                 backgroundColor: Colors.grey[300],
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                     value > 0.6 ? Colors.blue : Colors.orange),
//                 strokeWidth: 6,
//               ),
//               Center(
//                 child: Text("${(value * 100).toInt()}%",
//                     style: const TextStyle(fontSize: 12)),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(height: 5),
//         Text(label,
//             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
//       ],
//     );
//   }
//
//   // @override
//   // Widget build(BuildContext context) {
//   //   return Scaffold(
//   //     backgroundColor: Color(0xFFF8F8F8),
//   //     body: Padding(
//   //       padding: EdgeInsets.all(16),
//   //           child: Center(child: Text("Dashboard", style: TextStyle(fontSize: 28),)),
//   //     )
//   //   );
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFFF8F8F8),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.only(
//             left: 16.0,
//             top: 16.0,
//             right: 16.0,
//             bottom: 0,
//           ),
//           child: SingleChildScrollView(
//             child: _isChartLoading
//                 ? Center(
//               child: Padding(
//                 padding: const EdgeInsets.only(top: 50.0),
//                 child: CircularProgressIndicator(),
//               ),
//             )
//                 : Column(
//               children: [
//                 _buildProgressCard("Today's Progress"),
//                 const SizedBox(height: 16),
//                 _buildProgressCard("Weekly Progress"),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: _showUpdateDialog,
//                   style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red,
//                       foregroundColor: Colors.white),
//                   child: const Text("Update health metrics",
//                       style: TextStyle(fontSize: 12)),
//                 ),
//                 _buildMetricGraph("Cholesterol Level", "Cholesterol"),
//                 const SizedBox(height: 16),
//                 _buildMetricGraph("Systolic BP", "Systolic BP"),
//                 const SizedBox(height: 16),
//                 _buildMetricGraph("Diastolic BP", "Diastolic BP"),
//                 const SizedBox(height: 16),
//                 _buildMetricGraph("Blood Glucose", "Blood Glucose"),
//                 const SizedBox(height: 16),
//                 _buildMetricGraph("Heart Rate", "Heart Rate"),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

