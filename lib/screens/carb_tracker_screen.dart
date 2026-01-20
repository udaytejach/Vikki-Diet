import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import '../models/food_item.dart';
import '../items.dart';
import '../constants/app_theme.dart';
import 'search_page.dart';

class CarbTrackerScreen extends StatefulWidget {
  const CarbTrackerScreen({super.key});

  @override
  State<CarbTrackerScreen> createState() => _CarbTrackerScreenState();
}

class _CarbTrackerScreenState extends State<CarbTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _gramsController = TextEditingController();

  FoodItem? selectedItem;
  double grams = 0;
  double calculatedCarbs = 0;

  // Parse items from items.dart
  late List<FoodItem> allItems;
  late Map<String, List<FoodItem>> itemsByCategory;

  // Track selections per tab
  Map<int, FoodItem?> selectedItemPerTab = {
    0: null,
    1: null,
    2: null,
    3: null,
    4: null,
  };
  Map<int, double> gramsPerTab = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};
  Map<int, Map<String, double>> nutritionPerTab = {
    0: {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0},
    1: {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0},
    2: {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0},
    3: {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0},
    4: {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0},
  };
  int currentTabIndex = 0;
  late List<String> categoryTabs;

  @override
  void initState() {
    super.initState();
    // Parse items from items.dart
    // ignore: unnecessary_cast
    allItems = (Items as List)
        .map((item) => FoodItem.fromMap(item as Map<String, dynamic>))
        .toList();

    // Group items by category
    itemsByCategory = {};
    for (var item in allItems) {
      if (!itemsByCategory.containsKey(item.category)) {
        itemsByCategory[item.category] = [];
      }
      itemsByCategory[item.category]!.add(item);
    }

    // Get unique categories
    categoryTabs = itemsByCategory.keys.toList();

    _tabController = TabController(length: categoryTabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    setState(() {
      currentTabIndex = _tabController.index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gramsController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final shouldExit = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text(
            'Exit App',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 12.0),
            child: Text(
              'Do you want to exit the app?',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.secondaryColor),
              ),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Exit',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit ?? false) {
      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  void calculateNutrition() {
    FoodItem? item = selectedItemPerTab[currentTabIndex];
    double gramValue = gramsPerTab[currentTabIndex] ?? 0;
    if (item != null && gramValue > 0) {
      setState(() {
        nutritionPerTab[currentTabIndex] = {
          'calories': (item.calories * gramValue) / 100,
          'protein': (item.protein * gramValue) / 100,
          'carbs': (item.carbs * gramValue) / 100,
          'fat': (item.fat * gramValue) / 100,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categoryTabs.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String currentCategory = categoryTabs[currentTabIndex];
    // ignore: unused_local_variable
    List<FoodItem> currentItems = itemsByCategory[currentCategory] ?? [];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vikki Diet Tracker'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchPage(allItems: allItems),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: categoryTabs.map((category) => Tab(text: category)).toList(),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: categoryTabs.map((category) {
                  List<FoodItem> items = itemsByCategory[category] ?? [];
                  return _buildFoodList(items);
                }).toList(),
              ),
            ),
            if (selectedItemPerTab[currentTabIndex] != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _gramsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Enter grams',
                        labelStyle: const TextStyle(color: Colors.grey),
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        prefixIcon: const Icon(
                          Icons.scale,
                          color: AppTheme.primaryColor,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.cardColor,
                      ),
                      onChanged: (value) {
                        setState(() {
                          gramsPerTab[currentTabIndex] =
                              double.tryParse(value) ?? 0;
                          calculateNutrition();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.cardColor,
                            AppTheme.cardColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${selectedItemPerTab[currentTabIndex]!.name}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (selectedItemPerTab[currentTabIndex]!
                              .teluguName
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                'తెలుగు: ${selectedItemPerTab[currentTabIndex]!.teluguName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white70,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          Text(
                            'Amount: ${(gramsPerTab[currentTabIndex] ?? 0).toStringAsFixed(1)}g',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundColor.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNutritionRow(
                                  'Calories',
                                  '${(nutritionPerTab[currentTabIndex]?['calories'] ?? 0).toStringAsFixed(1)} kcal',
                                  AppTheme.caloriesColor,
                                ),
                                _buildNutritionRow(
                                  'Protein',
                                  '${(nutritionPerTab[currentTabIndex]?['protein'] ?? 0).toStringAsFixed(2)}g',
                                  AppTheme.proteinColor,
                                ),
                                _buildNutritionRow(
                                  'Carbs',
                                  '${(nutritionPerTab[currentTabIndex]?['carbs'] ?? 0).toStringAsFixed(2)}g',
                                  AppTheme.carbsColor,
                                ),
                                _buildNutritionRow(
                                  'Fat',
                                  '${(nutritionPerTab[currentTabIndex]?['fat'] ?? 0).toStringAsFixed(2)}g',
                                  AppTheme.fatColor,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodList(List<FoodItem> items) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: items.map((item) {
            bool isSelected =
                selectedItemPerTab[currentTabIndex]?.name == item.name;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: GestureDetector(
                onTap: () {
                  _selectItem(item);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withOpacity(0.2),
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : AppTheme.cardColor,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : [],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.teluguName.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              item.teluguName,
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Cal: ${item.calories.toStringAsFixed(0)} | P: ${item.protein.toStringAsFixed(1)}g | C: ${item.carbs.toStringAsFixed(1)}g | F: ${item.fat.toStringAsFixed(1)}g',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _selectItem(FoodItem item) {
    bool isCurrentlySelected =
        selectedItemPerTab[currentTabIndex]?.name == item.name;
    setState(() {
      if (isCurrentlySelected) {
        // If already selected, deselect it (hide details)
        selectedItemPerTab[currentTabIndex] = null;
        nutritionPerTab[currentTabIndex] = {
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
        };
        gramsPerTab[currentTabIndex] = 0;
        _gramsController.clear();
      } else {
        // If not selected, select it (show details)
        selectedItemPerTab[currentTabIndex] = item;
        nutritionPerTab[currentTabIndex] = {
          'calories': 0,
          'protein': 0,
          'carbs': 0,
          'fat': 0,
        };
        gramsPerTab[currentTabIndex] = 0;
        _gramsController.clear();
      }
    });
  }
}
