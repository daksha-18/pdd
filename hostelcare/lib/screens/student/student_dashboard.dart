import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final primary = cs.primary;
    final user = auth.user;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => complaints.fetchComplaints(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              stretch: true,
              backgroundColor: primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primary, const Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -50, top: -50,
                        child: Container(
                          width: 200, height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              FadeInDown(
                                child: Text(
                                  'Hello, ${user?.name.split(' ').first ?? 'Student'} 👋',
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              FadeInDown(
                                delay: const Duration(milliseconds: 100),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${user?.hostelBlock ?? ''} • Room ${user?.roomNumber ?? ''}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const NotificationScreen()),
                        ),
                      ),
                    ),
                    if (notif.unreadCount > 0)
                      Positioned(
                        right: 12,
                        top: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            shape: BoxShape.circle,
                            border: Border.all(color: primary, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '${notif.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
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
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Complaints',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          TextButton(
                              onPressed: () {}, child: const Text('See All')),
                        ]),
                  ),
                  if (complaints.isLoading)
                    const Center(child: CircularProgressIndicator()),
                  if (!complaints.isLoading && complaints.complaints.isEmpty)
                    FadeIn(child: _buildEmptyState()),
                  ...complaints.complaints.take(5).toList().asMap().entries.map(
                        (entry) => FadeInUp(
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
    final active = complaints
        .where((c) => c.status == 'in_progress' || c.status == 'assigned')
        .length;
    final resolved = complaints
        .where((c) => c.status == 'resolved' || c.status == 'closed')
        .length;
    return Row(
      children: [
        Expanded(
            child: _statCard('Pending', '$pending', Colors.orange,
                Icons.hourglass_empty_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(
                'Active', '$active', Colors.blue, Icons.engineering_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard('Resolved', '$resolved', Colors.green,
                Icons.check_circle_outline_rounded)),
      ],
    );
  }

  Widget _statCard(String label, String count, Color color, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: isDark ? [
          const BoxShadow(
            color: Colors.transparent,
            blurRadius: 0,
            offset: Offset.zero,
          )
        ] : [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            count,
            style: GoogleFonts.outfit(
              fontSize: 26, 
              fontWeight: FontWeight.bold, 
              color: isDark ? color : const Color(0xFF0F172A)
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12, 
              fontWeight: FontWeight.w600,
              color: isDark ? color.withOpacity(0.8) : const Color(0xFF64748B)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(complaint) {
    final statusColors = {
      'pending': const Color(0xFFF59E0B),
      'assigned': const Color(0xFF3B82F6),
      'in_progress': const Color(0xFF6366F1),
      'resolved': const Color(0xFF10B981),
      'closed': const Color(0xFF64748B)
    };
    final color = statusColors[complaint.status] ?? Colors.grey;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ComplaintDetailScreen(complaintId: complaint.id),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      complaint.categoryIcon,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${complaint.complaintId ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    complaint.statusLabel,
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
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
          Text('No complaints yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Tap the button below to submit your first complaint',
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
