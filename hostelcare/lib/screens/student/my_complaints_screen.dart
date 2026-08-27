import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import 'complaint_detail_screen.dart';

class MyComplaintsScreen extends StatefulWidget {
  const MyComplaintsScreen({super.key});
  @override
  State<MyComplaintsScreen> createState() => _MyComplaintsScreenState();
}

class _MyComplaintsScreenState extends State<MyComplaintsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _tabs = ['All', 'Campus Issues 🌐', 'Pending', 'Assigned', 'Resolved'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _load();
    });
    Future.microtask(() => _load());
  }

  void _load() {
    final idx = _tabCtrl.index;
    if (idx == 1) {
      context.read<ComplaintProvider>().fetchComplaints(isCommonArea: true);
    } else {
      final statusFilter = idx == 0 ? null : (idx == 2 ? 'pending' : (idx == 3 ? 'assigned' : 'resolved'));
      context.read<ComplaintProvider>().fetchComplaints(status: statusFilter);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Complaints & Issues', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            indicatorColor: primary,
            indicatorWeight: 3,
            labelColor: primary,
            unselectedLabelColor: isDark ? Colors.grey[500] : const Color(0xFF64748B),
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
      ),
      body: Consumer<ComplaintProvider>(
        builder: (_, provider, __) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.complaints.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeInDown(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.inbox_rounded, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeInUp(
                    child: Text(
                      'No complaints found',
                      style: GoogleFonts.outfit(color: isDark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FadeInUp(
                    delay: const Duration(milliseconds: 100),
                    child: Text(
                      'Any issues you report or upvote will appear here.',
                      style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _load(),
            color: primary,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: provider.complaints.length,
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: i * 50),
                child: _buildCard(provider.complaints[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(dynamic complaint) {
    final statusColors = {
      'pending': const Color(0xFFF59E0B),
      'assigned': const Color(0xFF3B82F6),
      'in_progress': const Color(0xFF6366F1),
      'resolved': const Color(0xFF10B981),
      'closed': const Color(0xFF64748B),
      'withdrawn': const Color(0xFF94A3B8),
    };
    final priorityColors = {
      'low': const Color(0xFF10B981),
      'medium': const Color(0xFFF59E0B),
      'high': const Color(0xFFF97316),
      'urgent': const Color(0xFFEF4444)
    };
    final sc = statusColors[complaint.status] ?? Colors.grey;
    final pc = priorityColors[complaint.priority] ?? Colors.grey;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final currentUser = context.watch<AuthProvider>().user;
    final isUpvoted = currentUser != null && complaint.isUpvotedByMe(currentUser.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ComplaintDetailScreen(complaintId: complaint.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(complaint.categoryIcon, style: const TextStyle(fontSize: 24)),
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              complaint.complaintId ?? '',
                              style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            if (complaint.isCommonArea) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Common Area',
                                  style: GoogleFonts.inter(fontSize: 10, color: primary, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _chip(complaint.statusLabel, sc),
                  const SizedBox(width: 8),
                  _chip(complaint.priority[0].toUpperCase() + complaint.priority.substring(1), pc),
                  const Spacer(),
                  if (complaint.isCommonArea && !['closed', 'rejected'].contains(complaint.status)) ...[
                    InkWell(
                      onTap: () async {
                        await context.read<ComplaintProvider>().toggleUpvote(complaint.id);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isUpvoted ? primary : primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUpvoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                              size: 14,
                              color: isUpvoted ? Colors.white : primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${complaint.upvoteCount}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isUpvoted ? Colors.white : primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.grey[600] : const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
