// lib/features/categories/widgets/custom_tab_bar.dart

import 'package:flutter/material.dart';
import 'dart:ui';

class CustomTabBar extends StatelessWidget {
  final TabController tabController;
  final List<String> tabs;

  const CustomTabBar({
    super.key,
    required this.tabController,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TabBar(
            controller: tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              color: const Color(0xFF5A67D8), // Color primario del tema
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: tabs.map((tab) => Tab(text: tab)).toList(),
          ),
        ),
      ),
    );
  }
}