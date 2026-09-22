import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../core/constants.dart';
import '../providers/transaction_provider.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  final List<Color> _presetColors = [
    Colors.orange,
    Colors.blue,
    Colors.red,
    Colors.purple,
    Colors.green,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
  ];

  final List<IconData> _presetIcons = [
    Icons.restaurant,
    Icons.directions_car,
    Icons.receipt_long,
    Icons.shopping_bag,
    Icons.medical_services,
    Icons.payments,
    Icons.school,
    Icons.movie,
    Icons.fitness_center,
    Icons.home,
    Icons.child_care,
    Icons.flight,
    Icons.gamepad,
    Icons.pets,
    Icons.more_horiz,
  ];

  void _showAddCategorySheet(TransactionProvider tp) {
    final nameController = TextEditingController();
    Color selectedColor = _presetColors.first;
    IconData selectedIcon = _presetIcons.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add New Category',
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Name Input
                Text(
                  'Category Name',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: GoogleFonts.outfit(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'e.g. Entertainment, Gym...',
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),

                // Color Selection
                Text(
                  'Select Color',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _presetColors.length,
                    itemBuilder: (context, index) {
                      final color = _presetColors[index];
                      final isSelected = selectedColor == color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: InkWell(
                          onTap: () => setSheetState(() => selectedColor = color),
                          customBorder: const CircleBorder(),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: color,
                            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Icon Selection
                Text(
                  'Select Icon',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _presetIcons.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final icon = _presetIcons[index];
                    final isSelected = selectedIcon == icon;
                    return InkWell(
                      onTap: () => setSheetState(() => selectedIcon = icon),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? selectedColor.withOpacity(0.15) : Colors.grey.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? selectedColor : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? selectedColor : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a category name')),
                            );
                            return;
                          }
                          
                          // Check duplicate
                          final exists = TransactionCategory.categories.any(
                            (c) => c.name.toLowerCase() == name.toLowerCase(),
                          );
                          if (exists) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Category already exists')),
                            );
                            return;
                          }

                          await tp.addCategory(name, selectedIcon.codePoint, selectedColor.value);
                          if (mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text('Create Category', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteCategoryConfirm(TransactionProvider tp, String categoryName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Category', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete the category "$categoryName"? This will not delete your transactions but will move them to "Others".',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await tp.deleteCategory(categoryName);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Category "$categoryName" deleted successfully')),
                );
              }
            },
            child: Text('Delete', style: GoogleFonts.outfit(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TransactionProvider>(context);
    final categories = TransactionCategory.categories;

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Categories', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.25,
        ),
        itemBuilder: (context, index) {
          final cat = categories[index];
          // Default categories shouldn't be deleted
          final isDefault = TransactionCategory.defaultCategories.any(
            (dc) => dc.name.toLowerCase() == cat.name.toLowerCase(),
          );

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 20),
                      ),
                      if (!isDefault)
                        IconButton(
                          onPressed: () => _showDeleteCategoryConfirm(tp, cat.name),
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.name,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isDefault ? 'Default Category' : 'Custom Category',
                    style: GoogleFonts.outfit(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategorySheet(tp),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
