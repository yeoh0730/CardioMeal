import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/custom_button.dart';

class EditDietPreferencePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const EditDietPreferencePage({Key? key, required this.userData})
      : super(key: key);

  @override
  _EditDietPreferencePageState createState() => _EditDietPreferencePageState();
}

class _EditDietPreferencePageState extends State<EditDietPreferencePage> {
  List<String> _selectedDietPreferences = [];
  late TextEditingController _freePreferenceController;

  final Map<String, String> _tooltipTexts = {
    "Dairy-Free": "Dairy-free diets exclude milk, cheese, yogurt, and other dairy products. Suitable for people with lactose intolerance or dairy allergies.",
    "Gluten-Free": "Gluten-free diets exclude wheat, barley, rye, and other gluten-containing foods. Important for people with celiac disease or gluten sensitivity.",
    "Vegan": "Vegan diets exclude all animal products including meat, dairy, eggs, and honey. Suitable for those following a plant-based lifestyle.",
    "Vegetarian": "Vegetarian diets exclude meat and fish but may include dairy and eggs. Ideal for those avoiding meat but not all animal products.",
  };

  final List<String> _dietaryOptions = [
    "None",
    "Dairy-Free",
    "Gluten-Free",
    "High-Fiber",
    "High-Protein",
    "Low-Calorie",
    "Low-Carb",
    "Low-Fat",
    "Low-Sugar",
    "Vegan",
    "Vegetarian",
  ];

  OverlayEntry? _overlayEntry;
  bool _tooltipVisible = false;

  @override
  void initState() {
    super.initState();
    _selectedDietPreferences =
    List<String>.from(widget.userData?['dietaryPreferences'] ?? []);
    String freePrefs = _selectedDietPreferences
        .where((pref) => !_dietaryOptions.contains(pref))
        .join(", ");
    _freePreferenceController = TextEditingController(text: freePrefs);
  }

  void _toggleDietaryPreference(String preference) {
    setState(() {
      if (_selectedDietPreferences.contains(preference)) {
        _selectedDietPreferences.remove(preference);
      } else {
        _selectedDietPreferences.removeWhere((item) => !_dietaryOptions.contains(item));
        _freePreferenceController.clear();
        _selectedDietPreferences.add(preference);
      }
    });
  }

  void _saveDietPreferences() async {
    final freeInput = _freePreferenceController.text.trim();
    List<String> freePrefs = [];
    if (freeInput.isNotEmpty) {
      freePrefs = freeInput.split(',').map((e) => e.trim()).toList();
    }

    List<String> combinedPrefs = freePrefs.isNotEmpty
        ? freePrefs
        : _selectedDietPreferences.toSet().toList();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'dietaryPreferences': combinedPrefs,
      });
      Navigator.pop(context, true);
    }
  }

  void _showTooltip(BuildContext context, GlobalKey key, String message) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (renderBox == null || overlay == null) return;

    final position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + renderBox.size.height + 6,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxWidth: 260),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Text(message, style: const TextStyle(fontSize: 13)),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _tooltipVisible = true;
  }

  void _toggleTooltip(BuildContext context, GlobalKey key, String message) {
    if (_tooltipVisible) {
      _removeTooltip();
    } else {
      _showTooltip(context, key, message);
    }
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _tooltipVisible = false;
  }

  Widget _buildCheckbox(String preference) {
    final bool hasTooltip = _tooltipTexts.containsKey(preference);
    final GlobalKey iconKey = GlobalKey();

    return CheckboxListTile(
      controlAffinity: ListTileControlAffinity.trailing,
      activeColor: Colors.red,
      value: _selectedDietPreferences.contains(preference),
      onChanged: (bool? value) {
        _toggleDietaryPreference(preference);
      },
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(preference),
          if (hasTooltip)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                key: iconKey,
                onTap: () {
                  _toggleTooltip(context, iconKey, _tooltipTexts[preference]!);
                },
                child: const Icon(Icons.info_outline, size: 20, color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _removeTooltip,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Edit Diet Preferences"),
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Describe your preference in your own words:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _freePreferenceController,
                decoration: InputDecoration(
                  hintText: "e.g., I prefer dairy-free dishes or meals that contain salmon.",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                maxLines: null,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text("Or select from the list below:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _dietaryOptions.map(_buildCheckbox).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: "Save Changes",
                  onPressed: _saveDietPreferences,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
