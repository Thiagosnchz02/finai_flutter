// lib/features/categories/screens/category_management_screen.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:finai_flutter/presentation/widgets/finai_aurora_background.dart';
import '../services/category_service.dart';
import '../widgets/category_card.dart';
import '../widgets/custom_tab_bar.dart';
import 'subcategory_screen.dart';
import 'add_edit_category_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  final CategoryService _categoryService = CategoryService();
  late TabController _tabController;

  late Future<List<Category>> _standardCategoriesFuture;
  late Future<List<Category>> _customCategoriesFuture;

  List<Category> _standardCategories = [];
  List<Category> _customCategories = [];
  List<Category> _filteredStandard = [];
  List<Category> _filteredCustom = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(_filterCategories);
  }

  void _loadData() {
    _standardCategoriesFuture = _categoryService.getStandardCategories();
    _customCategoriesFuture = _categoryService.getCustomCategories();

    _standardCategoriesFuture.then((value) {
      if (mounted) {
        setState(() {
          _standardCategories = value;
          _filteredStandard = value;
        });
      }
    });
    _customCategoriesFuture.then((value) {
      if (mounted) {
        setState(() {
          _customCategories = value;
          _filteredCustom = value;
        });
      }
    });
  }
  
  void _filterCategories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStandard = _standardCategories
          .where((cat) => cat.name.toLowerCase().contains(query))
          .toList();
      _filteredCustom = _customCategories
          .where((cat) => cat.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildSearchBar(),
                const SizedBox(height: 16),
                CustomTabBar(
                  tabController: _tabController,
                  tabs: const ['Estándar', 'Personalizadas'],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: FinAiAuroraBackground()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 150), // Espacio para dejar visible el AppBar
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryGrid(_filteredStandard),
                  _buildCategoryGrid(_filteredCustom, isCustom: true),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
      // Navega y espera un resultado para saber si debe recargar
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AddEditCategoryScreen()),
      );
      if (result == true) {
        _loadData(); // Recarga los datos si la pantalla anterior guardó algo
      }
    },
        backgroundColor: const Color(0xFF5A67D8),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar categoría...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(List<Category> categories, {bool isCustom = false}) {
    if (categories.isEmpty && _searchController.text.isNotEmpty) {
      return const Center(child: Text("No se encontraron categorías.", style: TextStyle(color: Colors.white70)));
    }
  
    if (categories.isEmpty) {
        return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                  isCustom ? "Aún no has creado categorías personalizadas. ¡Toca el botón '+' para empezar!" : "No hay categorías estándar disponibles.",
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
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryCard(
          category: category,
          onTap: () {
            // <-- LÓGICA DE NAVEGACIÓN ACTUALIZADA
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubcategoryScreen(
                  parentCategoryId: category.id,
                  parentCategoryName: category.name,
                ),
              ),
            );
          },
          onEdit: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditCategoryScreen(category: category),
              ),
            );
            if (result == true) {
              _loadData();
            }
          },
          onArchive: () {
            _categoryService.archiveCategory(category.id).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${category.name}" ha sido archivada.')),
              );
              _loadData(); // Recarga los datos para refrescar la UI
            });
          },
        );
      },
    );
  }
}