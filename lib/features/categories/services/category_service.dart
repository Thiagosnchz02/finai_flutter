// lib/features/categories/services/category_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

// Modelo simple para representar una Categoría
class Category {
  final String id;
  final String name;
  final String? userId;
  final int hierarchyLevel;
  final String? parentId;
  final bool isArchived;
  // Placeholder para el icono, asumiendo que se guarda como un String, ej: 'home'
  final String? iconData;
  // Placeholder para el color
  final String? color;
  final String? type;

  Category({
    required this.id,
    required this.name,
    this.userId,
    required this.hierarchyLevel,
    this.parentId,
    required this.isArchived,
    this.iconData,
    this.color,
    this.type,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      userId: map['user_id'],
      hierarchyLevel: map['hierarchy_level'] ?? 1,
      parentId: map['parent_id'],
      isArchived: map['is_archived'] ?? false,
      iconData: map['icon'],
      color: map['color'],
      type: map['type'],
    );
  }

  bool get isStandard => userId == null;
}


class CategoryService {
  final _supabase = Supabase.instance.client;

  /// Obtiene una única categoría por su ID.
  Future<Category?> getCategoryById(String id) async {
    final response = await _supabase
        .from('categories')
        .select()
        .eq('id', id)
        .single();
    return Category.fromMap(response);
  }

  /// Obtiene las categorías estándar (del sistema) de Nivel 1.
  Future<List<Category>> getStandardCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .filter('user_id', 'is', null)
        .eq('hierarchy_level', 1)
        .order('name', ascending: true);
        
    return response.map((item) => Category.fromMap(item)).toList();
  }

  /// Obtiene las categorías personalizadas de Nivel 1 para el usuario actual.
  Future<List<Category>> getCustomCategories() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _supabase
        .from('categories')
        .select()
        .eq('user_id', userId)
        .eq('is_archived', false)
        .order('name', ascending: true);

    return response.map((item) => Category.fromMap(item)).toList();
  }

  /// Obtiene las subcategorías (hijos) de una categoría padre.
  Future<List<Category>> fetchSubcategories(String parentId) async {
    final response = await _supabase
        .from('categories')
        .select()
        .eq('parent_id', parentId)
        .eq('is_archived', false)
        .order('name', ascending: true);
    
    return response.map((item) => Category.fromMap(item)).toList();
  }

  /// Comprueba de forma eficiente si una categoría tiene subcategorías.
  Future<bool> hasSubcategories(String categoryId) async {
    final response = await _supabase
        .from('categories')
        .select('id')
        .eq('parent_id', categoryId)
        .eq('is_archived', false)
        .limit(1);

    return response.isNotEmpty;
  }
  
  /// **NUEVO:** Guarda (crea o actualiza) una categoría.
  Future<void> saveCategory({
    required String name,
    required String? parentId,
    required String? icon,
    required String? color,
    Category? existingCategory, // Si se provee, estamos en modo edición
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final isEditing = existingCategory != null;

    if (isEditing) {
      // --- LÓGICA DE ACTUALIZACIÓN ---
      await _supabase.from('categories').update({
        'name': name,
        'icon': icon,
        'color': color,
      }).eq('id', existingCategory.id);
    } else {
      // --- LÓGICA DE CREACIÓN ---
      if (parentId == null) {
        throw Exception('Se requiere una categoría padre para crear una nueva.');
      }
      
      // 1. Obtener datos del padre
      final parentCategory = await getCategoryById(parentId);
      if (parentCategory == null) {
        throw Exception('La categoría padre no fue encontrada.');
      }

      // 2. Insertar la nueva categoría
      await _supabase.from('categories').insert({
        'name': name,
        'icon': icon,
        'color': color,
        'user_id': user.id,
        'parent_id': parentId,
        'hierarchy_level': parentCategory.hierarchyLevel + 1,
        'type': parentCategory.type, // Hereda el tipo (gasto/ingreso) del padre
        'is_default': false,
      });
    }
  }

  Future<void> archiveCategory(String categoryId) async {
    await _supabase.from('categories').update({
      'is_archived': true,
      'archived_at': DateTime.now().toIso8601String(),
    }).eq('id', categoryId);
  }
}