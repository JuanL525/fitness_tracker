import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/glass_bottom_nav.dart';
import '../../../activity_history/presentation/pages/activity_history_page.dart';
import '../../../tracking/presentation/widgets/route_map_widget.dart';
import 'fitness_dashboard_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  late final _historyPage = ActivityHistoryPage(
    getAllSessions: getIt(),
    deleteSession: getIt(),
    updateSession: getIt(),
    embedded: true,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: [
          const FitnessDashboardPage(),
          const RouteMapWidget(),
          _historyPage,
        ],
      ),
      bottomNavigationBar: GlassBottomNav(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
