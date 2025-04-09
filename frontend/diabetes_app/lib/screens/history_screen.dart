import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:diabetes_app/services/auth_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> history = [];
  bool isLoading = true;
  // Track expanded state for each history item
  Map<int, bool> expandedItems = {};

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('jwt_token');

    if (token == null) {
      setState(() {
        isLoading = false;
        history = [];
      });
      return;
    }

    final response = await http.get(
      Uri.parse('http://localhost:8080/history'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        history = data['history'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
        history = [];
      });
    }
  }

  // Helper method to parse nutrients JSON
  Map<String, dynamic> parseNutrients(String nutrientsString) {
    try {
      if (nutrientsString.isNotEmpty) {
        return json.decode(nutrientsString);
      }
    } catch (e) {
      print("Error parsing nutrients: $e");
    }
    return {};
  }

  // Helper method to format nutrient name
  String formatNutrientName(String name) {
    name = name.replaceAll('_', ' ');
    return name.isNotEmpty ? name[0].toUpperCase() + name.substring(1) : name;
  }

  // Helper method to get appropriate unit for a nutrient
  String getNutrientUnit(String name) {
    if (name.contains('carb') || 
        name.contains('protein') || 
        name.contains('fat') || 
        name.contains('fiber')) {
      return 'g';
    } else if (name.contains('sodium') || name.contains('potassium')) {
      return 'mg';
    } else if (name.contains('vitamin')) {
      return '%';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Diet + Glucose History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: () {
              AuthService().logout(context);
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? const Center(child: Text("No logs available"))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final nutrientsMap = parseNutrients(entry['nutrients'] ?? '');
                    final isExpanded = expandedItems[index] ?? false;
                    
                    // Get key nutrients for summary view
                    final keyNutrients = ['protein', 'carbs', 'fat', 'fiber']
                        .where((key) => nutrientsMap.containsKey(key))
                        .toList();
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("📅 ${entry['timestamp']}", 
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text("🍽 Food: ${entry['food_description']}"),
                            Text("🔥 Calories: ${entry['calories']}"),
                            
                            // Nutrients section with expand/collapse
                            if (nutrientsMap.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Text("🔬 Nutrients:", 
                                      style: TextStyle(fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        expandedItems[index] = !isExpanded;
                                      });
                                    },
                                    child: Text(
                                      isExpanded ? "Collapse" : "Expand",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              // Summary view (when collapsed)
                              if (!isExpanded && keyNutrients.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 8.0,
                                    children: keyNutrients.map((key) {
                                      final name = formatNutrientName(key);
                                      final unit = getNutrientUnit(key);
                                      final value = nutrientsMap[key] is double 
                                          ? (nutrientsMap[key] as double).toStringAsFixed(1) 
                                          : nutrientsMap[key].toString();
                                      
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "$name: $value$unit",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              
                              // Detailed view (when expanded)
                              if (isExpanded)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Wrap(
                                    spacing: 8.0,
                                    runSpacing: 4.0,
                                    children: nutrientsMap.entries.map((mapEntry) {
                                      final name = formatNutrientName(mapEntry.key);
                                      final unit = getNutrientUnit(mapEntry.key);
                                      final value = mapEntry.value is double 
                                          ? (mapEntry.value as double).toStringAsFixed(1) 
                                          : mapEntry.value.toString();
                                      
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        margin: const EdgeInsets.only(bottom: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "$name: $value$unit",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                            ] else
                              const Text("🔬 Nutrients: Not available"),
                            
                            const SizedBox(height: 8),
                            Text("💉 Glucose: ${entry['glucose_level']} mg/dL"),
                            Text("🕒 Meal Tag: ${entry['meal_tag']}"),
                            Text("📌 Meal Type: ${entry['meal_type']}"),
                            Text("📝 Notes: ${entry['notes']}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
