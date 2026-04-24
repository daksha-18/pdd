import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/constants.dart';
import 'complaint_detail_screen.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});
  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['All', 'Pending', 'Assigned', 'In Progress', 'Resolved'];
  final _filters = [null, 'pending', 'assigned', 'in_progress', 'resolved'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) _load(); });
    Future.microtask(() => _load());
  }

  void _load() {
    context.read<ComplaintProvider>().fetchComplaints(status: _filters[_tabCtrl.index]);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Complaints'),
        centerTitle: true,
        bottom: TabBar(controller: _tabCtrl, isScrollable: true, tabs: _tabs.map((t) => Tab(text: t)).toList()),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.complaints.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text('No complaints found', style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchComplaints(status: _filters[_tabCtrl.index]),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.complaints.length,
              itemBuilder: (_, i) => _buildCard(provider.complaints[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(complaint) {
    final statusColors = {'pending': Colors.orange, 'assigned': Colors.blue, 'in_progress': Colors.indigo, 'resolved': Colors.green, 'closed': Colors.grey};
    final priorityColors = {'low': Colors.green, 'medium': Colors.orange, 'high': Colors.deepOrange, 'urgent': Colors.red};
    final sc = statusColors[complaint.status] ?? Colors.grey;
    final pc = priorityColors[complaint.priority] ?? Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: complaint.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(complaint.categoryIcon, style: const TextStyle(fontSize: 22)))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(complaint.complaintId ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _chip(complaint.statusLabel, sc),
              const SizedBox(width: 8),
              _chip(complaint.priority[0].toUpperCase() + complaint.priority.substring(1), pc),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
