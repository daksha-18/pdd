import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class StaffAssignmentsScreen extends StatefulWidget {
  const StaffAssignmentsScreen({super.key});
  @override
  State<StaffAssignmentsScreen> createState() => _StaffAssignmentsScreenState();
}

class _StaffAssignmentsScreenState extends State<StaffAssignmentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _assignments = [];
  bool _loading = true;
  final _tabs = ['All', 'Assigned', 'In Progress', 'Resolved'];
  final _filters = [null, 'assigned', 'in_progress', 'resolved'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) _load(); });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      String url = '${ApiConstants.staff}/assignments?limit=50';
      final status = _filters[_tabCtrl.index];
      if (status != null) url += '&status=$status';
      final res = await ApiService.get(url);
      setState(() { _assignments = res['data'] ?? []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _updateStatus(String id, String status) async {
    final notesCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Mark as ${status.replaceAll('_', ' ')}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: notesCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (optional)', hintText: 'Add resolution notes...')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
      ],
    ));
    if (confirmed != true) return;
    try {
      await ApiService.put('${ApiConstants.staff}/assignments/$id/status', {'status': status, 'notes': notesCtrl.text});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated to ${status.replaceAll('_', ' ')}'), backgroundColor: Colors.green));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _uploadCompletionImages(String id) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80, maxWidth: 1024);
    if (images.isEmpty) return;
    try {
      await ApiService.multipartPost(
        '${ApiConstants.staff}/assignments/$id/completion-images',
        files: images.map((x) => File(x.path)).toList(),
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Images uploaded!'), backgroundColor: Colors.green));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 140, pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.7)])),
              child: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                const Text('My Assignments', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                Text('${_assignments.length} tasks', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              ]))),
            ),
          ),
          bottom: TabBar(controller: _tabCtrl, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70, tabs: _tabs.map((t) => Tab(text: t)).toList()),
        ),
        _loading
          ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          : _assignments.isEmpty
            ? SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text('No assignments', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
              ])))
            : SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(delegate: SliverChildBuilderDelegate(
                  (_, i) => FadeInUp(delay: Duration(milliseconds: i * 100), child: _buildCard(_assignments[i])),
                  childCount: _assignments.length,
                )),
              ),
      ]),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final statusColors = {'assigned': Colors.blue, 'in_progress': Colors.indigo, 'resolved': Colors.green};
    final priorityColors = {'low': Colors.green, 'medium': Colors.orange, 'high': Colors.deepOrange, 'urgent': Colors.red};
    final sc = statusColors[c['status']] ?? Colors.grey;
    final pc = priorityColors[c['priority']] ?? Colors.grey;
    final cat = c['category'] ?? 'other';
    final student = c['submittedBy'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(AppConstants.categoryIcons[cat] ?? '📋', style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(c['complaintId'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: pc.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text((c['priority'] ?? '')[0].toUpperCase() + (c['priority'] ?? '').substring(1), style: TextStyle(color: pc, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        Text(c['description'] ?? '', style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (student != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.person_outline, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text('${student['name']} • ${student['hostelBlock'] ?? ''} ${student['roomNumber'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ],
        const Divider(height: 20),
        Row(children: [
          if (c['status'] == 'assigned') ...[
            Expanded(child: FilledButton.icon(
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Start', style: TextStyle(fontSize: 13)),
              onPressed: () => _updateStatus(c['_id'], 'in_progress'),
            )),
            const SizedBox(width: 8),
          ],
          if (c['status'] == 'in_progress') ...[
            Expanded(child: FilledButton.icon(
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Resolve', style: TextStyle(fontSize: 13)),
              onPressed: () => _updateStatus(c['_id'], 'resolved'),
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
            )),
            const SizedBox(width: 8),
          ],
          if (c['status'] != 'resolved') OutlinedButton.icon(
            icon: const Icon(Icons.camera_alt, size: 16),
            label: const Text('Photos', style: TextStyle(fontSize: 13)),
            onPressed: () => _uploadCompletionImages(c['_id']),
          ),
        ]),
      ])),
    );
  }
}
