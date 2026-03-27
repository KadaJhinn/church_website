import 'package:flutter/material.dart';
import 'register_page.dart';
import 'attendance_scanner.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  final bool embeddedInDashboard;
  final VoidCallback? onBackToDashboard;

  const LandingPage({
    super.key,
    this.embeddedInDashboard = false,
    this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: embeddedInDashboard
          ? AppBar(
              title: const Text("Attendance"),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    onBackToDashboard ?? () => Navigator.maybePop(context),
              ),
            )
          : null,
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
                    builder: (_) => const AttendanceScanner(),
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
            if (!embeddedInDashboard)
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
