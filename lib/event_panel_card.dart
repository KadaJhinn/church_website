import 'package:flutter/material.dart';
import 'event_model.dart';

class EventPanelCard extends StatelessWidget {
  final EventModel? event;
  final String? title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color color;

  const EventPanelCard({
    super.key,
    this.event,
    this.title,
    this.subtitle,
    this.onTap,
    this.color = const Color.fromARGB(255, 44, 110, 103),
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = event?.title ?? title ?? "Untitled Event";
    final displaySubtitle = event != null
        ? "${event!.date.month}/${event!.date.day}/${event!.date.year} • ${event!.time}"
        : subtitle ?? "";

    final displayColor = event != null
        ? _getNetworkColor(event!.network)
        : color;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: displayColor.withOpacity(0.15),
        child: Container(
          padding: const EdgeInsets.all(16),
          width: 220, // fixed width for horizontal list
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: displayColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (event?.imageBytes != null)
                      ? Image.memory(
                          event!.imageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            // fallback if image fails
                            return const Icon(Icons.event, color: Color.fromARGB(255, 181, 180, 180), size: 30);
                          },
                        )
                      : const Icon(Icons.event, color: Color.fromARGB(255, 181, 180, 180), size: 30),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: displayColor.darken(0.2),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (displaySubtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        displaySubtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                    if (event != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                        decoration: BoxDecoration(
                          color: displayColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          event!.network,
                          style: const TextStyle(fontSize: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNetworkColor(String network) {
    switch (network.toLowerCase()) {
      case "men":
        return Colors.blueGrey;
      case "women":
        return Colors.pink;
      case "rooftop":
      default:
        return Colors.teal;
    }
  }
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}