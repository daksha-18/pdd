import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../providers/notification_provider.dart';
import '../../utils/constants.dart';
import '../common/notification_screen.dart';
import 'complaint_detail_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<ComplaintProvider>().fetchComplaints());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final complaints = context.watch<ComplaintProvider>();
    final notif = context.watch<NotificationProvider>();
    final cs = Theme.of(context).colorScheme;
    final user = auth.user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => complaints.fetchComplaints(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 180, pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Hello, ${user?.name?.split(' ').first ?? 'Student'} 👋', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('${user?.hostelBlock ?? ''} • Room ${user?.roomNumber ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Stack(
                  children: [
                    IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()))),
                    if (notif.unreadCount > 0) Positioned(right: 8, top: 8, child: Container(width: 18, height: 18, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Center(child: Text('${notif.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))))),
                  ],
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Cards
                  FadeInUp(child: _buildStatsRow(complaints.complaints)),
                  const SizedBox(height: 24),
                  // Recent Complaints
                  FadeInUp(
                    delay: const Duration(milliseconds: 200),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Recent Complaints', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      TextButton(onPressed: () {}, child: const Text('See All')),
                    ]),
                  ),
                  if (complaints.isLoading) const Center(child: CircularProgressIndicator()),
                  if (!complaints.isLoading && complaints.complaints.isEmpty)
                    FadeIn(child: _buildEmptyState()),
                  ...complaints.complaints.take(5).toList().asMap().entries.map((entry) =>
                    FadeInUp(
                      delay: Duration(milliseconds: 300 + entry.key * 100),
                      child: _buildComplaintCard(entry.value),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(List complaints) {
    final pending = complaints.where((c) => c.status == 'pending').length;
    final active = complaints.where((c) => c.status == 'in_progress' || c.status == 'assigned').length;
    final resolved = complaints.where((c) => c.status == 'resolved' || c.status == 'closed').length;
    return Row(
      children: [
        Expanded(child: _statCard('Pending', '$pending', Colors.orange, Icons.hourglass_empty_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Active', '$active', Colors.blue, Icons.engineering_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Resolved', '$resolved', Colors.green, Icons.check_circle_outline_rounded)),
      ],
    );
  }

  Widget _statCard(String label, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(complaint) {
    final statusColors = {'pending': Colors.orange, 'assigned': Colors.blue, 'in_progress': Colors.indigo, 'resolved': Colors.green, 'closed': Colors.grey};
    final color = statusColors[complaint.status] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: complaint.id))),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(complaint.categoryIcon, style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(complaint.title, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(complaint.complaintId ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(complaint.statusLabel, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No complaints yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Tap the button below to submit your first complaint', style: TextStyle(color: Colors.grey[400]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
