class FoodItem {
  final String name;
  final String teluguName;
  final String category;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  FoodItem({
    required this.name,
    required this.teluguName,
    required this.category,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      name: map['Item'] ?? '',
      teluguName: map['teluguItem'] ?? '',
      category: map['Category'] ?? '',
      calories: (map['Calories (kcal)'] ?? 0).toDouble(),
      protein: (map['Protein (g)'] ?? 0).toDouble(),
      carbs: (map['Carbs (g)'] ?? 0).toDouble(),
      fat: (map['Fat (g)'] ?? 0).toDouble(),
    );
  }
}
