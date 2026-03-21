import 'package:flutter/material.dart';
import 'event_model.dart';
import 'event_manager.dart';
import 'event_panel_card.dart';
import 'event_planner.dart';
import 'monthly_lineup_calendar.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  // Generate analytics counts
  Map<String, int> getAnalytics() {
    Map<String, int> data = {
      "Rooftop": 0,
      "Men": 0,
      "Women": 0,
    };

    for (var event in EventManager.events) {
      data[event.network] = (data[event.network] ?? 0) + 1;
    }

    return data;
  }

  // Delete an event
  void deleteEvent(EventModel event) {
    setState(() {
      EventManager.deleteEvent(event);
    });
  }

  // Edit an event
  void editEvent(EventModel event) async {
    try {
      final updatedEvent = await Navigator.push<EventModel>(
        context,
        MaterialPageRoute(
          builder: (_) => EventPlanner(editEvent: event),
        ),
      );

      if (updatedEvent != null && mounted) {
        EventManager.updateEvent(event, updatedEvent); // update explicitly
        setState(() {}); // refresh dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.teal,
            content: Text("Event Updated: ${updatedEvent.title}", style: const TextStyle(fontSize: 16)),
          ),
        );
      }
    } catch (e, stack) {
      print("Error editing event: $e\n$stack");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to edit event"), backgroundColor: Colors.red),
      );
    }
  }

  // Show latest announcement as SnackBar
  void showAnnouncementSnackBar() {
    if (EventManager.events.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No events available")),
      );
      return;
    }

    final latestEvent = EventManager.events.last;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.teal,
        content: Text(
          "Upcoming Event: ${latestEvent.title} • ${latestEvent.time}",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final analytics = getAnalytics();

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Home", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),

            // Event Announcement
            GestureDetector(
              onTap: showAnnouncementSnackBar,
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.campaign, color: Colors.teal),
                    SizedBox(width: 10),
                    Text("Event Announcement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Analytics bars
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: analytics.entries.map((entry) {
                final color = _getNetworkColor(entry.key);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${entry.key} • Total Events: ${entry.value}",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: (entry.value / 10).clamp(0.0, 1.0),
                        color: color,
                        backgroundColor: color.withOpacity(0.2),
                        minHeight: 10,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 30),
            const Text("Events", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Event lists by network
            _buildNetworkEvents("Rooftop"),
            _buildNetworkEvents("Men"),
            _buildNetworkEvents("Women"),

            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MonthlyLineupCalendar()),
                );
              },
              child: const Text("View Monthly Lineup"),
            ),
          ],
        ),
      ),

      // Floating button to add a new event
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          try {
            final newEvent = await Navigator.push<EventModel>(
              context,
              MaterialPageRoute(builder: (_) => const EventPlanner()),
            );

            if (newEvent != null && mounted) {
              EventManager.addEvent(newEvent); // explicitly add
              setState(() {}); // refresh dashboard
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 4),
                  backgroundColor: const Color.fromARGB(255, 53, 117, 110),
                  content: Text("Event Saved: ${newEvent.title}", style: const TextStyle(fontSize: 16)),
                ),
              );
            }
          } catch (e, stack) {
            print("Error opening EventPlanner: $e\n$stack");
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to open event planner"), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  // Build horizontal list of events per network
  Widget _buildNetworkEvents(String network) {
    final events = EventManager.events.where((e) => e.network == network).toList();
    final color = _getNetworkColor(network);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(network, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 8),

        if (events.isEmpty)
          Text("No events for $network", style: const TextStyle(color: Colors.grey)),

        if (events.isNotEmpty)
          SizedBox(
            height: 170,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return Stack(
                  children: [
                    Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      child: EventPanelCard(event: event, onTap: () {}),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                              onPressed: () => editEvent(event)),
                          IconButton(icon: const Icon(Icons.delete, color: Color.fromARGB(255, 146, 42, 77), size: 20),
                              onPressed: () => deleteEvent(event)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Helper for network colors
  Color _getNetworkColor(String network) {
    switch (network.toLowerCase()) {
      case "men":
        return Colors.blueGrey;
      case "women":
        return const Color.fromARGB(255, 146, 42, 77);
      default:
        return const Color.fromARGB(255, 53, 117, 110);
    }
  }
}
  // Helper for network colors
  Color _getNetworkColor(String network) {
    switch (network.toLowerCase()) {
      case "men":
        return Colors.blueGrey;
      case "women":
        return const Color.fromARGB(255, 146, 42, 77);
      default:
        return const Color.fromARGB(255, 53, 117, 110);
    }
  }

