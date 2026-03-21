import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'event_manager.dart';

class MonthlyCalendar extends StatefulWidget {
  const MonthlyCalendar({super.key});

  @override
  State<MonthlyCalendar> createState() => _MonthlyCalendarState();
}

class _MonthlyCalendarState extends State<MonthlyCalendar> {

  DateTime selected = DateTime.now();

  @override
  Widget build(BuildContext context) {

    final eventsToday = EventManager.events.where((e) =>
      e.date.year == selected.year &&
      e.date.month == selected.month &&
      e.date.day == selected.day
    ).toList();

    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.all(16), // added padding
          child: Material(
            child: TableCalendar(
              firstDay: DateTime(2023),
              lastDay: DateTime(2030),
              focusedDay: selected,

              selectedDayPredicate: (d) => isSameDay(d, selected),

              onDaySelected: (d, f) {
                setState(() => selected = d);
              },
            ),
          ),
        ),

        const SizedBox(height: 20),

        Expanded(
          child: ListView.builder(
            itemCount: eventsToday.length,
            itemBuilder: (context, i) {

              final event = eventsToday[i];

              return ListTile(
                title: Text(event.title),
                subtitle: Text(event.time),
              );
            },
          ),
        )

      ],
    );
  }
}