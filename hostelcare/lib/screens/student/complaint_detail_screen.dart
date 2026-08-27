import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
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
    Future.microtask(() { if (mounted) context.read<ComplaintProvider>().fetchComplaintDetail(widget.complaintId); });
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
          final statusColors = {'pending': Colors.orange, 'assigned': Colors.blue, 'in_progress': Colors.indigo, 'resolved': Colors.green, 'closed': Colors.grey, 'withdrawn': Colors.grey[600]!};
          final sc = statusColors[c.status] ?? Colors.grey;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FadeInDown(child: _statusBanner(c, sc)),
              if (c.isCommonArea) ...[
                const SizedBox(height: 16),
                FadeInUp(delay: const Duration(milliseconds: 50), child: _upvoteBanner(c)),
              ],
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
              if (c.status == 'pending' || c.status == 'assigned') ...[
                const SizedBox(height: 24),
                FadeInUp(delay: const Duration(milliseconds: 500), child: _withdrawSection(context, c)),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _upvoteBanner(c) {
    final user = context.watch<AuthProvider>().user;
    final isUpvoted = user != null && c.isUpvotedByMe(user.id);
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      color: isUpvoted ? primary.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.people_alt_rounded, color: primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Common Area Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('${c.upvoteCount} student(s) upvoted / affected', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            if (!['closed', 'rejected'].contains(c.status))
              ElevatedButton.icon(
                onPressed: () async {
                  await context.read<ComplaintProvider>().toggleUpvote(c.id);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isUpvoted ? primary : Colors.white,
                  foregroundColor: isUpvoted ? Colors.white : primary,
                  elevation: isUpvoted ? 2 : 0,
                  side: isUpvoted ? null : BorderSide(color: primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(isUpvoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined, size: 16),
                label: Text(isUpvoted ? 'Upvoted' : 'Upvote'),
              ),
          ],
        ),
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
    final quickChips = ['Fast Repair ⚡', 'Polite Staff 😊', 'Thorough Work 👍', 'Clean Finish ✨'];
    return StatefulBuilder(builder: (context, setSt) {
      return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Rate Repair & Resolution Quality', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => IconButton(
          icon: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: Colors.amber, size: 36),
          onPressed: () => setSt(() => rating = i + 1),
        ))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: quickChips.map((chip) => ActionChip(
            label: Text(chip, style: const TextStyle(fontSize: 12)),
            onPressed: () {
              final currentText = commentCtrl.text;
              commentCtrl.text = currentText.isEmpty ? chip : '$currentText, $chip';
            },
          )).toList(),
        ),
        const SizedBox(height: 8),
        TextField(controller: commentCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Add additional feedback notes...')),
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

  Widget _withdrawSection(BuildContext context, c) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
        label: const Text('Withdraw Complaint', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final provider = context.read<ComplaintProvider>();
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Confirm Withdrawal'),
              content: const Text('Are you sure you want to withdraw this complaint?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Withdraw'),
                ),
              ],
            ),
          );
          if (confirm == true) {
            final success = await provider.withdrawComplaint(c.id);
            if (!mounted) return;
            if (success) {
              messenger.showSnackBar(
                const SnackBar(content: Text('Complaint withdrawn successfully'), backgroundColor: Colors.orange),
              );
            } else {
              messenger.showSnackBar(
                const SnackBar(content: Text('Failed to withdraw complaint'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }
}
