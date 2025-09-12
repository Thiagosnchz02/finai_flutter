// lib/features/categories/widgets/category_grid_view.dart

import 'package:flutter/material.dart';
import '../screens/add_edit_category_screen.dart';
import '../screens/subcategory_screen.dart';
import '../services/category_service.dart';
import 'category_card.dart';

class CategoryGridView extends StatefulWidget {
  final bool isCustom;
  final String searchQuery;

  const CategoryGridView({
    super.key,
    required this.isCustom,
    required this.searchQuery,
  });

  @override
  State<CategoryGridView> createState() => _CategoryGridViewState();
}

class _CategoryGridViewState extends State<CategoryGridView> {
  final CategoryService _categoryService = CategoryService();
  late Future<List<Category>> _categoriesFuture;
  List<Category> _allCategories = [];
  List<Category> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  // Se llama cuando el widget es reconstruido con nuevos parámetros (ej. nueva búsqueda)
  @override
  void didUpdateWidget(covariant CategoryGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _filterCategories();
    }
  }

  void _loadData() {
    _categoriesFuture = widget.isCustom
        ? _categoryService.getCustomCategories()
        : _categoryService.getStandardCategories();

    _categoriesFuture.then((value) {
      if (mounted) {
        setState(() {
          _allCategories = value;
          _filterCategories();
        });
      }
    });
  }

  void _filterCategories() {
    final query = widget.searchQuery.toLowerCase();
    setState(() {
      _filteredCategories = _allCategories
          .where((cat) => cat.name.toLowerCase().contains(query))
          .toList();
    });
  }
  
  void _archiveCategory(Category category) {
     _categoryService.archiveCategory(category.id).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${category.name}" ha sido archivada.')),
        );
        _loadData(); // Recarga los datos para refrescar la UI
      });
  }

  void _editCategory(Category category) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditCategoryScreen(category: category),
      ),
    );
    if (result == true && mounted) {
      _loadData();
    }
  }

  void _navigateToSubcategories(Category category) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubcategoryScreen(
            parentCategoryId: category.id,
            parentCategoryName: category.name,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _allCategories.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white70)));
        }

        if (_filteredCategories.isEmpty && widget.searchQuery.isNotEmpty) {
          return const Center(child: Text("No se encontraron categorías.", style: TextStyle(color: Colors.white70)));
        }
      
        if (_allCategories.isEmpty) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                      widget.isCustom ? "Aún no has creado categorías personalizadas. ¡Toca el botón '+' para empezar!" : "No hay categorías estándar disponibles.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: _filteredCategories.length,
          itemBuilder: (context, index) {
            final category = _filteredCategories[index];
            return CategoryCard(
              category: category,
              onTap: () => _navigateToSubcategories(category),
              onEdit: () => _editCategory(category),
              onArchive: () => _archiveCategory(category),
            );
          },
        );
      },
    );
  }
}