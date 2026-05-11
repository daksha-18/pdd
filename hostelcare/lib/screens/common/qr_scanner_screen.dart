import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../student/submit_complaint_screen.dart';

/// QR Scanner screen for auto-filling location in complaints
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _scanned = false;
  String _status = 'Point camera at QR code on hostel room/area';
  final MobileScannerController controller = MobileScannerController();

  void _handleQRData(String data) {
    if (_scanned) return;
    setState(() => _scanned = true);

    // Expected QR format: "HOSTELCARE:BlockA:Room101:Floor1"
    try {
      final parts = data.split(':');
      if (parts.length >= 3 && parts[0] == 'HOSTELCARE') {
        final block = parts[1];
        final room = parts[2];
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SubmitComplaintScreen(prefilledBlock: block, prefilledRoom: room, qrScanned: true),
        ));
      } else {
        _showError('Invalid QR code. Expected HostelCare+ QR format.');
      }
    } catch (e) {
      _showError('Could not read QR code data.');
    }
  }

  void _showError(String msg) {
    setState(() {
      _status = msg;
      _scanned = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan QR Code', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front, color: Colors.white);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear, color: Colors.white);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRData(barcode.rawValue!);
                }
              }
            },
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: cs.primary, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                // Demo button for testing without camera
                TextButton.icon(
                  icon: const Icon(Icons.bug_report, size: 18, color: Colors.white70),
                  label: const Text('Simulate Scan (Demo)', style: TextStyle(color: Colors.white70)),
                  onPressed: () => _handleQRData('HOSTELCARE:Block A:101:1'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
