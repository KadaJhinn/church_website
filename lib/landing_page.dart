import 'package:flutter/material.dart';
import 'register_page.dart';
import 'web_scan_page.dart';
import 'login_page.dart';
import 'event_model.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Church logo / title
            const Icon(Icons.church, size: 80, color: Color(0xFF385B4F)),
            const SizedBox(height: 16),
            const Text(
              "MyPresence",
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Color(0xFF385B4F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Church Attendance System",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 60),

            // Register button
            SizedBox(
              width: 280,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterPage(),
                  ),
                ),
                icon: const Icon(Icons.person_add, size: 24),
                label: const Text(
                  "Register as Member",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF385B4F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Scan attendance button
            SizedBox(
              width: 280,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WebScanPage(
                      event: EventModel(
                        title: 'Walk-in',
                        date: DateTime.now(),
                        time: '00:00',
                        network: 'General',
                        suggestions: [],
                        attendance: 0,
                      ),
                      onAttendanceCounted: () {},
                    ),
                  ),
                ),
                icon: const Icon(Icons.face_retouching_natural, size: 24),
                label: const Text(
                  "Scan Attendance",
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF385B4F),
                  side: const BorderSide(color: Color(0xFF385B4F), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Small admin link at the bottom
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              ),
              child: const Text(
                "Admin Login",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}