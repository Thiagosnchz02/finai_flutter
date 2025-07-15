import 'package:avataaars/avataaars.dart';

/// Extensión que expone getters de Avataaar para obtener las propiedades
/// como cadenas legibles por la API de avataaars.
extension AvataaarGetters on Avataaar {
  /// Obtiene el tipo de peinado seleccionado.
  String getTopType() => top.name;

  /// Obtiene el tipo de accesorio seleccionado.
  String getAccessoriesType() => accessories.name;

  /// Obtiene el color de pelo seleccionado.
  String getHairColor() => hairColor.name;

  /// Obtiene el tipo de vello facial seleccionado.
  String getFacialHairType() => facialHair.name;

  /// Obtiene el color del vello facial seleccionado.
  String getFacialHairColor() => facialHairColor.name;

  /// Obtiene el tipo de ojos seleccionado.
  String getEyeType() => eye.name;

  /// Obtiene el tipo de cejas seleccionado.
  String getEyebrowType() => eyebrow.name;

  /// Obtiene el tipo de boca seleccionado.
  String getMouthType() => mouth.name;

  /// Obtiene el color de piel seleccionado.
  String getSkinColor() => skin.name;

  /// Obtiene el tipo de vestimenta seleccionado.
  String getClotheType() => clothe.name;

  /// Obtiene el color de la vestimenta seleccionada.
  String getClotheColor() => clotheColor.name;
}
