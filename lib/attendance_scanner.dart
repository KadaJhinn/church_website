import 'package:flutter/material.dart';
import 'event_manager.dart';
import 'event_model.dart'; 

class AttendanceScanner extends StatefulWidget {
  const AttendanceScanner({super.key});

  @override
  State<AttendanceScanner> createState() => _AttendanceScannerState();
}

class _AttendanceScannerState extends State<AttendanceScanner> {
  int attendees = 0;

  String? selectedService;
  String? selectedEvent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Facial Recognition Attendance Scanner")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Total Attendees: $attendees",
                style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _showSundayServiceDialog,
                  child: const Text("Sunday Service"),
                ),
                ElevatedButton(
                  onPressed: _showEventsDialog,
                  child: const Text("Events"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Sunday Service options
  void _showSundayServiceDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Service"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text("First Service"),
              value: "First Service",
              groupValue: selectedService,
              onChanged: (val) {
                setState(() => selectedService = val);
                Navigator.pop(context);
                _openScanPage(val!, "Sunday Service");
              },
            ),
            RadioListTile<String>(
              title: const Text("Second Service"),
              value: "Second Service",
              groupValue: selectedService,
              onChanged: (val) {
                setState(() => selectedService = val);
                Navigator.pop(context);
                _openScanPage(val!, "Sunday Service");
              },
            ),
          ],
        ),
      ),
    );
  }

  // Event location options
  void _showEventsDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Event Location"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _eventButton("Rooftop"),
            _eventButton("Men's Network"),
            _eventButton("Women's Network"),
          ],
        ),
      ),
    );
  }

  Widget _eventButton(String location) {
    return GestureDetector(
      onTap: () {
        setState(() => selectedEvent = location);
        Navigator.pop(context);
        _openScanPage(location, location);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.teal.withOpacity(0.1),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.teal),
            const SizedBox(width: 12),
            Text(location, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _openScanPage(String title, String network) {
    // Actually reference EventModel
    EventModel? event = EventManager.events
        .firstWhere((e) => e.network == network && e.title == title, orElse: () => EventModel(
          title: title,
          date: DateTime.now(),
          time: "00:00",
          network: network,
          suggestions: [],
          attendance: 0,
        ));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanPlaceholderPage(
          event: event,
          onScan: () {
            setState(() => attendees += 1);

            // Increment attendance
            event.attendance++;
          },
        ),
      ),
    );
  }
}

// Scan placeholder page
class ScanPlaceholderPage extends StatelessWidget {
  final EventModel event;
  final VoidCallback onScan;

  const ScanPlaceholderPage({
    super.key,
    required this.event,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Start: ${event.title}")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onScan,
              child: const Text("Start"),
            ),
          ],
        ),
      ),
    );
  }
}