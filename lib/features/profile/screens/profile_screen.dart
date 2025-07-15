import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

// Importamos las pantallas necesarias
import 'change_password_screen.dart';
import 'avatar_creator_screen.dart';
import 'generative_ai_screen.dart';
import 'meta_import_screen.dart';

import '../widgets/avatar_source_dialog.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isEditing = false;
  
  // Controladores y variables de estado
  final _nameController = TextEditingController();
  String? _phoneValue;
  String? _avatarUrl;
  String? _email;

  // Guardamos los datos originales para poder cancelar la edición
  Map<String, dynamic> _originalProfileData = {};

  @override
  void initState() {
    super.initState();
    _getProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  /// Obtiene los datos del perfil desde Supabase
  Future<void> _getProfile() async {
    if (!mounted) return;
    setState(() { _isLoading = true; });

    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      
      // Guardamos los datos originales para la función de cancelar
      _originalProfileData = data;

      // Poblamos los controladores y variables de estado
      _nameController.text = (data['full_name'] as String?) ?? '';
      _email = _supabase.auth.currentUser?.email ?? '';
      _phoneValue = (data['phone_number'] as String?) ?? '';
      _avatarUrl = (data['avatar_url'] as String?) ?? '';
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error al cargar el perfil.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }

    if(mounted) {
      setState(() { _isLoading = false; });
    }
  }

  /// Actualiza los datos del perfil en Supabase
  Future<void> _updateProfile() async {
    setState(() { _isLoading = true; });

    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneValue,
        'avatar_url': _avatarUrl, // <-- Guardamos la URL del avatar de RPM
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Perfil actualizado con éxito!'),
          backgroundColor: Colors.green,
        ));
      }
      // Volvemos a cargar los datos para reflejar los cambios guardados
      await _getProfile();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Error al guardar el perfil.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
    
    if(mounted) {
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAvatarCreator() async {
    final source = await showAvatarSourceDialog(context);
    if (!mounted || source == null) return;

    String? result;
    switch (source) {
      case AvatarSource.avataaars:
        result = await Navigator.push<String?>(
          context,
          MaterialPageRoute<String?>(
            builder: (context) => const AvataaarsScreen(),
          ),
        );
        break;
      case AvatarSource.generativeAI:
        result = await Navigator.push<String?>(
          context,
          MaterialPageRoute<String?>(
            builder: (context) => const GenerativeAiScreen(),
          ),
        );
        break;
      case AvatarSource.metaImport:
        result = await Navigator.push<String?>(
          context,
          MaterialPageRoute<String?>(
            builder: (context) => const MetaImportScreen(),
          ),
        );
        break;
    }

    if (!mounted) return;

    if (result == null) {
      await _getProfile();
    } else if (result.isNotEmpty) {
      setState(() {
        _avatarUrl = result;
      });
    }
  }


  /// Cierra la sesión del usuario actual.
  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Muestra un diálogo de confirmación y luego cierra sesión en otros dispositivos.
  Future<void> _signOutOthers() async {
    // ... (Tu código para _signOutOthers se mantiene igual)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Perfil' : 'Mi Perfil'),
        actions: _isEditing
            ? [
                // Botón para Guardar los cambios
                IconButton(
                  icon: const Icon(Icons.save_outlined),
                  onPressed: _updateProfile,
                  tooltip: 'Guardar Cambios',
                ),
              ]
            : [
                // Botón para ir a la pantalla de Ajustes
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () { /* TODO: Navegar a Ajustes */ },
                ),
                // Botón para cerrar sesión
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: _signOut,
                  tooltip: 'Cerrar Sesión',
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildAvatarSection(),
                const SizedBox(height: 30),
                _InfoCard(
                  title: 'Información Personal',
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Nombre Completo',
                      child: _isEditing
                          ? TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                            )
                          : Text(_nameController.text.isEmpty ? 'No añadido' : _nameController.text),
                    ),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      child: Text(_email ?? 'No disponible'),
                      trailing: const Icon(Icons.lock_outline, size: 16),
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      child: _isEditing
                          ? IntlPhoneField(
                              initialCountryCode: 'ES',
                              initialValue: _phoneValue,
                              onChanged: (phone) {
                                _phoneValue = phone.completeNumber;
                              },
                              decoration: const InputDecoration(isDense: true, border: InputBorder.none),
                            )
                          : Text(_phoneValue == null || _phoneValue!.isEmpty ? 'No añadido' : _phoneValue!),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoCard(
                  title: 'Seguridad',
                  children: [
                    _ActionRow(
                      icon: Icons.lock_outline,
                      label: 'Cambiar Contraseña',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    _ActionRow(
                      icon: Icons.phonelink_erase_outlined,
                      label: 'Cerrar sesión en otros dispositivos',
                      onTap: _signOutOthers,
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildAvatarSection() {
    final bool is3DAvatar = _avatarUrl?.endsWith('.glb') ?? false;

    return Column(
      children: [
        GestureDetector(
          // La acción de abrir el creador de avatares solo se activa en modo edición
          onTap: _isEditing ? _openAvatarCreator : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Theme.of(context).cardColor.withOpacity(0.5),
                // Si es un avatar 3D, mostramos un icono placeholder.
                // Si no, intentamos mostrar la imagen (que podría ser un PNG o SVG).
                // Si no hay URL, mostramos el avatar por defecto.
                child: is3DAvatar
                    ? const Icon(Icons.threed_rotation, size: 60, color: Colors.white)
                    : _avatarUrl != null && _avatarUrl!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              // RPM genera avatares en formato .png para las previews 2D
                              _avatarUrl!.replaceFirst('.glb', '.png'),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 100,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/images/avatar_predeterminado.png'),
                            ),
                          )
                        : ClipOval(
                            child: Image.asset('assets/images/avatar_predeterminado.png'),
                          ),
              ),
              // Mostramos un icono de "editar" sobre el avatar si estamos en modo edición
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Botón principal para entrar/salir del modo edición
        TextButton.icon(
          onPressed: () {
            if (_isEditing) {
              // Si se cancela, se restauran los datos originales sin recargar de la red
              _nameController.text =
                  (_originalProfileData['full_name'] as String?) ?? '';
              _phoneValue =
                  (_originalProfileData['phone_number'] as String?) ?? '';
              _avatarUrl =
                  (_originalProfileData['avatar_url'] as String?) ?? '';
            }
            setState(() => _isEditing = !_isEditing);
          },
          icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, size: 18),
          label: Text(_isEditing ? 'Cancelar' : 'Editar Perfil'),
        ),
      ],
    );
  }
}

// --- Widgets auxiliares (sin cambios, usa tu código) ---
class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _InfoCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;
  final Widget? trailing;
  const _InfoRow({required this.icon, required this.label, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 2),
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyLarge!,
                  child: child,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge!)),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
