// lib/features/goals/widgets/contribution_history_dialog.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:finai_flutter/features/goals/services/goals_service.dart';

class ContributionHistoryDialog extends StatefulWidget {
  final String goalId;
  final String goalName;

  const ContributionHistoryDialog({
    super.key,
    required this.goalId,
    required this.goalName,
  });

  @override
  State<ContributionHistoryDialog> createState() => _ContributionHistoryDialogState();
}

class _ContributionHistoryDialogState extends State<ContributionHistoryDialog> {
  final _service = GoalsService();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _service.getContributionHistory(widget.goalId);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Historial de "${widget.goalName}"'),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar el historial.'));
            }
            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return const Center(child: Text('No hay aportaciones todavía.'));
            }

            return ListView.builder(
              shrinkWrap: true,
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final date = DateTime.parse(item['created_at']);
                final amount = (item['amount'] as num).toDouble();
                final notes = item['notes'] as String?;
                final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');

                return ListTile(
                  title: Text('+ ${formatter.format(amount)}'),
                  subtitle: Text(DateFormat.yMMMd('es_ES').add_Hms().format(date)),
                  trailing: notes != null && notes.isNotEmpty ? const Icon(Icons.comment) : null,
                  onTap: notes != null && notes.isNotEmpty
                      ? () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Nota de la Aportación'),
                              content: Text(notes),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cerrar'),
                                ),
                              ],
                            ),
                          );
                        }
                      : null,
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cerrar'),
        )
      ],
    );
  }
}