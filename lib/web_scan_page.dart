import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'event_model.dart';
import 'face_match_service.dart';

const double kConfidenceThreshold = 80.0;

class WebScanPage extends StatefulWidget {
  final EventModel event;
  final VoidCallback onAttendanceCounted;

  const WebScanPage({
    super.key,
    required this.event,
    required this.onAttendanceCounted,
  });

  @override
  State<WebScanPage> createState() => _WebScanPageState();
}

class _WebScanPageState extends State<WebScanPage> {
  final supabase = Supabase.instance.client;

  bool _webcamReady = false;
  bool _isProcessing = false;
  String _status = "Starting webcam...";
  String? _resultMessage;
  bool? _matchSuccess;

  // The actual HTML video element
  late html.VideoElement _videoElement;
  final String _viewId = 'webcam-view-${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _registerAndStartWebcam();
  }

  Future<void> _registerAndStartWebcam() async {
    // 1. Create the video element directly in Dart
    _videoElement = html.VideoElement()
      ..id = 'attendanceVideo'
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    // 2. Register it as a Flutter platform view
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _videoElement,
    );

    // 3. Request camera access and connect stream directly
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false,
      });

      _videoElement.srcObject = stream;
      await _videoElement.play();

      setState(() {
        _webcamReady = true;
        _status = "Camera ready. Position your face and tap Scan.";
      });
    } catch (e) {
      setState(() {
        _status = "Could not access camera: $e";
      });
    }
  }

  // Capture photo directly from the video element
  Future<String> _capturePhoto() async {
  try {
    // Get the video element directly from the DOM
    final video = html.document.getElementById('attendanceVideo') 
        as html.VideoElement?;
    
    if (video == null) {
      throw Exception('Video element not found');
    }

    print('DEBUG CAM: video size = ${video.videoWidth}x${video.videoHeight}');

    // Use a default size if video dimensions aren't ready yet
    final width = video.videoWidth > 0 ? video.videoWidth : 640;
    final height = video.videoHeight > 0 ? video.videoHeight : 480;

    final canvas = html.CanvasElement(width: width, height: height);
    canvas.context2D.drawImage(video, 0, 0);
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);
    
    if (dataUrl == 'data:,') {
      throw Exception('Canvas capture returned empty image');
    }

    final base64 = dataUrl.split(',')[1];
    print('DEBUG CAM: captured base64 length = ${base64.length}');
    return base64;

  } catch (e) {
    print('DEBUG CAM ERROR: $e');
    throw Exception('Photo capture failed: $e');
  }
}

  Future<void> _scanAndMatch() async {
    setState(() {
      _isProcessing = true;
      _status = "Scanning face...";
      _resultMessage = null;
      _matchSuccess = null;
    });

    try {
      // Step 1
      print('DEBUG 1: capturing photo...');
      final String webcamBase64 = await _capturePhoto();
      print('DEBUG 2: photo captured, length: ${webcamBase64.length}');

      setState(() => _status = "Looking up members...");

      // Step 2
      print('DEBUG 3: fetching members...');
          final List<Map<String, dynamic>> members = await supabase
              .from('members')
              .select('*');
      print('DEBUG 4: members count = ${members.length}');

            if (members.isEmpty) {
              setState(() {
                _status = "No members found. Please add members first.";
                _isProcessing = false;
              });
              return;
            }

      print('DEBUG 6: starting face comparison loop...');
      setState(() => _status = "Comparing faces...");

      String? matchedName;
      String? matchedMemberId;
      double highestConfidence = 0;

      for (final member in members) {
        print('DEBUG 7: checking member = ${member['name']}');
        final String? photoUrl = member['photo_url'];
        print('DEBUG 8: photoUrl = $photoUrl');

        if (photoUrl == null || photoUrl.isEmpty) {
          print('DEBUG 9: skipping — no photo');
          continue;
        }

        try {
          final confidence = await FaceMatchService.compareFaces(
            webcamBase64: webcamBase64,
            storedPhotoUrl: photoUrl,
          );
          print('DEBUG 10: confidence = $confidence');

          if (confidence > highestConfidence) {
            highestConfidence = confidence;
            matchedName = member['name'];
            matchedMemberId = member['id'];
          }
        } catch (e) {
          print('DEBUG ERR: member comparison failed: $e');
          continue;
        }
      }

      print('DEBUG 11: highest confidence = $highestConfidence');

      if (FaceMatchService.isSamePerson(highestConfidence) &&
          matchedName != null) {
        await supabase.from('attendance').insert({
          'member_id': matchedMemberId,
          'member_name': matchedName,
          'event_title': widget.event.title,
          'network': widget.event.network,
        });

        widget.onAttendanceCounted();

        setState(() {
          _matchSuccess = true;
          _resultMessage =
              "Welcome, $matchedName!\nConfidence: ${highestConfidence.toStringAsFixed(1)}%";
          _status = "Attendance recorded ✓";
          _isProcessing = false;
        });
      } else {
        setState(() {
          _matchSuccess = false;
          _resultMessage = highestConfidence > 0
              ? "No match found.\nBest score: ${highestConfidence.toStringAsFixed(1)}% (need 80%+)"
              : "No face detected. Please try again.";
          _status = "Scan failed";
          _isProcessing = false;
        });
      }
    } catch (e) {
      print('DEBUG FATAL: $e');
      setState(() {
        _status = "Error: $e";
        _isProcessing = false;
      });
    }
  }
  @override
  void dispose() {
    // Stop the camera stream when leaving the page
    _videoElement.srcObject?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan: ${widget.event.title}")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Camera preview
              Container(
                width: 320,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _webcamReady
                      ? HtmlElementView(viewType: _viewId) // ✅ uses unique ID
                      : const Center(
                          child: CircularProgressIndicator(color: Colors.teal),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),

              if (_resultMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _matchSuccess == true
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _matchSuccess == true ? Colors.green : Colors.red,
                    ),
                  ),
                  child: Text(
                    _resultMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: _matchSuccess == true
                          ? Colors.green[800]
                          : Colors.red[800],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isProcessing || !_webcamReady ? null : _scanAndMatch,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.face_retouching_natural),
                label: Text(_isProcessing ? "Processing..." : "Scan Face"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),

              if (_matchSuccess == true) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Done — go back"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}