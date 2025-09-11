// lib/features/categories/screens/subcategory_screen.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/presentation/widgets/finai_aurora_background.dart';
import '../services/category_service.dart';
import '../widgets/category_card.dart';

class SubcategoryScreen extends StatefulWidget {
  final String parentCategoryId;
  final String parentCategoryName;

  const SubcategoryScreen({
    super.key,
    required this.parentCategoryId,
    required this.parentCategoryName,
  });

  @override
  State<SubcategoryScreen> createState() => _SubcategoryScreenState();
}

class _SubcategoryScreenState extends State<SubcategoryScreen> {
  final CategoryService _categoryService = CategoryService();
  late Future<List<Category>> _subcategoriesFuture;

  @override
  void initState() {
    super.initState();
    _subcategoriesFuture = _categoryService.fetchSubcategories(widget.parentCategoryId);
  }

  // Maneja la navegación al tocar una tarjeta de subcategoría
  void _handleCardTap(Category tappedCategory) async {
    final hasChildren = await _categoryService.hasSubcategories(tappedCategory.id);

    if (mounted) {
      if (hasChildren) {
        // Navega recursivamente a la misma pantalla con los nuevos datos del padre
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubcategoryScreen(
              parentCategoryId: tappedCategory.id,
              parentCategoryName: tappedCategory.name,
            ),
          ),
        );
      } else {
        // Es un nodo final, devuelve la categoría seleccionada
        Navigator.pop(context, tappedCategory);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.parentCategoryName),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: FinAiAuroraBackground()),
          SafeArea(
            child: FutureBuilder<List<Category>>(
              future: _subcategoriesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar las subcategorías: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final subcategories = snapshot.data ?? [];

                if (subcategories.isEmpty) {
                  return const Center(
                    child: Text(
                      'Esta categoría no tiene subcategorías.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = subcategories[index];
                    return CategoryCard(
                      category: subcategory,
                      onTap: () => _handleCardTap(subcategory),
                      onEdit: () {
                        // La edición/archivado se maneja desde la pantalla principal
                        // o se podría implementar aquí si fuese necesario.
                      },
                      onArchive: () {},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}