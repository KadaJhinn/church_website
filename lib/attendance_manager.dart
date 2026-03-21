import 'package:flutter/foundation.dart';

class Attendee {
  final String name;
  final String category; // Men, Women, Youth, Young Pro, Kids
  final String service;  // First Service / Second Service
  final DateTime time;

  Attendee({
    required this.name,
    required this.category,
    required this.service,
    required this.time,
  });
}

class AttendanceManager {
  static final ValueNotifier<List<Attendee>> attendees =
      ValueNotifier([]);

  static void addAttendee(Attendee attendee) {
    attendees.value = [...attendees.value, attendee];
  }

  // feeds graph
  static Map<String, int> getCounts(String service) {
    Map<String, int> counts = {
      "Men": 0,
      "Women": 0,
      "Youth": 0,
      "Young Pro": 0,
      "Kids": 0,
    };

    for (var person in attendees.value) {
      if (person.service == service) {
        counts[person.category] =
            (counts[person.category] ?? 0) + 1;
      }
    }

    return counts;
  }
}