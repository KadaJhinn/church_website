import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;

  late html.VideoElement _videoElement;
  final String _viewId =
      'register-webcam-${DateTime.now().millisecondsSinceEpoch}';
  bool _webcamReady = false;
  String? _capturedBase64;
  bool _photoCaptured = false;
  bool _isSaving = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _initVideoElement(); // ✅ register first, then start camera
  }

  // ✅ Step 1: Create and register video element ONCE — never re-registered
  void _initVideoElement() {
    _videoElement = html.VideoElement()
      ..id = 'registerVideo'
      ..autoplay = true
      ..muted = true
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'cover';

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _viewId,
      (int viewId) => _videoElement,
    );

    _startCamera(); // start stream after element is registered
  }

  // ✅ Step 2: Start camera stream — can be called independently
  Future<void> _startCamera() async {
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': false,
      });
      _videoElement.srcObject = stream;
      await _videoElement.play();
      if (mounted) setState(() => _webcamReady = true);
    } catch (e) {
      if (mounted) setState(() => _status = "Could not access camera: $e");
    }
  }

  void _capturePhoto() {
    final width =
        _videoElement.videoWidth > 0 ? _videoElement.videoWidth : 640;
    final height =
        _videoElement.videoHeight > 0 ? _videoElement.videoHeight : 480;

    final canvas = html.CanvasElement(width: width, height: height);
    canvas.context2D.drawImage(_videoElement, 0, 0);
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.9);

    setState(() {
      _capturedBase64 = dataUrl.split(',')[1];
      _photoCaptured = true;
      _status = "Photo captured! ✓";
    });
    // ✅ stream stays alive — never stopped
  }

  // ✅ Retake — just removes the overlay, video was never stopped
  void _retakePhoto() {
    setState(() {
      _capturedBase64 = null;
      _photoCaptured = false;
      _status = '';
    });
  }

  Future<void> _saveMember() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _status = "Please enter a name.");
      return;
    }
    if (_ageController.text.trim().isEmpty) {
      setState(() => _status = "Please enter an age.");
      return;
    }
    if (_selectedGender == null) {
      setState(() => _status = "Please select a gender.");
      return;
    }
    if (_capturedBase64 == null) {
      setState(() => _status = "Please take a photo first.");
      return;
    }

    setState(() {
      _isSaving = true;
      _status = "Uploading photo...";
    });

    try {
      final fileName =
          '${_nameController.text.trim().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final photoBytes = base64Decode(_capturedBase64!);

      await supabase.storage.from('member-photos').uploadBinary(
            fileName,
            photoBytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final photoUrl =
          supabase.storage.from('member-photos').getPublicUrl(fileName);

      setState(() => _status = "Saving member info...");

      await supabase.from('members').insert({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'gender': _selectedGender,
        'photo_url': photoUrl,
      });

      _videoElement.srcObject?.getTracks().forEach((t) => t.stop());

      setState(() {
        _isSaving = false;
        _status = "Member registered successfully! ✓";
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Registered!"),
            content: Text(
                "${_nameController.text.trim()} has been added as a member."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Done"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
        _status = "Error: $e";
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _videoElement.srcObject?.getTracks().forEach((t) => t.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Member")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                Center(
                  child: Container(
                    width: 280,
                    height: 210,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _photoCaptured ? Colors.green : Colors.teal,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // ✅ Always in widget tree — never removed
                          HtmlElementView(viewType: _viewId),

                          // Black loading overlay
                          if (!_webcamReady)
                            Container(
                              color: Colors.black,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.teal),
                              ),
                            ),

                          // Captured photo on top — cleared on retake
                          if (_photoCaptured && _capturedBase64 != null)
                            Image.memory(
                              base64Decode(_capturedBase64!),
                              fit: BoxFit.cover,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Center(
                  child: _photoCaptured
                      ? TextButton.icon(
                          onPressed: _retakePhoto,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Retake photo"),
                        )
                      : ElevatedButton.icon(
                          onPressed: _webcamReady ? _capturePhoto : null,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text("Take Photo"),
                        ),
                ),

                const SizedBox(height: 24),

                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Age",
                    prefixIcon: const Icon(Icons.cake),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: "Gender",
                    prefixIcon: const Icon(Icons.people),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Male", child: Text("Male")),
                    DropdownMenuItem(value: "Female", child: Text("Female")),
                    DropdownMenuItem(value: "Other", child: Text("Other")),
                  ],
                  onChanged: (val) => setState(() => _selectedGender = val),
                ),

                const SizedBox(height: 24),

                if (_status.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _status.contains('✓')
                            ? Colors.green
                            : _status.contains('Error')
                                ? Colors.red
                                : Colors.orange,
                        fontSize: 14,
                      ),
                    ),
                  ),

                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveMember,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.check),
                  label: Text(
                    _isSaving ? "Saving..." : "Register Member",
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}