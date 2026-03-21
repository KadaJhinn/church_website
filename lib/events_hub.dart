import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'event_model.dart';
import 'event_manager.dart';

/// Original bar graph for Rooftop, Men, Women
class AnalyticsBarGraph extends StatelessWidget {
  final List<double> values;
  final Color color;

  const AnalyticsBarGraph({
    super.key,
    required this.values,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: values.asMap().entries.map(
          (e) => BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: e.value,
                color: color,
                width: 18,
              ),
            ],
          ),
        ).toList(),
      ),
    );
  }
}

/// Specialized bar graph for Sunday Service
class AnalyticsBarGraphSundayService extends StatelessWidget {
  final List<double> firstValues;
  final List<double> secondValues;
  final List<String> labels;

  const AnalyticsBarGraphSundayService({
    super.key,
    required this.firstValues,
    required this.secondValues,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final barGroups = <BarChartGroupData>[];

    for (var i = 0; i < labels.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: firstValues[i],
              color: Colors.deepPurple,
              width: 8,
            ),
            BarChartRodData(
              toY: secondValues[i],
              color: Colors.green,
              width: 8,
            ),
          ],
          barsSpace: 6,
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: ([...firstValues, ...secondValues].reduce((a, b) => a > b ? a : b)) * 1.1,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(labels[index]),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 10)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 10)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
        barTouchData: BarTouchData(enabled: true),
        groupsSpace: 20,
      ),
    );
  }
}

/// Main EventHub widget
class EventHub extends StatefulWidget {
  const EventHub({super.key});

  @override
  State<EventHub> createState() => _EventHubState();
}

class _EventHubState extends State<EventHub> {
  int _selectedIndex = 0;

  final List<String> networks = [
    "Rooftop",
    "Men",
    "Women",
    "Sunday Service",
  ];

  void updateEventsFromFacialRecognition(List<EventModel> newEvents) {
    setState(() {
      EventManager.events = newEvents;
    });
  }

  int _getWeekOfYear(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysPassed = date.difference(firstDayOfYear).inDays;
    return ((daysPassed + firstDayOfYear.weekday) / 7).ceil();
  }

  Map<String, dynamic> getWeeklyServiceData() {
    Map<int, double> firstServiceMap = {};
    Map<int, double> secondServiceMap = {};

    for (var e in EventManager.events) {
      if (e.network == "Rooftop" &&
          (e.service == "1st Service" || e.service == "2nd Service")) {
        final week = _getWeekOfYear(e.date);
        if (e.service == "1st Service") {
          firstServiceMap[week] = (firstServiceMap[week] ?? 0) + e.attendance;
        } else {
          secondServiceMap[week] = (secondServiceMap[week] ?? 0) + e.attendance;
        }
      }
    }

    final allWeeks = {...firstServiceMap.keys, ...secondServiceMap.keys}.toList()..sort();

    List<double> firstValues = [];
    List<double> secondValues = [];
    List<String> labels = [];

    for (var week in allWeeks) {
      firstValues.add(firstServiceMap[week] ?? 0);
      secondValues.add(secondServiceMap[week] ?? 0);
      labels.add("W$week");
    }

    return {
      "first": firstValues,
      "second": secondValues,
      "labels": labels,
    };
  }

  List<EventModel> getEvents(String network) {
    if (network == "Sunday Service") {
      return EventManager.events
          .where((e) =>
              e.network == "Rooftop" &&
              (e.service == "1st Service" || e.service == "2nd Service"))
          .toList();
    }
    return EventManager.events.where((e) => e.network == network).toList();
  }

  Color _getNetworkColor(String network) {
    switch (network.toLowerCase()) {
      case "men":
        return Colors.blueGrey;
      case "women":
        return Colors.pink;
      case "sunday service":
        return Colors.deepPurple;
      default:
        return const Color(0xFF385B4F);
    }
  }

  @override
  void initState() {
    super.initState();
    EventManager.events = [];
  }

  @override
  Widget build(BuildContext context) {
    final network = networks[_selectedIndex];
    final color = _getNetworkColor(network);
    final events = getEvents(network);
    final analytics = network != "Sunday Service"
        ? {
            "events": events.length,
            "attendance": events.fold<int>(0, (sum, e) => sum + e.attendance),
          }
        : null;

    final weeklyData = network == "Sunday Service" ? getWeeklyServiceData() : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Hub"),
        backgroundColor: const Color(0xFF385B4F),
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.roofing), label: Text("Rooftop")),
              NavigationRailDestination(icon: Icon(Icons.male), label: Text("Men")),
              NavigationRailDestination(icon: Icon(Icons.female), label: Text("Women")),
              NavigationRailDestination(icon: Icon(Icons.church), label: Text("Sunday")),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(network, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    if (network == "Sunday Service") ...[
                      const Text("Sunday Service Analytics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.circle, color: Colors.deepPurple, size: 10),
                          SizedBox(width: 5),
                          Text("1st Service"),
                          SizedBox(width: 20),
                          Icon(Icons.circle, color: Colors.green, size: 10),
                          SizedBox(width: 5),
                          Text("2nd Service"),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 250,
                        child: (weeklyData != null && (weeklyData["labels"] as List).isNotEmpty)
                            ? AnalyticsBarGraphSundayService(
                                firstValues: List<double>.from(weeklyData["first"]),
                                secondValues: List<double>.from(weeklyData["second"]),
                                labels: List<String>.from(weeklyData["labels"]),
                              )
                            : const Center(child: Text("No attendance data")),
                      ),
                    ] else ...[
                      const Text("Analytics", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 200,
                        child: AnalyticsBarGraph(
                          values: [analytics!["events"]!.toDouble(), analytics["attendance"]!.toDouble()],
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: const [
                          SizedBox(width: 18),
                          Text("Events", style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 40),
                          Text("Attendance", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 30),
                    Text("Events", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(height: 15),
                    if (events.isEmpty)
                      const Text("No events yet")
                    else
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: events.map((event) {
                          return SizedBox(
                            width: 250,
                            child: Card(
                              elevation: 3,
                              child: ListTile(
                                title: Text(event.title),
                                subtitle: Text(
                                  "Date: ${event.date.toLocal().toString().split(' ')[0]}\n"
                                  "Time: ${event.time}\n"
                                  "Service: ${event.service}\n"
                                  "Attendance: ${event.attendance}",
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}