// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:ui_web' as ui;
import 'dart:html' as html;
import 'dart:math' as math;
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
  final List<Map<String, dynamic>> _membersCache = [];
  DateTime? _membersCacheFetchedAt;

  static const Duration _membersCacheTtl = Duration(minutes: 2);
  static const double _earlyAcceptConfidence = 95.0;
  static const int _compareBatchSize = 4;
  static const int _livenessRetries = 2;

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
    _preloadMembers();
  }

  Future<void> _preloadMembers() async {
    try {
      await _getMembersForScan(forceRefresh: true);
    } catch (_) {
      // Non-blocking warmup; scan flow handles fetch errors explicitly.
    }
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
      final video =
          html.document.getElementById('attendanceVideo') as html.VideoElement?;

      if (video == null) {
        throw Exception('Video element not found');
      }

      debugPrint(
          'DEBUG CAM: video size = ${video.videoWidth}x${video.videoHeight}');

      // Use a default size if video dimensions aren't ready yet
      final width = video.videoWidth > 0 ? video.videoWidth : 640;
      final height = video.videoHeight > 0 ? video.videoHeight : 480;

      // Downscale large frames to reduce payload and Face++ roundtrip time.
      const maxSide = 640;
      final largestSide = math.max(width, height).toDouble();
      final scale = largestSide > maxSide ? maxSide / largestSide : 1.0;
      final targetWidth = (width * scale).round();
      final targetHeight = (height * scale).round();

      final canvas =
          html.CanvasElement(width: targetWidth, height: targetHeight);
      canvas.context2D.drawImageScaled(video, 0, 0, targetWidth, targetHeight);
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.82);

      if (dataUrl == 'data:,') {
        throw Exception('Canvas capture returned empty image');
      }

      final base64 = dataUrl.split(',')[1];
      debugPrint('DEBUG CAM: captured base64 length = ${base64.length}');
      return base64;
    } catch (e) {
      debugPrint('DEBUG CAM ERROR: $e');
      throw Exception('Photo capture failed: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getMembersForScan({
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _membersCacheFetchedAt != null &&
        now.difference(_membersCacheFetchedAt!) < _membersCacheTtl &&
        _membersCache.isNotEmpty) {
      return _membersCache;
    }

    final rows = await supabase
        .from('members')
        .select('id, name, photo_url, is_newcomer');

    final members = List<Map<String, dynamic>>.from(rows)
        .where((row) => (row['photo_url'] as String?)?.isNotEmpty == true)
        .toList();

    _membersCache
      ..clear()
      ..addAll(members);
    _membersCacheFetchedAt = now;

    return _membersCache;
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
      debugPrint('DEBUG 1: capturing photo...');
      final String webcamBase64 = await _capturePhoto();
      debugPrint('DEBUG 2: photo captured, length: ${webcamBase64.length}');

      final validation = await FaceMatchService.validateFaceFrame(
        imageBase64: webcamBase64,
        strict: true,
      );
      if (!validation.isValid) {
        setState(() {
          _status = validation.message;
          _isProcessing = false;
        });
        return;
      }

      final liveness = await _runLivenessCheckWithRetry(
        firstFrameBase64: webcamBase64,
        firstValidation: validation,
      );

      if (!liveness.isValid) {
        setState(() {
          _status = liveness.message;
          _isProcessing = false;
        });
        return;
      }

      setState(() => _status = "Looking up members...");

      // Step 2
      debugPrint('DEBUG 3: fetching members...');
      final members = await _getMembersForScan();
      debugPrint('DEBUG 4: members count = ${members.length}');

      if (members.isEmpty) {
        setState(() {
          _status = "No members found. Please add members first.";
          _isProcessing = false;
        });
        return;
      }

      debugPrint('DEBUG 6: starting face comparison loop...');
      setState(() => _status = "Comparing faces...");

      String? matchedName;
      String? matchedMemberId;
      bool matchedIsNewcomer = false;
      double highestConfidence = 0;

      for (var i = 0; i < members.length; i += _compareBatchSize) {
        final batch = members.skip(i).take(_compareBatchSize).toList();

        final results = await Future.wait(
          batch.map(
            (member) => _compareAgainstMember(
              webcamBase64: webcamBase64,
              member: member,
            ),
          ),
        );

        for (final result in results) {
          if (result == null) {
            continue;
          }

          if (result.confidence > highestConfidence) {
            highestConfidence = result.confidence;
            matchedName = result.member['name']?.toString();
            matchedMemberId = result.member['id']?.toString();
            matchedIsNewcomer = result.member['is_newcomer'] == true;
          }
        }

        if (highestConfidence >= _earlyAcceptConfidence) {
          debugPrint(
              'DEBUG 10b: early exit on strong confidence $highestConfidence');
          break;
        }
      }

      debugPrint('DEBUG 11: highest confidence = $highestConfidence');

      if (FaceMatchService.isSamePerson(highestConfidence) &&
          matchedName != null) {
        await supabase.from('attendance').insert({
          'member_id': matchedMemberId,
          'member_name': matchedName,
          'event_title': widget.event.title,
          'network': widget.event.network,
          'is_newcomer': matchedIsNewcomer,
        });

        if (matchedIsNewcomer && matchedMemberId != null) {
          await supabase
              .from('members')
              .update({'is_newcomer': false}).eq('id', matchedMemberId);

          final index = _membersCache.indexWhere(
            (member) => member['id']?.toString() == matchedMemberId,
          );
          if (index != -1) {
            _membersCache[index]['is_newcomer'] = false;
          }
        }

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
      debugPrint('DEBUG FATAL: $e');
      setState(() {
        _status = "Error: $e";
        _isProcessing = false;
      });
    }
  }

  Future<FaceValidationResult> _runLivenessCheckWithRetry({
    required String firstFrameBase64,
    required FaceValidationResult firstValidation,
  }) async {
    FaceValidationResult lastFailure = const FaceValidationResult(
      isValid: false,
      message: 'Liveness check failed. Please try again.',
    );

    for (var attempt = 1; attempt <= _livenessRetries; attempt++) {
      setState(() {
        _status = _livenessRetries == 1
            ? 'Running liveness check...'
            : 'Running liveness check ($attempt/$_livenessRetries)...';
      });

      await Future<void>.delayed(const Duration(milliseconds: 550));

      try {
        final secondFrameBase64 = await _capturePhoto();
        final secondValidation = await FaceMatchService.validateFaceFrame(
          imageBase64: secondFrameBase64,
          strict: true,
        );

        if (!secondValidation.isValid) {
          lastFailure = secondValidation;
          continue;
        }

        final liveness = await FaceMatchService.validateLivenessPair(
          frameBase64A: firstFrameBase64,
          frameBase64B: secondFrameBase64,
          frameAValidation: firstValidation,
          frameBValidation: secondValidation,
        );

        if (liveness.isValid) {
          return liveness;
        }

        lastFailure = liveness;
      } catch (_) {
        lastFailure = const FaceValidationResult(
          isValid: false,
          message:
              'Liveness check had a temporary issue. Keep your face centered and retry.',
        );
      }
    }

    return lastFailure;
  }

  Future<_MemberCompareResult?> _compareAgainstMember({
    required String webcamBase64,
    required Map<String, dynamic> member,
  }) async {
    final photoUrl = member['photo_url'] as String?;
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    try {
      final confidence = await FaceMatchService.compareFaces(
        webcamBase64: webcamBase64,
        storedPhotoUrl: photoUrl,
      );
      return _MemberCompareResult(member: member, confidence: confidence);
    } catch (e) {
      debugPrint('DEBUG ERR: member comparison failed: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // Stop the camera stream when leaving the page
    _videoElement.srcObject?.getTracks().forEach((track) => track.stop());
    super.dispose();
  }

  Color _statusColor() {
    if (_matchSuccess == true) {
      return const Color(0xFF1B8D4A);
    }
    if (_matchSuccess == false || _status.startsWith('Error')) {
      return const Color(0xFFB23A3A);
    }
    return const Color(0xFF0F766E);
  }

  IconData _statusIcon() {
    if (_matchSuccess == true) {
      return Icons.verified_rounded;
    }
    if (_matchSuccess == false || _status.startsWith('Error')) {
      return Icons.error_outline_rounded;
    }
    if (_isProcessing) {
      return Icons.autorenew_rounded;
    }
    return Icons.camera_front_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Scaffold(
      appBar: AppBar(title: Text("Scan: ${widget.event.title}")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4FBF9), Color(0xFFE9F4F1)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Card(
                elevation: 8,
                shadowColor: const Color(0x33206B63),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Container(
                        width: 340,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0F766E), width: 2),
                          borderRadius: BorderRadius.circular(14),
                          color: Colors.black,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _webcamReady
                              ? HtmlElementView(viewType: _viewId)
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(_statusIcon(), color: statusColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _status,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_resultMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _matchSuccess == true
                                ? const Color(0xFFECFDF3)
                                : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _matchSuccess == true
                                  ? const Color(0xFF86EFAC)
                                  : const Color(0xFFFDA4AF),
                            ),
                          ),
                          child: Text(
                            _resultMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: _matchSuccess == true
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF991B1B),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              _isProcessing || !_webcamReady ? null : _scanAndMatch,
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
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (_matchSuccess == true) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text("Done - go back"),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberCompareResult {
  final Map<String, dynamic> member;
  final double confidence;

  const _MemberCompareResult({
    required this.member,
    required this.confidence,
  });
}
