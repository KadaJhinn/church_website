import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_manager.dart';
import 'event_model.dart';
import 'web_scan_page.dart';

class AttendanceScanner extends StatefulWidget {
  const AttendanceScanner({super.key});

  @override
  State<AttendanceScanner> createState() => _AttendanceScannerState();
}

class _AttendanceScannerState extends State<AttendanceScanner> {
  final supabase = Supabase.instance.client;
  int attendees = 0;
  String? selectedService;
  String? selectedEvent;
  bool _isLoadingAttendance = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceTotal();
  }

  Future<void> _loadAttendanceTotal() async {
    try {
      final rows = await supabase.from('attendance').select('id');
      if (!mounted) {
        return;
      }
      setState(() {
        attendees = List<dynamic>.from(rows).length;
        _isLoadingAttendance = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Facial Recognition Attendance Scanner"),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF4FBF9), Color(0xFFE5F0ED), Color(0xFFF9F7F2)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0x330F766E)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A0F766E),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF0F766E),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Live Check-in",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              _isLoadingAttendance
                                  ? const Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Color(0xFF0F766E),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      "Total attendees: $attendees",
                                      style: const TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F766E),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 640;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildModeCard(
                            width: compact ? constraints.maxWidth : 350,
                            title: "Sunday Service",
                            subtitle: "First Service / Second Service",
                            icon: Icons.church_rounded,
                            onTap: _showSundayServiceDialog,
                          ),
                          _buildModeCard(
                            width: compact ? constraints.maxWidth : 350,
                            title: "Events",
                            subtitle: "Rooftop, Men, Women",
                            icon: Icons.event_available_rounded,
                            onTap: _showEventsDialog,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    "Tip: after selecting a mode, hold the camera steady with face centered for faster scan.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF4B5563)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required double width,
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: width,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0x330F766E)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF0F766E), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSundayServiceDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildSelectionSheet(
        title: "Select Service",
        options: const ["First Service", "Second Service"],
        icon: Icons.church_rounded,
        onSelected: (val) {
          setState(() => selectedService = val);
          Navigator.pop(context);
          _openScanPage(val, "Sunday Service");
        },
      ),
    );
  }

  Widget _buildSelectionSheet({
    required String title,
    required List<String> options,
    required IconData icon,
    required ValueChanged<String> onSelected,
  }) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF0F766E)),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => onSelected(option),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF8CB8B3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      option,
                      style: const TextStyle(
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventsDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildSelectionSheet(
        title: "Select Event Location",
        options: const ["Rooftop", "Men", "Women"],
        icon: Icons.event_available_rounded,
        onSelected: (val) {
          setState(() => selectedEvent = val);
          Navigator.pop(context);
          _openScanPage(val, val);
        },
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
            _loadAttendanceTotal();
          },
        ),
      ),
    );
  }
}
