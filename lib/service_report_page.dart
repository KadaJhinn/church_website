import 'package:flutter/material.dart';
import 'attendance_manager.dart';

class ServiceReportPage extends StatelessWidget {
  final String serviceName;

  const ServiceReportPage({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sunday Service")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ValueListenableBuilder(
          valueListenable: AttendanceManager.attendees,
          builder: (context, attendees, _) {
            final counts =
                AttendanceManager.getCounts(serviceName);

            final data = [
              {"label": "Men", "value": counts["Men"] ?? 0, "color": Colors.blueGrey},
              {"label": "Women", "value": counts["Women"] ?? 0, "color": Colors.pink},
              {"label": "Youth", "value": counts["Youth"] ?? 0, "color": Colors.blue},
              {"label": "Young Professionals", "value": counts["Young Professional"] ?? 0, "color": Colors.green},
              {"label": "Kids", "value": counts["Kids"] ?? 0, "color": Colors.purple},
            ];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$serviceName (Report)",
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),

                const SizedBox(height: 30),

                // SCALE
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    8,
                    (i) => Text("${i * 10}"),
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    children: data.map((item) {
                      final value = item["value"] as int;

                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 130,
                              child: Text(item["label"] as String),
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 26,
                                    color: Colors.grey.shade300,
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: value / 70,
                                    child: Container(
                                      height: 26,
                                      color:
                                          item["color"] as Color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text("$value"),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}