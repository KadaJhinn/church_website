import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'event_model.dart';
import 'event_manager.dart';

class EventPlanner extends StatefulWidget {
  final EventModel? editEvent;
  final VoidCallback? onSave;
  final String? initialMemberChoice;

  const EventPlanner({
    super.key,
    this.editEvent,
    this.onSave,
    this.initialMemberChoice,
  });

  @override
  State<EventPlanner> createState() => _EventPlannerState();
}

class _EventPlannerState extends State<EventPlanner> {
  DateTime? eventDate;
  TimeOfDay? eventTime;
  final captionController = TextEditingController();
  final questionController = TextEditingController(text: "Enter your suggestion question here");
  final choiceControllers = List.generate(3, (_) => TextEditingController(text: "Choice"));
  String? selectedChoice;

  Uint8List? imageBytes;
  String network = "Rooftop"; // Event location

  late String memberChoice;

  @override
  void initState() {
    super.initState();

    memberChoice = widget.initialMemberChoice ?? "Going";

    if (widget.editEvent != null) {
      captionController.text = widget.editEvent!.title;
      eventDate = widget.editEvent!.date;
      eventTime = TimeOfDay(
        hour: int.parse(widget.editEvent!.time.split(":")[0]),
        minute: int.parse(widget.editEvent!.time.split(":")[1]),
      );
      network = widget.editEvent!.network;
      imageBytes = widget.editEvent!.imageBytes;

      if (widget.editEvent!.memberChoice != null) {
        memberChoice = widget.editEvent!.memberChoice!;
      }

      if (widget.editEvent!.suggestions.isNotEmpty) {
        questionController.text = widget.editEvent!.suggestions[0];
        for (int i = 0; i < widget.editEvent!.suggestions.length - 1 && i < 3; i++) {
          choiceControllers[i].text = widget.editEvent!.suggestions[i + 1];
        }
        selectedChoice = choiceControllers[0].text;
      } else {
        selectedChoice = choiceControllers[0].text;
      }
    } else {
      selectedChoice = choiceControllers[0].text;
    }
  }

  Future pickImage() async {
    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (img != null) {
      final bytes = await img.readAsBytes();
      setState(() => imageBytes = bytes);
    }
  }

  Future pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: eventDate ?? DateTime.now(),
    );
    if (picked != null) setState(() => eventDate = picked);
  }

  Future pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: eventTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => eventTime = picked);
  }

  void saveEvent() {
    if (captionController.text.isEmpty || eventDate == null || eventTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in title, date, and time")));
      return;
    }

    final suggestions = [
      questionController.text,
      ...choiceControllers.map((c) => c.text)
    ];

    final newEvent = EventModel(
      title: captionController.text,
      date: eventDate!,
      time: "${eventTime!.hour}:${eventTime!.minute}",
      network: network, // Save selected event location
      suggestions: suggestions,
      imageBytes: imageBytes,
      memberChoice: memberChoice,
    );

    if (widget.editEvent != null) {
      EventManager.updateEvent(widget.editEvent!, newEvent);
    } else {
      EventManager.addEvent(newEvent);
    }

    widget.onSave?.call();
    Navigator.pop(context, newEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Event Planner")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Top-right Insert Member Choices with outline box
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Insert Member Choices",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Radio<String>(
                          value: "Going",
                          groupValue: memberChoice,
                          onChanged: (val) {
                            setState(() {
                              memberChoice = val!;
                            });
                          },
                        ),
                        const Text("Going"),
                        Radio<String>(
                          value: "Not Going",
                          groupValue: memberChoice,
                          onChanged: (val) {
                            setState(() {
                              memberChoice = val!;
                            });
                          },
                        ),
                        const Text("Not Going"),
                        Radio<String>(
                          value: "Going With",
                          groupValue: memberChoice,
                          onChanged: (val) {
                            setState(() {
                              memberChoice = val!;
                            });
                          },
                        ),
                        const Text("Going With"),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text("Event Title", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: captionController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),

          Row(children: [
            ElevatedButton(onPressed: pickDate, child: const Text("Select Date")),
            const SizedBox(width: 20),
            Text(eventDate == null
                ? "No date"
                : "${eventDate!.month}/${eventDate!.day}/${eventDate!.year}"),
          ]),
          const SizedBox(height: 15),

          Row(children: [
            ElevatedButton(onPressed: pickTime, child: const Text("Select Time")),
            const SizedBox(width: 20),
            Text(eventTime == null ? "No time" : eventTime!.format(context)),
          ]),
          const SizedBox(height: 20),

          ElevatedButton(onPressed: pickImage, child: const Text("Upload Poster")),
          if (imageBytes != null)
            Image.memory(imageBytes!, height: 150),
          const SizedBox(height: 30),

          const Text("Suggestion Question", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: questionController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 15),

          Column(
            children: List.generate(3, (i) {
              return Row(
                children: [
                  Radio<String>(
                    value: choiceControllers[i].text,
                    groupValue: selectedChoice,
                    onChanged: (val) {
                      setState(() {
                        selectedChoice = val;
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: choiceControllers[i],
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      onChanged: (val) {
                        if (selectedChoice == choiceControllers[i].text) {
                          setState(() {
                            selectedChoice = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              );
            }),
          ),

          const SizedBox(height: 20),

          // 🔹 New Event Location Dropdown
          Row(
            children: [
              const Text(
                "Event: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: network,
                items: <String>['Rooftop', 'Men', 'Women']
                    .map((loc) => DropdownMenuItem(
                          value: loc,
                          child: Text(loc),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    network = val!;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(onPressed: saveEvent, child: const Text("Save Event")),
          ),
        ]),
      ),
    );
  }
}