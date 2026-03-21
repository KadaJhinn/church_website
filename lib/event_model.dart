import 'dart:typed_data';
import 'dart:convert';

class EventModel {
  final String title;
  final DateTime date;
  final String time;
  final String network;
  final List<String> suggestions;
  final Uint8List? imageBytes;
  final String? memberChoice;

  // ✅ NEW FIELD
  final String service; // "1st Service" or "2nd Service"

  int attendance;

  EventModel({
    required this.title,
    required this.date,
    required this.time,
    required this.network,
    required this.suggestions,
    this.imageBytes,
    this.memberChoice,

    // ✅ DEFAULT so old data still works
    this.service = "1st Service",

    this.attendance = 0,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'title': title,
        'date': date.toIso8601String(),
        'time': time,
        'network': network,
        'suggestions': suggestions,
        'memberChoice': memberChoice,
        'imageBytes': imageBytes != null ? base64Encode(imageBytes!) : null,
        'attendance': attendance,

        // ✅ SAVE SERVICE
        'service': service,
      };

  // Create EventModel from Firestore JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      title: json['title'],
      date: DateTime.parse(json['date']),
      time: json['time'],
      network: json['network'],
      suggestions: List<String>.from(json['suggestions']),
      memberChoice: json['memberChoice'],
      imageBytes: json['imageBytes'] != null
          ? base64Decode(json['imageBytes'])
          : null,
      attendance: json['attendance'] ?? 0,

      // ✅ LOAD SERVICE (fallback if missing)
      service: json['service'] ?? "1st Service",
    );
  }
}