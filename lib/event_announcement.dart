import 'package:flutter/material.dart';
import 'event_model.dart';
import 'event_manager.dart';
import 'event_panel_card.dart';
import 'event_planner.dart'; 

class EventAnnouncement extends StatefulWidget {
  const EventAnnouncement({super.key});

  @override
  State<EventAnnouncement> createState() => _EventAnnouncementState();
}

class _EventAnnouncementState extends State<EventAnnouncement> {

  void deleteEvent(EventModel event) {
    setState(() {
      EventManager.events.remove(event);
    });
  }

  Future<void> editEvent(EventModel event) async {
    final updatedEvent = await Navigator.push<EventModel>(
      context,
      MaterialPageRoute(builder: (context) => EventPlanner(editEvent: event)),
    );

    if (updatedEvent != null) {
      setState(() {
        EventManager.updateEvent(event, updatedEvent);
      });
    }
  }

  Future<void> addEvent() async {
    final newEvent = await Navigator.push<EventModel>(
      context,
      MaterialPageRoute(builder: (context) => const EventPlanner()),
    );

    if (newEvent != null) {
      setState(() {
        EventManager.addEvent(newEvent);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooftopEvents = EventManager.events.where((e) => e.network == "Rooftop").toList();
    final menEvents = EventManager.events.where((e) => e.network == "Men").toList();
    final womenEvents = EventManager.events.where((e) => e.network == "Women").toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Events Announcement"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addEvent,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildNetworkRow("Rooftop", rooftopEvents),
            buildNetworkRow("Men", menEvents),
            buildNetworkRow("Women", womenEvents),
          ],
        ),
      ),
    );
  }

  Widget buildNetworkRow(String network, List<EventModel> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          network,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          Text("No events for $network", style: const TextStyle(color: Colors.grey)),
        if (events.isNotEmpty)
          SizedBox(
            height: 150,
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
                      child: EventPanelCard(
                        event: event,
                        onTap: () {
                          // Optional: do something on tap
                        },
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 20,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 20),
                            onPressed: () => editEvent(event),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Color.fromARGB(255, 240, 135, 204), size: 20),
                            onPressed: () => deleteEvent(event),
                          ),
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
}