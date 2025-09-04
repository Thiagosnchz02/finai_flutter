// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/settings/models/profile_model.dart';
import 'package:finai_flutter/features/settings/services/settings_service.dart';
import 'package:finai_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:finai_flutter/features/profile/screens/change_password_screen.dart';
import '../widgets/mfa_dialogs.dart';
import '../widgets/delete_account_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  late Future<Profile> _profileFuture;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _profileFuture = _service.getProfileSettings();
    });
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await _service.updateProfileSetting(key, value);
      _loadProfile();
    } catch (e) {
      // Manejar error si es necesario
    }
  }

  Future<void> _onMfaToggleChanged(bool currentValue) async {
    bool success = false;
    if (!currentValue) {
      success = await showMfaEnrollDialog(context);
    } else {
      success = await showMfaUnenrollDialog(context);
    }

    if (success) {
      _loadProfile();
    }
  }

  Future<void> _exportData() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      await _service.exportData();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos exportados con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al exportar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: FutureBuilder<Profile>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar la configuración: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('No se encontró el perfil.'));
          }

          final profile = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              SettingsCard(
                title: 'Apariencia',
                children: [
                  SettingsNavigationRow(
                    label: 'Tema de la Aplicación',
                    icon: Icons.palette_outlined,
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: const Text('Predeterminado del sistema'),
                                  trailing: profile.theme == 'system'
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    Navigator.pop(context);
                                    _updateSetting('theme', 'system');
                                  },
                                ),
                                ListTile(
                                  title: const Text('Claro'),
                                  trailing: profile.theme == 'light'
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    Navigator.pop(context);
                                    _updateSetting('theme', 'light');
                                  },
                                ),
                                ListTile(
                                  title: const Text('Oscuro'),
                                  trailing: profile.theme == 'dark'
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () {
                                    Navigator.pop(context);
                                    _updateSetting('theme', 'dark');
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  SettingsNavigationRow(
                    label: 'Idioma',
                    icon: Icons.language,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return SimpleDialog(
                            title: const Text('Seleccionar Idioma'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _updateSetting('language', 'es');
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Español'),
                                    if (profile.language == 'es')
                                      const Icon(Icons.check),
                                  ],
                                ),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _updateSetting('language', 'en');
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Inglés'),
                                    if (profile.language == 'en')
                                      const Icon(Icons.check),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              SettingsCard(
                title: 'Notificaciones',
                children: [
                  SettingsToggleRow(label: 'Alertas de Presupuesto', value: profile.notifyBudgetAlert, onChanged: (value) => _updateSetting('notify_budget_alert', value)),
                  SettingsToggleRow(label: 'Vencimiento de Gastos Fijos', value: profile.notifyFixedExpense, onChanged: (value) => _updateSetting('notify_fixed_expense', value)),
                  SettingsToggleRow(label: 'Metas de Ahorro Alcanzadas', value: profile.notifyGoalReached, onChanged: (value) => _updateSetting('notify_goal_reached', value)),
                ],
              ),
              SettingsCard(
                title: 'Seguridad',
                children: [
                  SettingsNavigationRow(
                    label: 'Cambiar Contraseña',
                    icon: Icons.lock_outline,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                  // --- CORRECCIÓN AQUÍ ---
                  // Conectamos el interruptor con el método que ya habíamos creado.
                  SettingsToggleRow(
                    label: 'Autenticación de Dos Factores (2FA)',
                    value: profile.dobleFactorEnabled,
                    onChanged: (value) => _onMfaToggleChanged(profile.dobleFactorEnabled),
                  ),
                ],
              ),
              SettingsCard(
                title: 'Datos de la Cuenta',
                children: [
                  SettingsActionRow(
                    label: 'Importar mis Datos',
                    icon: Icons.upload_outlined,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Funcionalidad no disponible.'),
                        ),
                      );
                    },
                  ),
                  SettingsActionRow(
                    label: 'Exportar mis Datos',
                    icon: Icons.download_outlined,
                    onTap: _exportData,
                  ),
                  SettingsActionRow(
                    label: 'Eliminar mi Cuenta',
                    icon: Icons.delete_forever_outlined,
                    color: Colors.red,
                    onTap: () => showDeleteAccountDialog(context),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}