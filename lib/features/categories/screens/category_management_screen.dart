// lib/features/categories/screens/category_management_screen.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:finai_flutter/presentation/widgets/finai_aurora_background.dart';
import '../widgets/category_grid_view.dart';
import 'add_edit_category_screen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // La estructura ahora es un Stack que contiene el fondo y luego el Scaffold.
    // El Scaffold se hace transparente para dejar ver el fondo.
    return Stack(
      children: [
        const Positioned.fill(child: FinAiAuroraBackground()),
        DefaultTabController(
          length: 2,
          child: Scaffold(
            backgroundColor: Colors.transparent, // Hacemos el Scaffold transparente
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Categorías', style: TextStyle(fontWeight: FontWeight.bold)),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(110.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      const TabBar(
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(16.0)),
                          color: Color(0xFF5A67D8),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: [
                          Tab(text: 'Estándar'),
                          Tab(text: 'Personalizadas'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // El body ahora es directamente el TabBarView.
            // El Scaffold se encarga de colocarlo debajo del AppBar sin solapamientos.
            body: TabBarView(
              children: [
                CategoryGridView(
                  key: const Key('standard_grid'),
                  isCustom: false,
                  searchQuery: _searchQuery,
                ),
                CategoryGridView(
                  key: const Key('custom_grid'),
                  isCustom: true,
                  searchQuery: _searchQuery,
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const AddEditCategoryScreen()),
                );
                if (result == true && mounted) {
                  setState(() {}); // Forzamos reconstrucción para recargar datos
                }
              },
              backgroundColor: const Color(0xFF5A67D8),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ),
      ],
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
}