import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Screen for generating QR codes for hostel rooms/areas
/// Admin can generate these to place at physical locations
class QRGeneratorScreen extends StatefulWidget {
  const QRGeneratorScreen({super.key});
  @override
  State<QRGeneratorScreen> createState() => _QRGeneratorScreenState();
}

class _QRGeneratorScreenState extends State<QRGeneratorScreen> {
  final _blockCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  String? _qrData;

  void _generate() {
    if (_blockCtrl.text.isEmpty || _roomCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Block and Room required')));
      return;
    }
    setState(() {
      _qrData = 'HOSTELCARE:${_blockCtrl.text.trim()}:${_roomCtrl.text.trim()}:${_floorCtrl.text.trim()}';
    });
  }

  @override
  void dispose() { _blockCtrl.dispose(); _roomCtrl.dispose(); _floorCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Generate QR Code'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            TextField(controller: _blockCtrl, decoration: const InputDecoration(labelText: 'Hostel Block', prefixIcon: Icon(Icons.apartment))),
            const SizedBox(height: 12),
            TextField(controller: _roomCtrl, decoration: const InputDecoration(labelText: 'Room Number', prefixIcon: Icon(Icons.meeting_room))),
            const SizedBox(height: 12),
            TextField(controller: _floorCtrl, decoration: const InputDecoration(labelText: 'Floor (optional)', prefixIcon: Icon(Icons.layers))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.qr_code),
              label: const Text('Generate QR'),
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
            )),
          ]))),
          if (_qrData != null) ...[
            const SizedBox(height: 24),
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
              Text('QR Code Ready', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: QrImageView(data: _qrData!, version: QrVersions.auto, size: 200),
              ),
              const SizedBox(height: 12),
              Text(_qrData!, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontFamily: 'monospace')),
              const SizedBox(height: 16),
              Text('Print and place this QR at the location.\nStudents can scan to auto-fill complaint location.',
                style: TextStyle(color: Colors.grey[600], fontSize: 13), textAlign: TextAlign.center),
            ]))),
          ],
        ]),
      ),
    );
  }
}
