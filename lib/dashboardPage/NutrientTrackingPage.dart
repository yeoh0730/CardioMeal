import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:ui' as ui;



class NutrientTab extends StatefulWidget {
  const NutrientTab({super.key});

  @override
  State<NutrientTab> createState() => _NutrientTabState();
}

class _NutrientTabState extends State<NutrientTab> {
  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  List<DateTime> get _selectedDates {
    final days = _selectedRange.end.difference(_selectedRange.start).inDays + 1;
    return List.generate(days, (i) => _selectedRange.start.add(Duration(days: i)));
  }

  List<FlSpot> _calorieSpots = [];
  double carbs = 0;
  double sodium = 0;
  double fat = 0;

  double carbLimit = 0;
  double sodiumLimit = 0;
  double fatLimit = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
      await _fetchData();
    }
  }

  Future<void> _fetchData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final dates = _selectedDates;
    final firestore = FirebaseFirestore.instance;

    List<FlSpot> spots = [];
    double totalCarbs = 0;
    double totalSodium = 0;
    double totalFat = 0;

    for (int i = 0; i < dates.length; i++) {
      final dateStr = DateFormat('yyyy-MM-dd').format(dates[i]);
      final snapshot = await firestore
          .collection("users")
          .doc(userId)
          .collection("loggedMeals")
          .where("date", isEqualTo: dateStr)
          .get();

      double dailyCalories = 0;
      double dailyCarbs = 0;
      double dailySodium = 0;
      double dailyFat = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final foods = List<Map<String, dynamic>>.from(data['foods'] ?? []);
        for (var food in foods) {
          final serving = (food["servingSize"] ?? 1).toDouble();
          dailyCalories += (food["calories"] ?? 0) * serving;
          dailyCarbs += (food["carbs"] ?? 0) * serving;
          dailySodium += (food["sodium"] ?? 0) * serving;
          dailyFat += (food["fat"] ?? 0) * serving;
        }
      }

      totalCarbs += dailyCarbs;
      totalSodium += dailySodium / 1000;
      totalFat += dailyFat;

      spots.add(FlSpot(i.toDouble(), dailyCalories));
    }

    final goalSnap = await firestore
        .collection("users")
        .doc(userId)
        .collection("nutrientHistory")
        .orderBy("timestamp", descending: true)
        .limit(1)
        .get();

    if (goalSnap.docs.isNotEmpty) {
      final data = goalSnap.docs.first.data();
      carbLimit = (data['carbLimit'] ?? 0).toDouble();
      sodiumLimit = (data['sodiumLimit'] ?? 0).toDouble() / 1000;
      fatLimit = (data['fatLimit'] ?? 0).toDouble();
    }

    setState(() {
      _calorieSpots = spots;
      carbs = totalCarbs;
      sodium = totalSodium;
      fat = totalFat;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dates = _selectedDates;
    final dateFormat = DateFormat('MM/dd');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDateFilterBar(),
          _buildCalorieChart(dateFormat, dates),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Macronutrients Consumption", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: DualRingPieChartPainter(
                        consumed: [carbs, sodium, fat],
                        goals: [carbLimit, sodiumLimit, fatLimit],
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      _LegendDot(color: Colors.blue, label: "carbs"),
                      SizedBox(width: 16),
                      _LegendDot(color: Colors.purple, label: "sodium"),
                      SizedBox(width: 16),
                      _LegendDot(color: Colors.yellow, label: "fat"),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: _pickDateRange,
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
                children: const [
                  Icon(Icons.filter_alt, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Filter Date", style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                ],
              ),
              Text(
                "${DateFormat('MMM d').format(_selectedRange.start)} - ${DateFormat('MMM d').format(_selectedRange.end)}",
                style: const TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieChart(DateFormat dateFormat, List<DateTime> dates) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Calorie Intake", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          int index = value.toInt();
                          if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                          return Text(dateFormat.format(dates[index]), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: FlDotData(show: true),
                      spots: _calorieSpots,
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 5, backgroundColor: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class DualRingPieChartPainter extends CustomPainter {
  final List<double> consumed;
  final List<double> goals;

  DualRingPieChartPainter({required this.consumed, required this.goals});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2 - 8;
    final innerRadius = outerRadius - 30;
    final outerThickness = 30.0;
    final innerThickness = 30.0;

    final colors = [Colors.blue.shade400, Colors.purple.shade400, Colors.yellow.shade400];
    final totalConsumed = consumed.fold(0.0, (a, b) => a + b);
    final totalGoal = goals.fold(0.0, (a, b) => a + b);

    // Draw outer ring (consumed)
    double consumedStart = -pi / 2;
    for (int i = 0; i < consumed.length; i++) {
      final sweep = (consumed[i] / totalConsumed) * 2 * pi;
      final paint = Paint()
        ..color = colors[i].withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = outerThickness;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outerRadius),
        consumedStart,
        sweep,
        false,
        paint,
      );

      // Draw percentage text
      final percent = (consumed[i] / totalConsumed * 100).round();
      final angle = consumedStart + sweep / 2;
      final labelPos = Offset(
        center.dx + cos(angle) * (outerRadius),
        center.dy + sin(angle) * (outerRadius),
      );
      _drawText(canvas, '$percent%', labelPos);

      consumedStart += sweep;
    }

    // Draw inner ring (goal)
    double goalStart = -pi / 2;
    for (int i = 0; i < goals.length; i++) {
      final sweep = (goals[i] / totalGoal) * 2 * pi;
      final paint = Paint()
        ..color = colors[i].withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = innerThickness;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        goalStart,
        sweep,
        false,
        paint,
      );

      // Draw percentage text
      final percent = (goals[i] / totalGoal * 100).round();
      final angle = goalStart + sweep / 2;
      final labelPos = Offset(
        center.dx + cos(angle) * (innerRadius),
        center.dy + sin(angle) * (innerRadius),
      );
      _drawText(canvas, '$percent%', labelPos, fontSize: 10, color: Colors.black87);

      goalStart += sweep;
    }

    // Draw center label
    final centerText = TextSpan(
      text: 'My goal',
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
    );
    final textPainter = TextPainter(
      text: centerText,
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: size.width);
    final offset = center - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, offset);

    // ===== Bottom Text: My consumption =====
    final consumptionText = TextSpan(
      text: 'My consumption',
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
    );
    final consumptionPainter = TextPainter(
      text: consumptionText,
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    consumptionPainter.layout();
    final consumptionOffset = Offset(
      center.dx - consumptionPainter.width / 2,
      center.dy + outerRadius + 20, // ⬅️ was 10, now moved lower
    );
    consumptionPainter.paint(canvas, consumptionOffset);
  }

  void _drawText(Canvas canvas, String text, Offset offset,
      {double fontSize = 11, Color color = Colors.black}) {
    final span = TextSpan(
      text: text,
      style: TextStyle(fontSize: fontSize, color: color, fontWeight: FontWeight.w500),
    );
    final tp = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    tp.layout();
    canvas.save();
    canvas.translate(offset.dx - tp.width / 2, offset.dy - tp.height / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}


