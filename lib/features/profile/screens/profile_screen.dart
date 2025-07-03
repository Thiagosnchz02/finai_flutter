import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
// Importamos la nueva pantalla que creamos
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isEditing = false;
  
  final _nameController = TextEditingController();
  String? _phoneValue;
  
  String? _avatarUrl;
  String? _email;
  
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
  
  Future<void> _getProfile() async {
    if (_isLoading == false) { 
        setState(() { _isLoading = true; });
    }

    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _supabase.from('profiles').select().eq('id', userId).single();
      
      _nameController.text = (data['full_name'] as String?) ?? '';
      _email = _supabase.auth.currentUser?.email ?? '';
      _phoneValue = (data['phone_number'] as String?) ?? '';
      _avatarUrl = (data['avatar_url'] as String?) ?? '';
      
    } on PostgrestException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al cargar perfil: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Ocurrió un error inesperado'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }

    if(mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;
      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'phone_number': _phoneValue,
      }).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('¡Perfil actualizado con éxito!'),
          backgroundColor: Colors.green,
        ));
      }
    } on PostgrestException catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Ocurrió un error inesperado'),
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
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar acción'),
          content: const Text('Esto cerrará tu sesión en todos los demás dispositivos. ¿Estás seguro?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldSignOut != true) {
      return;
    }

    try {
      await _supabase.auth.signOut(scope: SignOutScope.others);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sesión cerrada en otros dispositivos con éxito.'),
          backgroundColor: Colors.green,
        ));
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${e.message}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Perfil' : 'Mi Perfil'),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _getProfile();
                    });
                  },
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => setState(() => _isEditing = true),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () {
                    // TODO: Navegar a la pantalla de Ajustes
                  },
                ),
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
                              decoration: const InputDecoration(isDense: true),
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
                              decoration: const InputDecoration(isDense: true),
                            )
                          : Text(_phoneValue == null || _phoneValue!.isEmpty ? 'No añadido' : _phoneValue!),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _InfoCard(
                  title: 'Seguridad',
                  children: [
                    // Acción para navegar a la pantalla de cambiar contraseña
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
                    // Acción para cerrar sesión en otros dispositivos
                    _ActionRow(
                      icon: Icons.phonelink_erase_outlined,
                      label: 'Cerrar sesión en otros dispositivos',
                      onTap: _signOutOthers,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                if (_isEditing)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)
                    ),
                    onPressed: _updateProfile,
                    child: const Text('Guardar Cambios'),
                  ),
              ],
            ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Theme.of(context).cardColor.withOpacity(0.5),
          child: _avatarUrl != null && _avatarUrl!.isNotEmpty
              ? ClipOval(
                  child: SvgPicture.network(
                    _avatarUrl!,
                    placeholderBuilder: (_) => const CircularProgressIndicator(),
                    width: 120,
                    height: 120,
                  ),
                )
              : ClipOval(
                  child: Image.asset(
                    'assets/images/avatar_predeterminado.png',
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
        ),
      ],
    );
  }
}

// --- Widgets auxiliares sin cambios ---

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