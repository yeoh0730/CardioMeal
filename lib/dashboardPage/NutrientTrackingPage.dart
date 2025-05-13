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
  bool _isLoading = true;

  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  List<DateTime> get _selectedDates {
    final days = _selectedRange.end.difference(_selectedRange.start).inDays + 1;
    return List.generate(days, (i) => _selectedRange.start.add(Duration(days: i)));
  }

  List<FlSpot> _calorieSpots = [];
  List<FlSpot> carbSpots = [];
  List<FlSpot> sodiumSpots = [];
  List<FlSpot> rawSodiumSpots = []; // mg
  List<FlSpot> fatSpots = [];
  double carbs = 0;
  double sodium = 0;
  double fat = 0;

  double calorieGoal = 0;
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
        _selectedRange = picked;
      });
      await _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;
    final dates = _selectedDates;
    final firestore = FirebaseFirestore.instance;

    List<FlSpot> spots = [];
    carbSpots.clear();
    sodiumSpots.clear();
    rawSodiumSpots.clear();
    fatSpots.clear();

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
      carbSpots.add(FlSpot(i.toDouble(), dailyCarbs));
      sodiumSpots.add(FlSpot(i.toDouble(), dailySodium / 1000));
      rawSodiumSpots.add(FlSpot(i.toDouble(), dailySodium)); // in mg
      fatSpots.add(FlSpot(i.toDouble(), dailyFat));
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
      calorieGoal = (data['dailyCalories'] ?? 2500).toDouble();
      carbLimit = (data['carbLimit'] ?? 0).toDouble();
      sodiumLimit = (data['sodiumLimit'] ?? 0).toDouble() / 1000;
      fatLimit = (data['fatLimit'] ?? 0).toDouble();
    }

    setState(() {
      _calorieSpots = spots;
      carbs = totalCarbs;
      sodium = totalSodium;
      fat = totalFat;
      _isLoading = false;
    });
  }

  Widget _buildDateFilterBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
    double maxCalorieY = max(
      _calorieSpots.map((e) => e.y).reduce(max) * 1.2,
      calorieGoal * 1.1,
    );

    double interval = maxCalorieY > 3000
        ? 500
        : maxCalorieY > 1500
        ? 300
        : maxCalorieY > 1000
        ? 100
        : maxCalorieY > 500
        ? 50
        : maxCalorieY > 100
        ? 30
        : maxCalorieY > 50
        ? 10
        : 5;

    int dateLabelInterval = dates.length > 7 ? (dates.length / 7).ceil() : 1;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  maxY: maxCalorieY,
                  minY: 0,
                  borderData: FlBorderData(
                    show: true,
                    border: const Border(
                      left: BorderSide(color: Colors.grey, width: 1),  // Y-axis
                      bottom: BorderSide(color: Colors.grey, width: 1), // X-axis
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 27,
                        interval: interval,
                        getTitlesWidget: (value, _) {
                          if (value % interval != 0) return const SizedBox.shrink();
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: dateLabelInterval.toDouble(),
                        getTitlesWidget: (value, _) {
                          int index = value.toInt();
                          if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                          if (index % dateLabelInterval != 0) return const SizedBox.shrink();
                          return Text(
                            DateFormat('dd/MM').format(dates[index]),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (LineBarSpot spot) => Colors.red.shade100,
                      tooltipRoundedRadius: 8,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipBorder: BorderSide.none,
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.y.toStringAsFixed(1)} kcal',
                            const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  extraLinesData: ExtraLinesData(horizontalLines: [
                    HorizontalLine(
                      y: calorieGoal,
                      color: Colors.grey,
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        labelResolver: (_) => "${calorieGoal.toStringAsFixed(0)} kcal",
                        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                        alignment: Alignment.topRight,
                      ),
                    )
                  ]),
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

  Widget _buildNutrientLineChart({
    required String label,
    required List<FlSpot> dataSpots,
    required double goalValue,
    required Color lineColor,
    required Color goalLineColor,
    required List<DateTime> dates,
  }) {
    double maxY = [
      goalValue,
      ...dataSpots.map((s) => s.y),
    ].reduce((a, b) => a > b ? a : b) * 1.2;

    int dateLabelInterval = dates.length > 7 ? (dates.length / 7).ceil() : 1;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: LineChart(
                  LineChartData(
                    maxY: maxY,
                    minY: 0,
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                        left: BorderSide(color: Colors.grey, width: 1),  // Y-axis
                        bottom: BorderSide(color: Colors.grey, width: 1), // X-axis
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        spots: dataSpots,
                        color: lineColor,
                        barWidth: 2,
                        dotData: FlDotData(show: true),
                      ),
                    ],
                    extraLinesData: ExtraLinesData(horizontalLines: [
                      HorizontalLine(
                        y: goalValue,
                        color: goalLineColor,
                        strokeWidth: 1.5,
                        dashArray: [6, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          labelResolver: (_) {
                            final isSodium = label.toLowerCase() == "sodium";
                            final unit = isSodium ? "mg" : "g";
                            return "${goalValue.toStringAsFixed(0)} $unit";
                          },
                          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                          alignment: Alignment.topRight,
                        ),
                      )
                    ]),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (LineBarSpot spot) {
                          if (label.toLowerCase().contains("carbs")) return Colors.blue.shade100;
                          if (label.toLowerCase().contains("sodium")) return Colors.purple.shade100;
                          if (label.toLowerCase().contains("fat")) return Colors.orange.shade100;
                          return Colors.grey.shade800;
                        },
                        tooltipRoundedRadius: 8,
                        tooltipPadding: const EdgeInsets.all(8),
                        tooltipBorder: BorderSide.none,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)}',
                              const TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: dateLabelInterval.toDouble(),
                          getTitlesWidget: (value, _) {
                            int index = value.toInt();
                            if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                            if (index % dateLabelInterval != 0) return const SizedBox.shrink();
                            return Text(
                              DateFormat('dd/MM').format(dates[index]),
                              style: const TextStyle(fontSize: 10),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          interval: maxY > 3000
                              ? 500
                              : maxY > 1500
                              ? 300
                              : maxY > 1000
                              ? 100
                              : maxY > 500
                              ? 50
                              : maxY > 100
                              ? 30
                              : maxY > 70
                              ? 10
                              : 5,
                          getTitlesWidget: (value, _) {
                            double interval = maxY > 3000
                                ? 500
                                : maxY > 1500
                                ? 300
                                : maxY > 1000
                                ? 100
                                : maxY > 500
                                ? 50
                                : maxY > 100
                                ? 30
                                : maxY > 70
                                ? 10
                                : 5;

                            if (value % interval != 0) return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dates = _selectedDates;
    final dateFormat = DateFormat('MM/dd');
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.red))
        : SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDateFilterBar(),
          const SizedBox(height: 16),
          const Text("Calorie Intake (kcal)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          _buildCalorieChart(dateFormat, dates),
          const SizedBox(height: 16),
          const Text("Nutrient Breakdown (%)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                      _LegendDot(color: Colors.blue, label: "Carbs"),
                      SizedBox(width: 16),
                      _LegendDot(color: Colors.purple, label: "Sodium"),
                      SizedBox(width: 16),
                      _LegendDot(color: Colors.orange, label: "Fat"),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("Carbs Intake (g)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          _buildNutrientLineChart(
            label: "Carbs",
            dataSpots: carbSpots,
            goalValue: carbLimit,
            lineColor: Colors.blue,
            goalLineColor: Colors.grey,
            dates: _selectedDates,
          ),
          const SizedBox(height: 16),
          const Text("Sodium Intake (mg)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          _buildNutrientLineChart(
            label: "Sodium",
            dataSpots: rawSodiumSpots,
            goalValue: sodiumLimit * 1000, // Convert goal (g) back to mg for display
            lineColor: Colors.purple,
            goalLineColor: Colors.grey,
            dates: _selectedDates,
          ),
          const SizedBox(height: 16),
          const Text("Fat Intake (g)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          _buildNutrientLineChart(
            label: "Fat",
            dataSpots: fatSpots,
            goalValue: fatLimit,
            lineColor: Colors.orange,
            goalLineColor: Colors.grey,
            dates: _selectedDates,
          ),
        ],
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

    final colors = [Colors.blue.shade400, Colors.purple.shade400, Colors.orange.shade400];
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


