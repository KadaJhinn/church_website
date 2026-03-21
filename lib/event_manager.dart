import 'event_model.dart';

class EventManager {
  static List<EventModel> events = [];

  
  static void addEvent(EventModel event) {
    events.add(event);
  }

  
  static void updateEvent(EventModel oldEvent, EventModel newEvent) {
    final index = events.indexOf(oldEvent);
    if (index != -1) {
      events[index] = newEvent;
    }
  }

  
  static void deleteEvent(EventModel event) {
    events.remove(event);
  }

  
  static void clearAll() {
    events.clear();
  }
}