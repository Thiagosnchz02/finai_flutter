import 'package:flutter/material.dart';

import '../services/report_service.dart';
import '../widgets/date_filter_dialog.dart';
import '../widgets/template_list_item.dart';
import 'analysis_viewer_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final ReportService _reportService = ReportService();

  // DESPUÉS (Versión Corregida para INFORMES)
  final List<_TemplateDefinition> _reportTemplates = const [
    _TemplateDefinition(
      templateName: 'flujo_caja',
      title: 'Resumen Mensual de Flujo de Caja',
      subtitle: 'Ingresos, gastos y ahorro neto del mes.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _TemplateDefinition(
      templateName: 'desglose_gastos_categoria',
      title: 'Desglose de Gastos por Categoría',
      subtitle: 'Un gráfico y tabla de en qué gastaste tu dinero.',
      icon: Icons.pie_chart_outline,
    ),
    _TemplateDefinition(
      templateName: 'informe_anual_consolidado',
      title: 'Informe Anual Consolidado',
      subtitle: 'Visión general de tus finanzas durante todo el año.',
      icon: Icons.calendar_today_outlined,
    ),
    _TemplateDefinition(
      templateName: 'estados_presupuestos',
      title: 'Estado de Presupuestos',
      subtitle: 'Compara tus gastos con los límites que te propusiste.',
      icon: Icons.check_circle_outline,
    ),
    _TemplateDefinition(
      templateName: 'progreso_metas',
      title: 'Progreso de Metas (Huchas)',
      subtitle: 'Revisa el avance de todos tus objetivos de ahorro.',
      icon: Icons.savings_outlined,
    ),
    _TemplateDefinition(
      templateName: 'informe_cuenta_especifica',
      title: 'Extracto de una Cuenta',
      subtitle: 'Todos los movimientos de una cuenta específica.',
      icon: Icons.receipt_long_outlined,
    ),
    _TemplateDefinition(
      templateName: 'listado_gastos_fijos',
      title: 'Listado de Gastos Fijos',
      subtitle: 'Consulta tus próximos pagos recurrentes.',
      icon: Icons.event_repeat_outlined,
    ),
    _TemplateDefinition(
      templateName: 'informe_impuestos',
      title: 'Informe de Impuestos (Simplificado)',
      subtitle: 'Resumen anual de ingresos y gastos deducibles.',
      icon: Icons.calculate_outlined,
    ),
  ];

  final List<_TemplateDefinition> _analysisTemplates = const [
    _TemplateDefinition(
      templateName: 'distribucion_gastos',
      title: 'Distribución de Gastos',
      subtitle: 'Observa cómo se reparten tus gastos en un gráfico.',
      icon: Icons.donut_large_outlined,
    ),
    _TemplateDefinition(
      templateName: 'comparativa_ingresos_vs_gastos',
      title: 'Ingresos vs. Gastos',
      subtitle: 'Compara tu flujo de caja de los últimos 6 meses.',
      icon: Icons.bar_chart,
    ),
    _TemplateDefinition(
      templateName: 'evolucion_patrimonio_neto',
      title: 'Evolución del Patrimonio Neto',
      subtitle: 'Sigue el crecimiento de tus ahorros e inversiones.',
      icon: Icons.show_chart,
    ),
    _TemplateDefinition(
      templateName: 'tendencia_gasto_categoria',
      title: 'Tendencia de Gasto por Categoría',
      subtitle: 'Analiza cómo varía un gasto a lo largo del año.',
      icon: Icons.timeline,
    ),
    _TemplateDefinition(
      templateName: 'analisis_flujo_caja',
      title: 'Calendario de Flujo de Caja',
      subtitle: 'Identifica los días del mes con más actividad.',
      icon: Icons.grid_on_outlined,
    ),
    _TemplateDefinition(
      templateName: 'proyeccion_metas',
      title: 'Proyección de Metas',
      subtitle: 'Estima cuándo alcanzarás tus objetivos de ahorro.',
      icon: Icons.flag_outlined,
    ),
    _TemplateDefinition(
      templateName: 'analisis_frecuencia_gastos',
      title: 'Gastos por Día de la Semana',
      subtitle: 'Descubre en qué días de la semana gastas más.',
      icon: Icons.view_week_outlined,
    ),
    _TemplateDefinition(
      templateName: 'comparativa_ahorro_vs_objetivo',
      title: 'Ahorro vs. Objetivo Mensual',
      subtitle: 'Mide tu ritmo de ahorro comparado con tu meta.',
      icon: Icons.speed_outlined,
    ),
  ];

  Future<void> _handleReportTap(_TemplateDefinition template) async {
    final filters = await DateFilterDialog.show(context);
    if (!mounted || filters == null) return;

    _showLoadingDialog();

    try {
      final data = await _reportService.getTemplateData(
        template.templateName,
        filters,
      );
      await _reportService.downloadPdfFromMicroservice(
        template.templateName,
        data,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reporte exportado correctamente.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ocurrió un error: $error')),
      );
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _showLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _handleAnalysisTap(_TemplateDefinition template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisViewerScreen(
          templateName: template.templateName,
          title: template.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Informes'),
              Tab(text: 'Análisis'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TemplateListView(
              templates: _reportTemplates,
              onItemTap: _handleReportTap,
            ),
            _TemplateListView(
              templates: _analysisTemplates,
              onItemTap: _handleAnalysisTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateListView extends StatelessWidget {
  const _TemplateListView({
    required this.templates,
    required this.onItemTap,
  });

  final List<_TemplateDefinition> templates;
  final void Function(_TemplateDefinition template) onItemTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return TemplateListItem(
          title: template.title,
          subtitle: template.subtitle,
          icon: template.icon,
          onTap: () => onItemTap(template),
        );
      },
    );
  }
}

class _TemplateDefinition {
  const _TemplateDefinition({
    required this.templateName,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String templateName;
  final String title;
  final String subtitle;
  final IconData icon;
}
