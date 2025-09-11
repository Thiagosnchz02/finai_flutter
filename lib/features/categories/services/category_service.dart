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

  Category({
    required this.id,
    required this.name,
    this.userId,
    required this.hierarchyLevel,
    this.parentId,
    required this.isArchived,
    this.iconData,
  });

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      userId: map['user_id'],
      hierarchyLevel: map['hierarchy_level'] ?? 1,
      parentId: map['parent_id'],
      isArchived: map['is_archived'] ?? false,
      iconData: map['icon'], // Asumiendo que la columna se llama 'icon'
    );
  }

  // Propiedad para determinar si una categoría es estándar (del sistema) o personalizada
  bool get isStandard => userId == null;
}


class CategoryService {
  final _supabase = Supabase.instance.client;

  /// Obtiene las categorías estándar (del sistema) de Nivel 1.
  Future<List<Category>> getStandardCategories() async {
    final response = await _supabase
        .from('categories')
        .select()
        .filter('user_id', 'is', null) // <-- CORRECCIÓN APLICADA AQUÍ
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

  /// Archiva una categoría definida por el usuario.
  Future<void> archiveCategory(String categoryId) async {
    await _supabase.from('categories').update({
      'is_archived': true,
      'archived_at': DateTime.now().toIso8601String(),
    }).eq('id', categoryId);
  }
}