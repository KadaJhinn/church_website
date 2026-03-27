import 'package:flutter/material.dart';
import 'sidebar_icons.dart';
import 'home_dashboard.dart';
import 'events_hub.dart';
import 'event_planner.dart';
import 'landing_page.dart';
import 'settings_page.dart';

class WireframeLayout extends StatefulWidget {
  const WireframeLayout({super.key});

  @override
  State<WireframeLayout> createState() => _WireframeLayoutState();
}

class _WireframeLayoutState extends State<WireframeLayout> {
  int selectedIndex = 0;

  List<Widget> get pages => [
        const HomeDashboard(),
        const EventHub(),
        const EventPlanner(),
        LandingPage(
          embeddedInDashboard: true,
          onBackToDashboard: () {
            setState(() {
              selectedIndex = 0;
            });
          },
        ),
        const SettingsPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          //  Sidebar
          SidebarIcons(
            selectedIndex: selectedIndex,
            onSelect: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),

          // Page content
          Expanded(
            child: pages[selectedIndex],
          ),
        ],
      ),
    );
  }
}
