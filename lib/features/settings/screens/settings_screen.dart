// lib/features/settings/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:finai_flutter/features/settings/models/profile_model.dart';
import 'package:finai_flutter/features/settings/services/settings_service.dart';
import 'package:finai_flutter/features/settings/widgets/settings_widgets.dart';
import 'package:finai_flutter/features/profile/screens/change_password_screen.dart';
import '../widgets/mfa_dialogs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  late Future<Profile> _profileFuture;

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
                  SettingsNavigationRow(label: 'Tema de la Aplicación', icon: Icons.palette_outlined, onTap: () {}),
                  SettingsNavigationRow(label: 'Idioma', icon: Icons.language, onTap: () {}),
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
                  SettingsActionRow(label: 'Exportar mis Datos', icon: Icons.download_outlined, onTap: () {}),
                  SettingsActionRow(label: 'Eliminar mi Cuenta', icon: Icons.delete_forever_outlined, color: Colors.red, onTap: () {}),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}