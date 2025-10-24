// lib/features/goals/widgets/goal_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../models/goal_model.dart';

class GoalStyle {
  final IconData icon;
  final Color iconColor;
  final Color titleColor;
  final Color subtitleColor;
  final Gradient backgroundGradient;
  final Gradient progressGradient;
  final String pigAsset;
  final Color borderColor;

  const GoalStyle({
    required this.icon,
    required this.iconColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.backgroundGradient,
    required this.progressGradient,
    required this.pigAsset,
    required this.borderColor,
  });
}

GoalStyle paletteFor(Goal goal) {
  final type = goal.type.toLowerCase();

  if (type.contains('viaje')) {
    return const GoalStyle(
      icon: Icons.airplanemode_active,
      iconColor: Color(0xFF875CF6),
      titleColor: Colors.white,
      subtitleColor: Color(0xFFE0D9FF),
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF2971FF), Color(0xFF875CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      progressGradient: LinearGradient(
        colors: [Color(0xFF3E8BFF), Color(0xFF9F7BFF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      pigAsset: 'assets/icons/piggy_purple.svg',
      borderColor: Color(0xFF875CF6),
    );
  }

  if (type.contains('ahorro')) {
    return const GoalStyle(
      icon: Icons.savings_rounded,
      iconColor: Color(0xFF2971FF),
      titleColor: Colors.white,
      subtitleColor: Color(0xFFD1E2FF),
      backgroundGradient: LinearGradient(
        colors: [Color(0xFF875CF6), Color(0xFF040404)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      progressGradient: LinearGradient(
        colors: [Color(0xFF2971FF), Color(0xFF0A2A66)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      pigAsset: 'assets/icons/piggy_blue.svg',
      borderColor: Color(0xFF2971FF),
    );
  }

  return const GoalStyle(
    icon: Icons.flag_rounded,
    iconColor: Color(0xFFFF0088),
    titleColor: Colors.white,
    subtitleColor: Color(0xFFFFC2E1),
    backgroundGradient: LinearGradient(
      colors: [Color(0xFFFF4FA6), Color(0xFFFF0088)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    progressGradient: LinearGradient(
      colors: [Color(0xFFFF71B5), Color(0xFFB30061)],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ),
    pigAsset: 'assets/icons/piggy_pink.svg',
    borderColor: Color(0xFFFF0088),
  );
}

class GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onContribute;
  final VoidCallback onAddExpense;
  final VoidCallback onArchive;
  final VoidCallback onViewHistory;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onContribute,
    required this.onAddExpense,
    required this.onArchive,
    required this.onViewHistory,
  });

  @override
  Widget build(BuildContext context) {
    final style = paletteFor(goal);
    final isCompleted = goal.progress >= 1.0;
    const completedGreen = Color(0xFF00FF00);
    final backgroundGradient = isCompleted
        ? const LinearGradient(
            colors: [Color(0xFF00FF00), Color(0xFF22C55E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : style.backgroundGradient;
    final progressGradient = isCompleted
        ? const LinearGradient(
            colors: [Color(0xFF00FF00), Color(0xFF22C55E)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : style.progressGradient;
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    final progress = goal.progress.clamp(0.0, 1.0).toDouble();
    final goalType = goal.type.toLowerCase();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(24),
        border: isCompleted
            ? Border.all(color: completedGreen, width: 1.5)
            : Border.all(
                color: style.borderColor.withOpacity(0.35),
                width: 1.5,
              ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 25),
            blurRadius: 50,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(style.icon, color: style.iconColor, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          goal.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: style.titleColor,
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: onViewHistory,
                      icon: const Icon(Icons.description_outlined),
                      color: style.subtitleColor,
                      tooltip: 'Ver historial',
                    ),
                    IconButton(
                      onPressed: onArchive,
                      icon: const Icon(Icons.archive_outlined),
                      color: style.subtitleColor,
                      tooltip: 'Archivar meta',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              goal.type,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: style.iconColor,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (goal.targetDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Hasta ${DateFormat.yMMMMd('es_ES').format(goal.targetDate!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: style.subtitleColor,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final barHeight = 14.0;
                final pigSize = 48.0;
                final availableWidth = (constraints.maxWidth - pigSize).clamp(0.0, double.infinity);
                final pigLeft = (availableWidth * progress).clamp(0.0, availableWidth);

                return SizedBox(
                  height: pigSize * 0.85,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(barHeight),
                        ),
                      ),
                      AnimatedFractionallySizedBox(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          height: barHeight,
                          decoration: BoxDecoration(
                            gradient: progressGradient,
                            borderRadius: BorderRadius.circular(barHeight),
                          ),
                        ),
                      ),
                      Positioned(
                        left: pigLeft,
                        top: -(pigSize / 2 - barHeight / 2),
                        child: Container(
                          width: pigSize,
                          height: pigSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: (isCompleted ? completedGreen : style.iconColor)
                                  .withOpacity(0.2),
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 22,
                                  child: SvgPicture.asset(
                                    style.pigAsset,
                                    colorFilter: ColorFilter.mode(
                                      isCompleted ? completedGreen : style.iconColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color:
                                            isCompleted ? completedGreen : style.iconColor,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: formatter.format(goal.currentAmount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: isCompleted ? completedGreen : Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        TextSpan(
                          text: ' / ',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: style.subtitleColor,
                              ),
                        ),
                        TextSpan(
                          text: formatter.format(goal.targetAmount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isCompleted) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0x3322C55E),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '¡Meta conseguida!',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: completedGreen,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (goalType.contains('viaje'))
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onAddExpense,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: style.titleColor,
                        side: BorderSide(color: style.subtitleColor.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: const Text('Añadir gasto'),
                    ),
                  ),
                if (goalType.contains('viaje')) const SizedBox(width: 12),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: progressGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: FilledButton(
                      onPressed: isCompleted ? null : onContribute,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor:
                            isCompleted ? const Color(0x3300FF00) : Colors.white24,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Aportar',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}