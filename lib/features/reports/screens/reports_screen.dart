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

  final List<_TemplateDefinition> _reportTemplates = const [
    _TemplateDefinition(
      templateName: 'monthly_summary',
      title: 'Resumen mensual',
      subtitle: 'Recibe un PDF con el resumen de tus finanzas del mes.',
      icon: Icons.description_outlined,
    ),
    _TemplateDefinition(
      templateName: 'cash_flow_statement',
      title: 'Flujo de caja',
      subtitle: 'Visualiza ingresos y egresos detallados.',
      icon: Icons.account_balance_wallet_outlined,
    ),
    _TemplateDefinition(
      templateName: 'expense_breakdown',
      title: 'Desglose de gastos',
      subtitle: 'Analiza tus gastos por categoría.',
      icon: Icons.pie_chart_outline,
    ),
    _TemplateDefinition(
      templateName: 'income_report',
      title: 'Informe de ingresos',
      subtitle: 'Evalúa tus fuentes de ingresos.',
      icon: Icons.attach_money,
    ),
    _TemplateDefinition(
      templateName: 'budget_vs_actual',
      title: 'Presupuesto vs Real',
      subtitle: 'Compara lo planificado con la realidad.',
      icon: Icons.compare_arrows,
    ),
    _TemplateDefinition(
      templateName: 'savings_progress',
      title: 'Progreso de ahorro',
      subtitle: 'Revisa el avance de tus metas de ahorro.',
      icon: Icons.savings_outlined,
    ),
    _TemplateDefinition(
      templateName: 'debt_overview',
      title: 'Resumen de deudas',
      subtitle: 'Mantén control sobre tus obligaciones.',
      icon: Icons.receipt_long_outlined,
    ),
    _TemplateDefinition(
      templateName: 'investment_snapshot',
      title: 'Instantánea de inversiones',
      subtitle: 'Consulta el estado de tus inversiones.',
      icon: Icons.trending_up,
    ),
  ];

  final List<_TemplateDefinition> _analysisTemplates = const [
    _TemplateDefinition(
      templateName: 'category_distribution',
      title: 'Distribución por categoría',
      subtitle: 'Observa cómo se reparten tus gastos.',
      icon: Icons.donut_large_outlined,
    ),
    _TemplateDefinition(
      templateName: 'income_expense_comparison',
      title: 'Ingresos vs Egresos',
      subtitle: 'Compara tu flujo mensual.',
      icon: Icons.bar_chart,
    ),
    _TemplateDefinition(
      templateName: 'net_worth_trend',
      title: 'Evolución del patrimonio',
      subtitle: 'Sigue tu patrimonio neto a lo largo del tiempo.',
      icon: Icons.show_chart,
    ),
    _TemplateDefinition(
      templateName: 'category_trend',
      title: 'Tendencia por categoría',
      subtitle: 'Analiza las variaciones por categoría.',
      icon: Icons.timeline,
    ),
    _TemplateDefinition(
      templateName: 'cash_flow_heatmap',
      title: 'Heatmap de flujo de caja',
      subtitle: 'Identifica meses con más actividad.',
      icon: Icons.grid_view,
    ),
    _TemplateDefinition(
      templateName: 'goal_projection',
      title: 'Proyección de metas',
      subtitle: 'Visualiza el avance estimado de tus metas.',
      icon: Icons.flag_outlined,
    ),
    _TemplateDefinition(
      templateName: 'weekday_spending',
      title: 'Gastos por día de la semana',
      subtitle: 'Descubre en qué días gastas más.',
      icon: Icons.calendar_today_outlined,
    ),
    _TemplateDefinition(
      templateName: 'savings_gauge',
      title: 'Indicador de ahorro',
      subtitle: 'Mide tu nivel de ahorro actual.',
      icon: Icons.speed,
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
