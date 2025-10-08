import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportService {
  ReportService();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> getTemplateData(
    String templateName,
    Map<String, dynamic> options,
  ) async {
    final response = await _supabase.rpc(
      'get_basic_template_data',
      params: {
        'template_name': templateName,
        'options': options,
      },
    );

    if (response is Map<String, dynamic>) {
      return Map<String, dynamic>.from(response);
    }

    throw Exception('Formato inesperado recibido para la plantilla $templateName');
  }

  Future<void> downloadPdfFromMicroservice(
    String templateName,
    Map<String, dynamic> reportData,
  ) async {
    final String? baseUrl = dotenv.env['REPORTS_PDF_MICROSERVICE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      throw Exception('No se ha configurado REPORTS_PDF_MICROSERVICE_URL en el archivo .env');
    }

    final session = _supabase.auth.currentSession;
    final token = session?.accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('No se pudo obtener el token de autenticación de Supabase');
    }

    final Uri uri = Uri.parse(baseUrl);
    final response = await http.post(
      uri,
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: 'application/json',
      },
      body: jsonEncode({
        'templateName': templateName,
        'data': reportData,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'No se pudo generar el PDF: ${response.statusCode} - ${response.body}',
      );
    }

    final bytes = response.bodyBytes;
    if (bytes.isEmpty) {
      throw Exception('El microservicio devolvió un PDF vacío');
    }

    final directory = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final sanitizedTemplate = templateName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filePath = '${directory.path}/FinAi_${sanitizedTemplate}_$timestamp.pdf';

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    if (!kIsWeb) {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception('El archivo se guardó pero no pudo abrirse: ${result.message}');
      }
    }
  }
}
