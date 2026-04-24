import 'package:flutter/material.dart';
import '../student/submit_complaint_screen.dart';

/// QR Scanner screen for auto-filling location in complaints
/// Uses mobile_scanner or qr_code_scanner package
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});
  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _scanned = false;
  String _status = 'Point camera at QR code on hostel room/area';

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
        _showError('Invalid QR code. Expected HostelCare QR format.');
      }
    } catch (e) {
      _showError('Could not read QR code data.');
    }
  }

  void _showError(String msg) {
    setState(() { _status = msg; _scanned = false; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.qr_code_scanner, size: 120, color: cs.primary.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                      'Camera preview will appear here\nwhen QR scanner package is configured',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ]),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Icon(Icons.qr_code_2, size: 32, color: cs.primary),
                const SizedBox(height: 8),
                Text(_status, style: TextStyle(color: Colors.grey[600], fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                // Demo button for testing without camera
                OutlinedButton.icon(
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('Demo: Simulate Scan'),
                  onPressed: () => _handleQRData('HOSTELCARE:Block A:101:1'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
