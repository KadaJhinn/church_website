import 'package:flutter/material.dart';
import 'event_manager.dart';
import 'event_model.dart';
import 'web_scan_page.dart';

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
    EventModel event = EventManager.events.firstWhere(
      (e) => e.network == network && e.title == title,
      orElse: () => EventModel(
        title: title,
        date: DateTime.now(),
        time: "00:00",
        network: network,
        suggestions: [],
        attendance: 0,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WebScanPage(
          event: event,
          onAttendanceCounted: () {
            setState(() => attendees += 1);
            event.attendance++;
          },
        ),
      ),
    );
  }

}