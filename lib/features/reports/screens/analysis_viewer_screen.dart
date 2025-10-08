import 'package:flutter/material.dart';

import '../services/report_service.dart';
import '../widgets/charts/cash_flow_heatmap.dart';
import '../widgets/charts/category_distribution_chart.dart';
import '../widgets/charts/category_trend_line_chart.dart';
import '../widgets/charts/goal_projection_view.dart';
import '../widgets/charts/income_expense_bar_chart.dart';
import '../widgets/charts/net_worth_line_chart.dart';
import '../widgets/charts/savings_gauge_chart.dart';
import '../widgets/charts/weekday_spending_bar_chart.dart';

class AnalysisViewerScreen extends StatefulWidget {
  const AnalysisViewerScreen({
    super.key,
    required this.templateName,
    required this.title,
  });

  final String templateName;
  final String title;

  @override
  State<AnalysisViewerScreen> createState() => _AnalysisViewerScreenState();
}

class _AnalysisViewerScreenState extends State<AnalysisViewerScreen> {
  final ReportService _reportService = ReportService();
  late Future<Map<String, dynamic>> _dataFuture;
  Map<String, dynamic>? _reportData;

  @override
  void initState() {
    super.initState();
    _dataFuture = _reportService.getTemplateData(
      widget.templateName,
      const {},
    );
  }

  Future<void> _exportToPdf() async {
    if (_reportData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los datos aún no están disponibles.')),
      );
      return;
    }

    try {
      await _reportService.downloadPdfFromMicroservice(
        widget.templateName,
        _reportData!,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Análisis exportado a PDF.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar el PDF: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exportar a PDF',
            onPressed: _exportToPdf,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Ocurrió un error al cargar los datos: ${snapshot.error}'),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: Text('No se encontraron datos para mostrar.'));
          }
          _reportData = data;

          switch (widget.templateName) {
            case 'category_distribution':
              return CategoryDistributionChart(data: data);
            case 'income_expense_comparison':
              return IncomeExpenseBarChart(data: data);
            case 'net_worth_trend':
              return NetWorthLineChart(data: data);
            case 'category_trend':
              return CategoryTrendLineChart(data: data);
            case 'cash_flow_heatmap':
              return CashFlowHeatmap(data: data);
            case 'goal_projection':
              return GoalProjectionView(data: data);
            case 'weekday_spending':
              return WeekdaySpendingBarChart(data: data);
            case 'savings_gauge':
              return SavingsGaugeChart(data: data);
            default:
              return _UnknownTemplateView(templateName: widget.templateName);
          }
        },
      ),
    );
  }
}

class _UnknownTemplateView extends StatelessWidget {
  const _UnknownTemplateView({
    required this.templateName,
  });

  final String templateName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Plantilla "$templateName" no soportada todavía.'),
    );
  }
}
