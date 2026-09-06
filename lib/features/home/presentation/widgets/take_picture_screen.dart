import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';

class TakePictureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final String? officeAddress;

  const TakePictureScreen({
    super.key,
    required this.cameras,
    this.officeAddress,
  });

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  CameraController? _controller;
  int _cameraIndex = 0;

  Timer? _timer;
  DateTime _currentTime = DateTime.now();

  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startClock();
  }

  void _startClock() {
    _updateTime();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTime();
    });
  }

  void _updateTime() {
    if (!mounted) return;

    setState(() {
      _currentTime = DateTime.now();
    });
  }

  Future<void> _initCamera() async {
    _controller = CameraController(
      widget.cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();

    // Pastikan flash SELALU mati saat kamera pertama kali dibuka
    await _controller!.setFlashMode(FlashMode.off);

    // Sinkronkan state tombol
    _isFlashOn = false;

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (widget.cameras.length < 2) return;

    _cameraIndex = (_cameraIndex + 1) % widget.cameras.length;

    await _controller?.dispose();
    await _initCamera();
  }

  Future<void> _takePicture() async {
    if (!_controller!.value.isInitialized) return;

    final image = await _controller!.takePicture();

    if (!mounted) return;

    Navigator.pop(context, File(image.path));
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final newFlashMode = _isFlashOn ? FlashMode.off : FlashMode.torch;

    try {
      await _controller!.setFlashMode(newFlashMode);

      if (!mounted) return;

      setState(() {
        _isFlashOn = !_isFlashOn;
      });
    } catch (e) {
      debugPrint('Gagal mengubah flash: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.22,
            left: MediaQuery.of(context).size.width * 0.05,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(_currentTime),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: MediaQuery.of(context).size.width * 0.19,
                          height: 0.95,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,

                          fontFamily: 'RobotoCondensed',
                        ),
                      ),

                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.025,
                      ),

                      Container(
                        margin: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.008,
                        ),
                        width: 3,
                        height: MediaQuery.of(context).size.height * 0.07,
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),

                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.025,
                      ),

                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).size.height * 0.008,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy').format(_currentTime),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.045,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'RobotoCondensed',
                                ),
                              ),

                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.003,
                              ),

                              Text(
                                DateFormat('EEEE').format(_currentTime),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize:
                                      MediaQuery.of(context).size.width * 0.035,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'RobotoCondensed',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: MediaQuery.of(context).size.height * 0.012),

                  Text(
                    widget.officeAddress?.trim().isNotEmpty == true
                        ? widget.officeAddress!
                        : 'Alamat office tidak tersedia',
                    textAlign: TextAlign.start,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.07,
            left: 0,
            right: 0,
            child: SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.15,
                    child: GestureDetector(
                      onTap: _toggleFlash,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .35),
                          ),
                        ),
                        child: Icon(
                          _isFlashOn
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.22,
                      height: MediaQuery.of(context).size.width * 0.22,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.17,
                          height: MediaQuery.of(context).size.width * 0.17,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12, width: 2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    right: MediaQuery.of(context).size.width * 0.15,
                    child: GestureDetector(
                      onTap: _switchCamera,
                      child: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .35),
                          ),
                        ),
                        child: const Icon(
                          Icons.cameraswitch_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
