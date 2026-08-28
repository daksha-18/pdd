import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
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
        files: images,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Images uploaded!'), backgroundColor: Colors.green));
      _load();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            stretch: true,
            backgroundColor: primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, const Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20, top: -20,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FadeInDown(
                              child: Text(
                                'My Assignments',
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_assignments.length} tasks assigned to you',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabCtrl,
                  onTap: (_) => _load(),
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w500),
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
            ),
          ),
          _loading
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            : _assignments.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_turned_in_rounded, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No assignments found',
                          style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'You are all caught up!',
                          style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => FadeInUp(
                        delay: Duration(milliseconds: i * 50),
                        child: _buildCard(_assignments[i]),
                      ),
                      childCount: _assignments.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final statusColors = {
      'assigned': const Color(0xFF3B82F6),
      'in_progress': const Color(0xFF6366F1),
      'resolved': const Color(0xFF10B981),
      'closed': const Color(0xFF10B981)
    };
    final priorityColors = {
      'low': const Color(0xFF10B981),
      'medium': const Color(0xFFF59E0B),
      'high': const Color(0xFFEF4444),
      'urgent': const Color(0xFF7F1D1D)
    };
    
    final sc = statusColors[c['status']] ?? Colors.grey;
    final pc = priorityColors[c['priority']] ?? Colors.grey;
    final cat = c['category'] ?? 'other';
    final student = c['submittedBy'] as Map<String, dynamic>?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(AppConstants.categoryIcons[cat] ?? '📋', style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c['title'] ?? '',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${c['complaintId'] ?? ''}',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (c['priority'] ?? '').toString().toUpperCase(),
                    style: GoogleFonts.outfit(color: pc, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              c['description'] ?? '',
              style: GoogleFonts.inter(
                color: isDark ? Colors.grey[400] : const Color(0xFF475569),
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (student != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_pin_rounded, size: 16, color: isDark ? Colors.indigo[300] : const Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${student['name']} • ${student['hostelBlock'] ?? ''} ${student['roomNumber'] ?? ''}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (c['status'] == 'assigned') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text('Start Working', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      onPressed: () => _updateStatus(c['_id'], 'in_progress'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (c['status'] == 'in_progress') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: Text('Mark Resolved', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                      onPressed: () => _updateStatus(c['_id'], 'resolved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.camera_enhance_rounded, color: isDark ? Colors.indigo[300] : const Color(0xFF6366F1)),
                    onPressed: () => _uploadCompletionImages(c['_id']),
                    tooltip: 'Upload Photos',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
