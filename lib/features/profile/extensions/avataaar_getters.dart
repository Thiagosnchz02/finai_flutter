import 'package:avataaars/avataaars.dart';

/// Extensión que expone getters de Avataaar para obtener las propiedades
/// como cadenas legibles por la API de avataaars.
extension AvataaarGetters on Avataaar {
  /// Obtiene el tipo de peinado seleccionado.
  String getTopType() => top.topType.name;

  /// Obtiene el tipo de accesorio seleccionado.
  String getAccessoriesType() => top.accessoriesType.name;

  /// Obtiene el color de pelo seleccionado.
  String getHairColor() => hairColor.name;

  /// Obtiene el tipo de vello facial seleccionado.
  String getFacialHairType() => facialHairType.name;

  /// Obtiene el color del vello facial seleccionado.
  String getFacialHairColor() => facialHairColor.name;

  /// Obtiene el tipo de ojos seleccionado.
  String getEyeType() => eyeType.name;

  /// Obtiene el tipo de cejas seleccionado.
  String getEyebrowType() => eyebrowType.name;

  /// Obtiene el tipo de boca seleccionado.
  String getMouthType() => mouthType.name;

  /// Obtiene el color de piel seleccionado.
  String getSkinColor() => skinColor.name;

  /// Obtiene el tipo de vestimenta seleccionado.
  String getClotheType() => clotheType.name;

  /// Obtiene el color de la vestimenta seleccionada.
  String getClotheColor() => clotheColor.name;
}
