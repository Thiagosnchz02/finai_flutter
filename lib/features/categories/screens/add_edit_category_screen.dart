// lib/features/categories/screens/add_edit_category_screen.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/presentation/widgets/finai_aurora_background.dart';
import 'package:finai_flutter/presentation/widgets/glass_card.dart';
import '../services/category_service.dart';
import 'category_management_screen.dart'; // Para el flujo de selección

class AddEditCategoryScreen extends StatefulWidget {
  final Category? category; // Si es null, estamos creando. Si no, editando.

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() => _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryService = CategoryService();

  // Estado del formulario
  Category? _parentCategory;
  String _selectedIcon = 'category'; // Valor por defecto
  String _selectedColor = 'FF5A67D8'; // Color primario por defecto
  bool _isLoading = false;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.category!.name;
      _selectedIcon = widget.category!.iconData ?? 'category';
      _selectedColor = widget.category!.color ?? 'FF5A67D8';
      // En modo edición, cargamos el padre para mostrar su nombre
      if (widget.category!.parentId != null) {
        _categoryService.getCategoryById(widget.category!.parentId!).then((parent) {
          if (mounted) setState(() => _parentCategory = parent);
        });
      }
    }
  }
  
  Future<void> _selectParentCategory() async {
    // Navega a la pantalla de selección y espera un resultado.
    final selected = await Navigator.push<Category>(
      context,
      MaterialPageRoute(builder: (context) => const CategoryManagementScreen()),
    );

    if (selected != null) {
      setState(() {
        _parentCategory = selected;
      });
    }
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    // Validación adicional para el modo 'Crear'
    if (!isEditing && _parentCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes agrupar la categoría dentro de otra.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _categoryService.saveCategory(
        name: _nameController.text.trim(),
        parentId: _parentCategory?.id,
        icon: _selectedIcon,
        color: _selectedColor,
        existingCategory: widget.category,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría guardada con éxito'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true); // Devuelve 'true' para indicar que se debe refrescar
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Categoría' : 'Añadir Categoría'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveCategory,
            icon: const Icon(Icons.save),
            tooltip: 'Guardar',
          )
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: FinAiAuroraBackground()),
          SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- Tarjeta para el Nombre ---
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Nombre de la Categoría',
                          labelStyle: TextStyle(color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty)
                            ? 'El nombre es obligatorio'
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Tarjeta para Icono y Color (Placeholder) ---
                  GlassCard(
                    child: ListTile(
                      onTap: () {
                        // TODO: Abrir modal de selección de icono y color
                        print("Abrir selector de icono y color");
                      },
                      leading: Icon(Icons.palette_outlined, color: Colors.white70),
                      title: const Text('Icono y Color', style: TextStyle(color: Colors.white)),
                      trailing: CircleAvatar(
                        backgroundColor: Color(int.parse('0x$_selectedColor')),
                        child: Icon(Icons.category, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // --- Tarjeta para Agrupar Categoría ---
                  GlassCard(
                    child: ListTile(
                      onTap: isEditing ? null : _selectParentCategory, // Deshabilitado en modo edición
                      leading: Icon(Icons.account_tree_outlined, color: Colors.white70),
                      title: const Text('Agrupar Dentro De', style: TextStyle(color: Colors.white)),
                      subtitle: Text(
                        _parentCategory?.name ?? (isEditing ? 'No se puede cambiar' : 'Toca para seleccionar'),
                        style: TextStyle(color: isEditing ? Colors.grey : Colors.white70),
                      ),
                      trailing: isEditing ? null : const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                    ),
                  ),

                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}