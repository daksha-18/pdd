import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class AdminComplaintsScreen extends StatefulWidget {
  const AdminComplaintsScreen({super.key});
  @override
  State<AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<AdminComplaintsScreen> {
  List<dynamic> _complaints = [];
  List<dynamic> _staffList = [];
  bool _loading = true;
  String? _statusFilter;
  String? _categoryFilter;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      String url = '${ApiConstants.admin}/complaints?limit=50';
      if (_statusFilter != null) url += '&status=$_statusFilter';
      if (_categoryFilter != null) url += '&category=$_categoryFilter';
      final res = await ApiService.get(url);
      final staffRes = await ApiService.get('${ApiConstants.admin}/staff');
      setState(() { _complaints = res['data'] ?? []; _staffList = staffRes['data'] ?? []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  Future<void> _assignComplaint(String complaintId) async {
    final staffId = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Assign to Staff'),
      content: SizedBox(width: double.maxFinite, child: ListView.builder(
        shrinkWrap: true, itemCount: _staffList.length,
        itemBuilder: (_, i) {
          final s = _staffList[i];
          return ListTile(
            leading: CircleAvatar(child: Text(s['name'][0])),
            title: Text(s['name']), subtitle: Text('${s['specialization']} • Active: ${s['activeAssignments']}'),
            onTap: () => Navigator.pop(ctx, s['_id']),
          );
        },
      )),
    ));
    if (staffId == null) return;
    try {
      await ApiService.put('${ApiConstants.admin}/complaints/$complaintId/assign', {'staffId': staffId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assigned!'), backgroundColor: Colors.green));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _changePriority(String complaintId, String currentPriority) async {
    final priority = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Set Priority'),
      children: AppConstants.priorities.map((p) => SimpleDialogOption(
        onPressed: () => Navigator.pop(ctx, p),
        child: Row(children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: {'low': Colors.green, 'medium': Colors.orange, 'high': Colors.deepOrange, 'urgent': Colors.red}[p])),
          const SizedBox(width: 8),
          Text(p[0].toUpperCase() + p.substring(1), style: TextStyle(fontWeight: p == currentPriority ? FontWeight.bold : FontWeight.normal)),
        ]),
      )).toList(),
    ));
    if (priority == null) return;
    try {
      await ApiService.put('${ApiConstants.admin}/complaints/$complaintId/priority', {'priority': priority});
      _load();
    } catch (e) { /* error */ }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Complaints'), centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilters)],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _complaints.length,
              itemBuilder: (_, i) => _buildCard(_complaints[i]),
            ),
          ),
    );
  }

  void _showFilters() {
    showModalBottomSheet(context: context, builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('Status'),
        Wrap(spacing: 8, children: [null, ...AppConstants.statuses].map((s) => ChoiceChip(
          label: Text(s == null ? 'All' : s[0].toUpperCase() + s.substring(1).replaceAll('_', ' ')),
          selected: _statusFilter == s,
          onSelected: (_) { setState(() => _statusFilter = s); Navigator.pop(context); _load(); },
        )).toList()),
        const SizedBox(height: 12),
        const Text('Category'),
        Wrap(spacing: 8, children: [null, ...AppConstants.categories].map((c) => ChoiceChip(
          label: Text(c == null ? 'All' : '${AppConstants.categoryIcons[c] ?? ''} ${c[0].toUpperCase()}${c.substring(1)}'),
          selected: _categoryFilter == c,
          onSelected: (_) { setState(() => _categoryFilter = c); Navigator.pop(context); _load(); },
        )).toList()),
      ]),
    ));
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final statusColors = {'pending': Colors.orange, 'assigned': Colors.blue, 'in_progress': Colors.indigo, 'resolved': Colors.green, 'closed': Colors.grey};
    final sc = statusColors[c['status']] ?? Colors.grey;
    final cat = c['category'] ?? 'other';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(AppConstants.categoryIcons[cat] ?? '📋', style: const TextStyle(fontSize: 20)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(c['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(c['complaintId'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text((c['status'] ?? '').replaceAll('_', ' '), style: TextStyle(color: sc, fontSize: 11, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 8),
        if (c['submittedBy'] != null) Text('By: ${c['submittedBy']['name']} • ${c['submittedBy']['hostelBlock'] ?? ''} ${c['submittedBy']['roomNumber'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const Divider(height: 20),
        Row(children: [
          if (c['status'] == 'pending') Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.assignment_ind, size: 16),
            label: const Text('Assign', style: TextStyle(fontSize: 13)),
            onPressed: () => _assignComplaint(c['_id']),
          )),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton.icon(
            icon: const Icon(Icons.flag, size: 16),
            label: Text(c['priority'] ?? 'medium', style: const TextStyle(fontSize: 13)),
            onPressed: () => _changePriority(c['_id'], c['priority'] ?? 'medium'),
          )),
        ]),
      ])),
    );
  }
}
