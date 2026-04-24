import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/complaint_provider.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  const ComplaintDetailScreen({super.key, required this.complaintId});
  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ComplaintProvider>().fetchComplaintDetail(widget.complaintId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details'), centerTitle: true),
      body: Consumer<ComplaintProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          final c = provider.selectedComplaint;
          if (c == null) return const Center(child: Text('Not found'));
          final statusColors = {'pending': Colors.orange, 'assigned': Colors.blue, 'in_progress': Colors.indigo, 'resolved': Colors.green, 'closed': Colors.grey};
          final sc = statusColors[c.status] ?? Colors.grey;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FadeInDown(child: _statusBanner(c, sc)),
              const SizedBox(height: 20),
              FadeInUp(delay: const Duration(milliseconds: 100), child: _infoSection(c)),
              const SizedBox(height: 16),
              FadeInUp(delay: const Duration(milliseconds: 200), child: _locationSection(c)),
              if (c.images.isNotEmpty) ...[
                const SizedBox(height: 16),
                FadeInUp(delay: const Duration(milliseconds: 300), child: _imagesSection(c.images, 'Complaint Photos')),
              ],
              if (c.completionImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                FadeInUp(delay: const Duration(milliseconds: 350), child: _imagesSection(c.completionImages, 'Resolution Photos')),
              ],
              const SizedBox(height: 16),
              FadeInUp(delay: const Duration(milliseconds: 400), child: _timelineSection(c)),
              if (c.status == 'resolved' && c.feedback == null) ...[
                const SizedBox(height: 20),
                FadeInUp(delay: const Duration(milliseconds: 500), child: _feedbackSection(c)),
              ],
              if (c.feedback != null) ...[
                const SizedBox(height: 16),
                FadeInUp(delay: const Duration(milliseconds: 500), child: _existingFeedback(c)),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _statusBanner(c, Color color) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(c.categoryIcon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(c.complaintId ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8))),
          ])),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
          child: Text(c.statusLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _infoSection(c) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Details', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Text(c.description, style: TextStyle(color: Colors.grey[600], height: 1.5)),
      const SizedBox(height: 12),
      _detailRow('Category', '${c.categoryIcon} ${c.category[0].toUpperCase()}${c.category.substring(1)}'),
      _detailRow('Priority', c.priority[0].toUpperCase() + c.priority.substring(1)),
      if (c.assignedTo != null) _detailRow('Assigned To', c.assignedTo!['name'] ?? ''),
      if (c.resolutionNotes != null && c.resolutionNotes!.isNotEmpty) _detailRow('Resolution', c.resolutionNotes!),
    ])));
  }

  Widget _detailRow(String label, String value) {
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
      SizedBox(width: 100, child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
    ]));
  }

  Widget _locationSection(c) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Location', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _detailRow('Block', c.location['hostelBlock'] ?? ''),
      _detailRow('Room', c.location['roomNumber'] ?? ''),
      if (c.location['floor'] != null) _detailRow('Floor', c.location['floor']),
      if (c.qrScanned) Row(children: [Icon(Icons.qr_code, size: 16, color: Colors.green[600]), const SizedBox(width: 4), Text('QR Verified', style: TextStyle(color: Colors.green[600], fontSize: 12))]),
    ])));
  }

  Widget _imagesSection(List images, String title) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      SizedBox(height: 120, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: images.length, itemBuilder: (_, i) {
        return Container(width: 120, height: 120, margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(images[i]['url'] ?? ''), fit: BoxFit.cover)),
        );
      })),
    ])));
  }

  Widget _timelineSection(c) {
    final history = c.statusHistory;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Timeline', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ...history.asMap().entries.map((e) {
        final h = e.value;
        final isLast = e.key == history.length - 1;
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: isLast ? Theme.of(context).colorScheme.primary : Colors.grey[300])),
            if (!isLast) Container(width: 2, height: 40, color: Colors.grey[200]),
          ]),
          const SizedBox(width: 12),
          Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((h['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (h['notes'] != null) Text(h['notes'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ]))),
        ]);
      }),
    ])));
  }

  Widget _feedbackSection(c) {
    int rating = 0;
    final commentCtrl = TextEditingController();
    return StatefulBuilder(builder: (context, setSt) {
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Rate Resolution', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
          icon: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 36),
          onPressed: () => setSt(() => rating = i + 1),
        ))),
        const SizedBox(height: 8),
        TextField(controller: commentCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Add a comment...')),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: ElevatedButton(
          onPressed: rating > 0 ? () async {
            await context.read<ComplaintProvider>().submitFeedback(c.id, rating, commentCtrl.text);
          } : null,
          child: const Text('Submit Feedback'),
        )),
      ])));
    });
  }

  Widget _existingFeedback(c) {
    final fb = c.feedback!;
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Your Feedback', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(children: List.generate(5, (i) => Icon(i < (fb['rating'] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 24))),
      if (fb['comment'] != null && fb['comment'].isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(fb['comment'], style: TextStyle(color: Colors.grey[600]))),
    ])));
  }
}
