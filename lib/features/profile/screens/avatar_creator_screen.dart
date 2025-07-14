// lib/features/profile/screens/avatar_creator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AvataaarsScreen extends StatefulWidget {
  const AvataaarsScreen({super.key});

  @override
  State<AvataaarsScreen> createState() => _AvataaarsScreenState();
}

class _AvataaarsScreenState extends State<AvataaarsScreen> {
  final Map<String, String> _config = {
    'topType': 'ShortHairShortFlat',
    'hairColor': 'BrownDark',
    'eyeType': 'Happy',
    'mouthType': 'Smile',
    'clotheType': 'ShirtCrewNeck',
  };

  String buildAvatarUrl() {
    final params = _config.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'https://avataaars.io/?$params&avatarStyle=Transparent';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Avataaars Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text('¿Qué es Avataaars?'),
                  content: Text(
                      'Avataaars son avatares 2D SVG modulares estilo cartoon. Elige peinado, color, expresión y ropa.'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(context, {'type': 'avataaars', 'config': _config});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          SvgPicture.network(
            buildAvatarUrl(),
            width: double.infinity,
            height: 200,
          ),
          DropdownButton<String>(
            value: _config['topType'],
            items: const [
              DropdownMenuItem(
                value: 'ShortHairShortFlat',
                child: Text('ShortHairShortFlat'),
              ),
              DropdownMenuItem(
                value: 'LongHairStraight',
                child: Text('LongHairStraight'),
              ),
            ],
            onChanged: (v) => setState(() => _config['topType'] = v!),
          ),
          DropdownButton<String>(
            value: _config['hairColor'],
            items: const [
              DropdownMenuItem(
                value: 'BrownDark',
                child: Text('BrownDark'),
              ),
              DropdownMenuItem(
                value: 'Blonde',
                child: Text('Blonde'),
              ),
            ],
            onChanged: (v) => setState(() => _config['hairColor'] = v!),
          ),
          DropdownButton<String>(
            value: _config['eyeType'],
            items: const [
              DropdownMenuItem(
                value: 'Happy',
                child: Text('Happy'),
              ),
              DropdownMenuItem(
                value: 'Squint',
                child: Text('Squint'),
              ),
            ],
            onChanged: (v) => setState(() => _config['eyeType'] = v!),
          ),
          DropdownButton<String>(
            value: _config['mouthType'],
            items: const [
              DropdownMenuItem(
                value: 'Smile',
                child: Text('Smile'),
              ),
              DropdownMenuItem(
                value: 'Serious',
                child: Text('Serious'),
              ),
            ],
            onChanged: (v) => setState(() => _config['mouthType'] = v!),
          ),
          DropdownButton<String>(
            value: _config['clotheType'],
            items: const [
              DropdownMenuItem(
                value: 'ShirtCrewNeck',
                child: Text('ShirtCrewNeck'),
              ),
              DropdownMenuItem(
                value: 'BlazerShirt',
                child: Text('BlazerShirt'),
              ),
            ],
            onChanged: (v) => setState(() => _config['clotheType'] = v!),
          ),
        ],
      ),
    );
  }
}
