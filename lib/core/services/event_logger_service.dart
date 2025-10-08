// lib/core/services/event_logger_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../events/app_events.dart';

class EventLoggerService {
  final _supabase = Supabase.instance.client;

  /// Registra un evento en la tabla `user_events`.
  ///
  /// [event]: El tipo de evento, definido en el enum `AppEvent`.
  /// [details]: Un mapa opcional con metadatos relevantes para el evento.
  Future<void> log(AppEvent event, {Map<String, dynamic>? details}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        // No podemos registrar un evento si no hay un usuario logueado.
        return;
      }

      await _supabase.from('user_events').insert({
        'user_id': user.id,
        'event_type': event.name, // .name convierte el enum a su nombre en String
        'payload': details, // Puede ser nulo si no se proporcionan detalles
      });

    } catch (e) {
      // En un entorno de producción, podríamos querer manejar este error
      // de una forma más robusta (ej: registrarlo en un servicio de logging de errores),
      // pero por ahora, simplemente lo imprimimos en la consola para no interrumpir
      // el flujo del usuario si el registro de eventos falla.
    }
  }
}