// lib/features/profile/screens/avatar_creator_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Mapas de etiquetas en español para las opciones de Avataaars
const Map<String, String> topTypeLabels = {
  'NoHair': 'Calvo',
  'Eyepatch': 'Parche en el ojo',
  'Hat': 'Sombrero',
  'Hijab': 'Hiyab',
  'Turban': 'Turbante',
  'WinterHat1': 'Gorro de invierno 1',
  'WinterHat2': 'Gorro de invierno 2',
  'WinterHat3': 'Gorro de invierno 3',
  'WinterHat4': 'Gorro de invierno 4',
  'LongHairBigHair': 'Pelo largo abundante',
  'LongHairBob': 'Melena',
  'LongHairBun': 'Moño',
  'LongHairCurly': 'Pelo largo rizado',
  'LongHairCurvy': 'Pelo largo ondulado',
  'LongHairDreads': 'Rastas largas',
  'LongHairFrida': 'Estilo Frida',
  'LongHairFro': 'Afro largo',
  'LongHairFroBand': 'Afro largo con banda',
  'LongHairNotTooLong': 'Pelo medio',
  'LongHairShavedSides': 'Lado rapado',
  'LongHairMiaWallace': 'Estilo Mia Wallace',
  'LongHairStraight': 'Pelo largo liso',
  'LongHairStraight2': 'Pelo largo liso 2',
  'LongHairStraightStrand': 'Pelo largo con mechón',
  'ShortHairDreads01': 'Rastas cortas 1',
  'ShortHairDreads02': 'Rastas cortas 2',
  'ShortHairFrizzle': 'Pelo muy rizado',
  'ShortHairShaggyMullet': 'Mullet desordenado',
  'ShortHairShortCurly': 'Pelo corto rizado',
  'ShortHairShortFlat': 'Pelo corto plano',
  'ShortHairShortRound': 'Pelo corto redondo',
  'ShortHairShortWaved': 'Pelo corto ondulado',
  'ShortHairSides': 'Lados cortos',
  'ShortHairTheCaesar': 'Corte César',
  'ShortHairTheCaesarSidePart': 'César con raya',
};

const Map<String, String> hairColorLabels = {
  'Auburn': 'Castaño rojizo',
  'Black': 'Negro',
  'Blonde': 'Rubio',
  'BlondeGolden': 'Rubio dorado',
  'Brown': 'Marrón',
  'BrownDark': 'Marrón oscuro',
  'PastelPink': 'Rosa pastel',
  'Platinum': 'Platino',
  'Red': 'Rojo',
  'SilverGray': 'Gris plateado',
};

const Map<String, String> hatTypeLabels = {
  'Blank': 'Sin accesorios',
  'Kurt': 'Gafas estilo Kurt',
  'Prescription01': 'Gafas graduadas 1',
  'Prescription02': 'Gafas graduadas 2',
  'Round': 'Gafas redondas',
  'Sunglasses': 'Gafas de sol',
  'Wayfarers': 'Gafas wayfarer',
};

const Map<String, String> facialHairTypeLabels = {
  'Blank': 'Ninguno',
  'BeardMedium': 'Barba media',
  'BeardLight': 'Barba ligera',
  'BeardMajestic': 'Barba majestuosa',
  'MoustacheFancy': 'Bigote elegante',
  'MoustacheMagnum': 'Bigote magnum',
};

// Reutilizamos los mismos colores de cabello para el vello facial
const Map<String, String> facialHairColorLabels = hairColorLabels;

const Map<String, String> eyeTypeLabels = {
  'Close': 'Cerrados',
  'Cry': 'Llorando',
  'Default': 'Normal',
  'Dizzy': 'Mareado',
  'EyeRoll': 'Ojos en blanco',
  'Happy': 'Feliz',
  'Hearts': 'Enamorado',
  'Side': 'De lado',
  'Squint': 'Entrecerrados',
  'Surprised': 'Sorprendido',
  'Wink': 'Guiño',
  'WinkWacky': 'Guiño alocado',
};

const Map<String, String> eyebrowTypeLabels = {
  'Angry': 'Enfadadas',
  'AngryNatural': 'Enfadadas natural',
  'Default': 'Normales',
  'DefaultNatural': 'Normales natural',
  'FlatNatural': 'Planas natural',
  'RaisedExcited': 'Levantadas',
  'RaisedExcitedNatural': 'Levantadas natural',
  'SadConcerned': 'Tristes',
  'SadConcernedNatural': 'Tristes natural',
  'UnibrowNatural': 'Uniceja',
  'UpDown': 'Arriba-Abajo',
  'UpDownNatural': 'Arriba-Abajo natural',
};

const Map<String, String> mouthTypeLabels = {
  'Concerned': 'Preocupado',
  'Default': 'Normal',
  'Disbelief': 'Incrédulo',
  'Eating': 'Comiendo',
  'Grimace': 'Mueca',
  'Sad': 'Triste',
  'ScreamOpen': 'Gritando',
  'Serious': 'Serio',
  'Smile': 'Sonriendo',
  'Tongue': 'Sacando la lengua',
  'Twinkle': 'Brillando',
  'Vomit': 'Vómito',
};

const Map<String, String> clotheTypeLabels = {
  'BlazerShirt': 'Blazer con camisa',
  'BlazerSweater': 'Blazer con suéter',
  'CollarSweater': 'Suéter con cuello',
  'GraphicShirt': 'Camiseta gráfica',
  'Hoodie': 'Sudadera',
  'Overall': 'Overol',
  'ShirtCrewNeck': 'Camiseta cuello redondo',
  'ShirtScoopNeck': 'Camiseta cuello amplio',
  'ShirtVNeck': 'Camiseta cuello V',
};

const Map<String, String> skinColorLabels = {
  'Tanned': 'Bronceado',
  'Yellow': 'Amarillo',
  'Pale': 'Pálido',
  'Light': 'Claro',
  'Brown': 'Marrón',
  'DarkBrown': 'Marrón oscuro',
  'Black': 'Negro',
};

class AvataaarsScreen extends StatefulWidget {
  const AvataaarsScreen({super.key});

  @override
  State<AvataaarsScreen> createState() => _AvataaarsScreenState();
}

class _AvataaarsScreenState extends State<AvataaarsScreen> {
  final Map<String, String> _config = {
    'topType': 'ShortHairShortFlat',
    'hatType': 'Blank',
    'hairColor': 'BrownDark',
    'facialHairType': 'Blank',
    'facialHairColor': 'BrownDark',
    'eyeType': 'Happy',
    'eyebrowType': 'Default',
    'mouthType': 'Smile',
    'skinColor': 'Light',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: SvgPicture.network(
                buildAvatarUrl(),
                width: double.infinity,
                height: 200,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Peinado'),
            DropdownButton<String>(
              value: _config['topType'],
              items: topTypeLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['topType'] = v!),
            ),
            const Divider(),
            const Text('Accesorios'),
            DropdownButton<String>(
              value: _config['hatType'],
              items: hatTypeLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['hatType'] = v!),
            ),
            const Divider(),
            const Text('Color de Pelo'),
            DropdownButton<String>(
              value: _config['hairColor'],
              items: hairColorLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['hairColor'] = v!),
            ),
            const Divider(),
            const Text('Vello Facial'),
            DropdownButton<String>(
              value: _config['facialHairType'],
              items: facialHairTypeLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['facialHairType'] = v!),
            ),
            const Divider(),
            const Text('Color del Vello Facial'),
            DropdownButton<String>(
              value: _config['facialHairColor'],
              items: facialHairColorLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['facialHairColor'] = v!),
            ),
            const Divider(),
            const Text('Ojos'),
            DropdownButton<String>(
              value: _config['eyeType'],
              items: eyeTypeLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['eyeType'] = v!),
            ),
            const Divider(),
            const Text('Cejas'),
            DropdownButton<String>(
              value: _config['eyebrowType'],
              items: eyebrowTypeLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['eyebrowType'] = v!),
            ),
            const Divider(),
            const Text('Boca'),
            DropdownButton<String>(
              value: _config['mouthType'],
              items: mouthTypeLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['mouthType'] = v!),
            ),
            const Divider(),
            const Text('Color de Piel'),
            DropdownButton<String>(
              value: _config['skinColor'],
              items: skinColorLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['skinColor'] = v!),
            ),
            const Divider(),
            const Text('Ropa'),
            DropdownButton<String>(
              value: _config['clotheType'],
              items: clotheTypeLabels.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _config['clotheType'] = v!),
            ),
          ],
        ),
      ),
    );
  }
}
