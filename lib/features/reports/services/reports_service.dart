// lib/features/reports/services/reports_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ReportsService {
  final _supabase = Supabase.instance.client;

  Future<void> generateReport(Map<String, dynamic> filters) async {

    final response = await _supabase.functions.invoke(
      'generate_filtered_report',
      body: {
        'reportType': 'transactions',
        'filters': filters,
      },
    );

    if (response.status != 200) {
      final errorData = response.data as Map<String, dynamic>?;
      if (errorData?['status'] == 'empty') {
        throw Exception('No se encontraron datos con los filtros seleccionados.');
      }
      throw Exception(errorData?['error'] ?? 'Error desconocido al generar el informe.');
    }
    
    final csvData = response.data as String;

    // --- CORRECCIÓN AQUÍ ---
    // Ya no intentamos leer las cabeceras. En su lugar, construimos el nombre del archivo.
    final reportType = 'transactions';
    final dateString = DateTime.now().toIso8601String().split('T')[0];
    final fileName = 'FinAi_Reporte_${reportType}_$dateString.csv';
    // --- FIN DE LA CORRECCIÓN ---

    final directory = await getDownloadsDirectory();
    if (directory == null) {
      throw Exception('No se pudo acceder a la carpeta de descargas.');
    }
    
    final filePath = '${directory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(csvData);
    
    final openResult = await OpenFilex.open(filePath);
    if (openResult.type != ResultType.done) {
      throw Exception('No se pudo abrir el archivo: ${openResult.message}');
    }
  }
  
  // Métodos para obtener datos para los filtros del formulario
  Future<List<Map<String, dynamic>>> getAccounts() async {
    return List<Map<String, dynamic>>.from(await _supabase.from('accounts').select('id, name').eq('is_archived', false));
  }
  
  Future<List<Map<String, dynamic>>> getCategories() async {
    return List<Map<String, dynamic>>.from(await _supabase.from('categories').select('id, name').eq('is_archived', false));
  }
  
  Future<List<Map<String, dynamic>>> getGoals() async {
    return List<Map<String, dynamic>>.from(await _supabase.from('goals').select('id, name').eq('is_archived', false));
  }
}