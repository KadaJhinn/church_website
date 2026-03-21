import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:image_picker/image_picker.dart';

class MonthlyLineupCalendar extends StatefulWidget {
  const MonthlyLineupCalendar({super.key});

  @override
  State<MonthlyLineupCalendar> createState() => _MonthlyLineupCalendarState();
}

class CaptionEntry {
  String text;
  TimeOfDay time;
  Uint8List? image;

  CaptionEntry(this.text, this.time, {this.image});
}

class _MonthlyLineupCalendarState extends State<MonthlyLineupCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  final TextEditingController _captionController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  Uint8List? _pickedImage;

  final Map<DateTime, List<CaptionEntry>> _captionsByDate = {};

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => _pickedImage = bytes);
    }
  }

  void _saveCaption() {
    final text = _captionController.text.trim();
    if (text.isEmpty || _selectedDay == null) return;

    final dayKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);

    setState(() {
      final entry = CaptionEntry(text, _selectedTime, image: _pickedImage);
      if (_captionsByDate.containsKey(dayKey)) {
        _captionsByDate[dayKey]!.add(entry);
      } else {
        _captionsByDate[dayKey] = [entry];
      }

      _captionController.clear();
      _selectedTime = TimeOfDay.now();
      _pickedImage = null;
    });
  }

  List<CaptionEntry> get _captionsForSelectedDay {
    if (_selectedDay == null) return [];
    final dayKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    return _captionsByDate[dayKey] ?? [];
  }

  List<CaptionEntry> _getEventsForDay(DateTime day) {
    final dayKey = DateTime(day.year, day.month, day.day);
    return _captionsByDate[dayKey] ?? [];
  }

  String formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? "AM" : "PM";
    return "$hour:$minute $period";
  }

  void _editCaption(CaptionEntry entry) {
    _captionController.text = entry.text;
    _selectedTime = entry.time;
    _pickedImage = entry.image;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Caption"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _captionController, decoration: const InputDecoration(labelText: "Caption")),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.access_time),
              label: Text("Time: ${formatTimeOfDay(_selectedTime)}"),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image),
              label: const Text("Pick Image"),
            ),
            if (_pickedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SizedBox(width: 50, height: 50, child: Image.memory(_pickedImage!, fit: BoxFit.cover)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                entry.text = _captionController.text.trim();
                entry.time = _selectedTime;
                entry.image = _pickedImage;
                _captionController.clear();
                _pickedImage = null;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _deleteCaption(CaptionEntry entry) {
    final dayKey = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
    setState(() {
      _captionsByDate[dayKey]?.remove(entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Monthly Lineup Calendar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption input
            TextField(
              controller: _captionController,
              decoration: InputDecoration(
                labelText: _selectedDay == null
                    ? "Select a day to add caption"
                    : "Insert Caption for ${_selectedDay!.toLocal().toIso8601String().substring(0, 10)}",
                border: const OutlineInputBorder(),
              ),
              enabled: _selectedDay != null,
              onSubmitted: (_) => _saveCaption(),
            ),
            const SizedBox(height: 8),

            // Buttons for time & image
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _selectedDay == null ? null : _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text("Time: ${formatTimeOfDay(_selectedTime)}"),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _selectedDay == null ? null : _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text("Pick Image"),
                ),
                if (_pickedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: SizedBox(width: 40, height: 40, child: Image.memory(_pickedImage!, fit: BoxFit.cover)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _selectedDay == null ? null : _saveCaption,
              child: const Text("Save Caption"),
            ),
            const SizedBox(height: 16),

            // Calendar
            TableCalendar(
              firstDay: DateTime(2023),
              lastDay: DateTime(2030),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _selectedDay != null && isSameDay(day, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              eventLoader: _getEventsForDay,
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox();
                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.take(3).map((e) {
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.teal),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Saved captions list
            const Text("Saved Captions:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _captionsForSelectedDay.isEmpty
                  ? const Center(
                      child: Text("No captions for selected day.", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                    )
                  : ListView.builder(
                      itemCount: _captionsForSelectedDay.length,
                      itemBuilder: (context, index) {
                        final caption = _captionsForSelectedDay[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: caption.image != null
                                ? SizedBox(width: 50, height: 50, child: Image.memory(caption.image!, fit: BoxFit.cover))
                                : const Icon(Icons.note),
                            title: Text(caption.text),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatTimeOfDay(caption.time)),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                  onPressed: () => _editCaption(caption),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCaption(caption),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}