import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;

class MetaImportScreen extends StatefulWidget {
  const MetaImportScreen({super.key});

  @override
  State<MetaImportScreen> createState() => _MetaImportScreenState();
}

class _MetaImportScreenState extends State<MetaImportScreen> {
  bool _loading = false;
  String? _avatarUrl;

  Future<void> _loginAndFetch() async {
    setState(() => _loading = true);
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['public_profile'],
      );
      if (result.status == LoginStatus.success) {
        final AccessToken fbToken = result.accessToken!;
        final String token = fbToken.token;
        final uri = Uri.parse(
          'https://graph.facebook.com/me/avatar?fields=image_url&access_token=$token',
        );
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body) as Map<String, dynamic>;
          final url = data['image_url'] as String?;
          setState(() => _avatarUrl = url);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ${resp.statusCode}: ${resp.body}')),
          );
        }
      } else if (result.status == LoginStatus.cancelled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicio de sesión cancelado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${result.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al conectar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar Avatar de Facebook')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _avatarUrl == null
                ? ElevatedButton(
                    onPressed: _loginAndFetch,
                    child: const Text('Conectar con Facebook'),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(_avatarUrl!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(
                          context,
                          {'type': 'meta', 'url': _avatarUrl},
                        ),
                        child: const Text('Usar este avatar'),
                      ),
                    ],
                  ),
      ),
    );
  }
}


