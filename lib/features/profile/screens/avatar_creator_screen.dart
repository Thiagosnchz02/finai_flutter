// lib/features/profile/screens/avatar_creator_screen.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avataaars/avataaars.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../../core/localization/localization_strings.dart';

class AvataaarsScreen extends StatefulWidget {
  const AvataaarsScreen({super.key});

  @override
  State<AvataaarsScreen> createState() => _AvataaarsScreenState();
}

class _AvataaarsScreenState extends State<AvataaarsScreen> {
  late Avataaar _avatar;
  final Map<String, String> _config = {
    'topType': 'ShortHairShortFlat',
    'accessoriesType': 'Blank',
    'hairColor': 'BrownDark',
    'facialHairType': 'Blank',
    'facialHairColor': 'BrownDark',
    'eyeType': 'Happy',
    'eyebrowType': 'Default',
    'mouthType': 'Smile',
    'skinColor': 'Light',
    'clotheType': 'ShirtCrewNeck',
    'clotheColor': 'Blue02',
  };

  bool _loadingAvatarSave = false;

  static const Map<String, Color> _hairColors = {
    'Auburn': Color(0xFFA55728),
    'Black': Color(0xFF2C1B18),
    'Blonde': Color(0xFFB58143),
    'BlondeGolden': Color(0xFFD6B370),
    'Brown': Color(0xFF724133),
    'BrownDark': Color(0xFF4A312C),
    'PastelPink': Color(0xFFF59797),
    'Platinum': Color(0xFFE8E1E1),
    'Red': Color(0xFFC93305),
    'SilverGray': Color(0xFFC8C8C8),
  };

  static const Map<String, Color> _clotheColors = {
    'Black': Color(0xFF262E33),
    'Blue01': Color(0xFF65C9FF),
    'Blue02': Color(0xFF5199E4),
    'Blue03': Color(0xFF25557C),
    'Red': Color(0xFFFF5C5C),
    'White': Color(0xFFFFFFFF),
  };

  @override
  void initState() {
    super.initState();
    _avatar = Avataaar.random();
  }

  void _randomizeAvatar() {
    setState(() {
      _avatar = Avataaar.random();
      _config['topType'] = _avatar.top.name;
      _config['accessoriesType'] = _avatar.accessories.name;
      _config['hairColor'] = _avatar.hairColor.name;
      _config['facialHairType'] = _avatar.facialHair.name;
      _config['facialHairColor'] = _avatar.facialHairColor.name;
      _config['eyeType'] = _avatar.eye.name;
      _config['eyebrowType'] = _avatar.eyebrow.name;
      _config['mouthType'] = _avatar.mouth.name;
      _config['skinColor'] = _avatar.skin.name;
      _config['clotheType'] = _avatar.clothe.name;
      _config['clotheColor'] = _avatar.clotheColor.name;
    });
  }

  void _updatePart(String key, String value) {
    setState(() {
      _config[key] = value;
      _avatar = _avatar.copyWith(
        top: key == 'topType' ? Top.values.byName(value) : _avatar.top,
        accessories:
            key == 'accessoriesType' ? Accessories.values.byName(value) : _avatar.accessories,
        hairColor: key == 'hairColor' ? HairColor.values.byName(value) : _avatar.hairColor,
        facialHair: key == 'facialHairType' ? FacialHair.values.byName(value) : _avatar.facialHair,
        facialHairColor:
            key == 'facialHairColor' ? HairColor.values.byName(value) : _avatar.facialHairColor,
        eye: key == 'eyeType' ? Eye.values.byName(value) : _avatar.eye,
        eyebrow: key == 'eyebrowType' ? Eyebrow.values.byName(value) : _avatar.eyebrow,
        mouth: key == 'mouthType' ? Mouth.values.byName(value) : _avatar.mouth,
        skin: key == 'skinColor' ? Skin.values.byName(value) : _avatar.skin,
        clothe: key == 'clotheType' ? Clothe.values.byName(value) : _avatar.clothe,
        clotheColor:
            key == 'clotheColor' ? ClotheColor.values.byName(value) : _avatar.clotheColor,
      );
    });
  }

  double _colorDistance(Color a, Color b) {
    final dr = a.red - b.red;
    final dg = a.green - b.green;
    final db = a.blue - b.blue;
    return math.sqrt((dr * dr + dg * dg + db * db).toDouble());
  }

  String _nearestColorKey(Color color, Map<String, Color> options) {
    String bestKey = options.keys.first;
    double best = double.infinity;
    for (final entry in options.entries) {
      final d = _colorDistance(color, entry.value);
      if (d < best) {
        best = d;
        bestKey = entry.key;
      }
    }
    return bestKey;
  }

  Future<void> _pickColor(String key, Map<String, Color> map) async {
    final current = map[_config[key]!] ?? Colors.black;
    final color = await showColorPickerDialog(
      context,
      current,
      title: const Text('Selecciona un color'),
      showColorCode: false,
      dismissible: true,
    );
    if (!mounted || color == null) return;
    final nearest = _nearestColorKey(color, map);
    _updatePart(key, nearest);
  }


  String buildAvatarUrl() {
    final params = _config.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'https://avataaars.io/?$params&avatarStyle=Circle';
  }

  Future<void> _saveAvatar() async {
    setState(() => _loadingAvatarSave = true);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser!.id;
    await supabase
        .from('profiles')
        .update({'avatar_attributes': _config})
        .eq('id', userId);

    _avatar.toSvg();
    final newUrl = buildAvatarUrl();
    await supabase
        .from('profiles')
        .update({'avatar_url': newUrl})
        .eq('id', userId);

    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      Navigator.of(context).pop(newUrl);
    }
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
          if (_loadingAvatarSave)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CircularProgressIndicator(),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveAvatar,
            ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: SvgPicture.string(
                    _avatar.toSvg(),
                    key: ValueKey(_avatar.toSvg()),
                    width: 160,
                    height: 160,
                    onPictureError: (e, s) => debugPrint('SVG error: $e'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _randomizeAvatar,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Randomizar'),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OptionCard(
              icon: Icons.face_6,
              title: 'Peinado',
              child: DropdownButton<String>(
                value: _config['topType'],
                items: LocalizationStrings.topTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => _updatePart('topType', v!),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.checkroom,
              title: 'Accesorios',
              child: DropdownButton<String>(
                value: _config['accessoriesType'],
                items: LocalizationStrings.accessoriesTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => _updatePart('accessoriesType', v!),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.color_lens,
              title: 'Color de Pelo',
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _hairColors[_config['hairColor']] ?? Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _config['hairColor'],
                      items: LocalizationStrings.hairColorLabels.entries
                          .map(
                            (e) => DropdownMenuItem(
                                value: e.key, child: Text(e.value)),
                          )
                          .toList(),
                      onChanged: (v) => _updatePart('hairColor', v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _pickColor('hairColor', _hairColors),
                    child: const Text('Elegir'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.face_retouching_natural,
              title: 'Vello Facial',
              child: DropdownButton<String>(
                value: _config['facialHairType'],
                items: LocalizationStrings.facialHairTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => _updatePart('facialHairType', v!),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.color_lens_outlined,
              title: 'Color del Vello Facial',
              child: DropdownButton<String>(
                value: _config['facialHairColor'],
                items: LocalizationStrings.facialHairColorLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => _updatePart('facialHairColor', v!),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.remove_red_eye,
              title: 'Ojos',
              child: DropdownButton<String>(
                value: _config['eyeType'],
                items: LocalizationStrings.eyeTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => _updatePart('eyeType', v!),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.filter_b_and_w,
              title: 'Cejas',
              child: DropdownButton<String>(
                value: _config['eyebrowType'],
                items: LocalizationStrings.eyebrowTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => _updatePart('eyebrowType', v!),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.tag_faces,
              title: 'Boca',
              child: DropdownButton<String>(
                value: _config['mouthType'],
                items: LocalizationStrings.mouthTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => _updatePart('mouthType', v!),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.brightness_6,
              title: 'Color de Piel',
              child: DropdownButton<String>(
                value: _config['skinColor'],
                items: LocalizationStrings.skinColorLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => _updatePart('skinColor', v!),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.checkroom_outlined,
              title: 'Ropa',
              child: DropdownButton<String>(
                value: _config['clotheType'],
                items: LocalizationStrings.clotheTypeLabels.entries
                    .map(
                      (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                    )
                    .toList(),
                onChanged: (v) => _updatePart('clotheType', v!),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: Icons.palette,
              title: 'Color de Ropa',
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _clotheColors[_config['clotheColor']] ?? Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _config['clotheColor'],
                      items: LocalizationStrings.clotheColorLabels.entries
                          .map(
                            (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                          )
                          .toList(),
                      onChanged: (v) => _updatePart('clotheColor', v!),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => _pickColor('clotheColor', _clotheColors),
                    child: const Text('Elegir'),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: SvgPicture.string(
                _avatar.toSvg(),
                key: ValueKey('preview_${_avatar.toSvg()}'),
                width: 160,
                height: 160,
                onPictureError: (e, s) => debugPrint('SVG error: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

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
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
