import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/sentiment_analyzer.dart';

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
          final avgRating = (s['averageRating'] ?? 0.0).toDouble();
          final totalCount = s['totalRatingsCount'] ?? 0;
          final ratingText = avgRating > 0 ? '⭐ ${avgRating.toStringAsFixed(1)} ($totalCount)' : '⭐ New';
          return ListTile(
            leading: CircleAvatar(child: Text(s['name'][0])),
            title: Text(s['name']), subtitle: Text('${(s['specialization'] ?? 'staff').toString().toUpperCase()} • Active: ${s['activeAssignments']} • $ratingText'),
            onTap: () => Navigator.pop(ctx, s['_id'] ?? s['id']),
          );
        },
      )),
    ));
    if (staffId == null) return;
    try {
      await ApiService.put('${ApiConstants.admin}/complaints/$complaintId/assign', {'staffId': staffId});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assigned!'), backgroundColor: Colors.green));
      _load();
    } catch (e) {
      if (!mounted) return;
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('All Complaints', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.filter_list_rounded, color: theme.colorScheme.primary),
              onPressed: _showFilters,
            ),
          ),
        ],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            color: theme.colorScheme.primary,
            child: ListView.builder(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _complaints.length,
              itemBuilder: (_, i) => FadeInUp(
                delay: Duration(milliseconds: i * 50),
                child: _buildCard(_complaints[i]),
              ),
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
    final statusColors = {
      'pending': const Color(0xFFF59E0B),
      'assigned': const Color(0xFF3B82F6),
      'in_progress': const Color(0xFF6366F1),
      'resolved': const Color(0xFF10B981),
      'closed': const Color(0xFF64748B),
      'withdrawn': const Color(0xFF94A3B8),
    };
    final sc = statusColors[c['status']] ?? Colors.grey;
    final cat = c['category'] ?? 'other';
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
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(AppConstants.categoryIcons[cat] ?? '📋', style: const TextStyle(fontSize: 24)),
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
                        c['complaintId'] ?? '',
                        style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (c['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.outfit(color: sc, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (c['submittedBy'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline_rounded, size: 14, color: isDark ? Colors.grey[400] : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      '${c['submittedBy']['name']} • ${c['submittedBy']['hostelBlock'] ?? ''} ${c['submittedBy']['roomNumber'] ?? ''}',
                      style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.grey[400] : const Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            if (c['assignedTo'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.indigo.withOpacity(0.15) : const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? Colors.indigo.withOpacity(0.3) : const Color(0xFFC7D2FE)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.engineering_rounded, size: 14, color: isDark ? Colors.indigo[300] : const Color(0xFF4F46E5)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Assigned Staff: ${c['assignedTo']['name']} (${(c['assignedTo']['specialization'] ?? 'Staff').toString().toUpperCase()})',
                        style: GoogleFonts.inter(fontSize: 12, color: isDark ? Colors.indigo[200] : const Color(0xFF4338CA), fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (c['assignedTo']['averageRating'] != null && (c['assignedTo']['averageRating'] as num) > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text('${(c['assignedTo']['averageRating'] as num).toStringAsFixed(1)}', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber[900])),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (c['feedback'] != null && c['feedback']['rating'] != null) ...[
              const SizedBox(height: 8),
              Builder(builder: (context) {
                final fb = c['feedback'];
                final double? sScore = (fb['sentimentScore'] is num) ? (fb['sentimentScore'] as num).toDouble() : null;
                final String? sLabel = fb['sentimentLabel']?.toString();
                final int? rRating = (fb['rating'] is num) ? (fb['rating'] as num).toInt() : null;
                final sent = SentimentAnalyzer.analyze(fb['comment']?.toString() ?? '', serverScore: sScore, serverLabel: sLabel);

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(isDark ? 0.15 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Student Feedback Score: ${fb['rating']}/5',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.amber[300] : Colors.amber[900]),
                          ),
                          const Spacer(),
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < (fb['rating'] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber, size: 14,
                            )),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sent.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: sent.color.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(sent.icon, color: sent.color, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Text Response: ${sent.displayText}',
                              style: GoogleFonts.inter(color: sent.color, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      if (fb['comment'] != null && (fb['comment'] as String).trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          '"${fb['comment']}"',
                          style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: isDark ? Colors.grey[300] : const Color(0xFF334155)),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(c['assignedTo'] != null ? Icons.swap_horiz_rounded : Icons.assignment_ind_rounded, size: 18),
                    label: Text(c['assignedTo'] != null ? 'Reassign' : 'Assign Staff', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    onPressed: () => _assignComplaint(c['_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c['assignedTo'] != null ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)) : const Color(0xFF6366F1),
                      foregroundColor: c['assignedTo'] != null ? (isDark ? Colors.white : const Color(0xFF334155)) : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.flag_rounded, size: 18, color: {'low': Colors.green, 'medium': Colors.orange, 'high': Colors.deepOrange, 'urgent': Colors.red}[c['priority']] ?? Colors.grey),
                    label: Text((c['priority'] ?? 'medium').toString().toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.grey[300] : const Color(0xFF334155))),
                    onPressed: () => _changePriority(c['_id'], c['priority'] ?? 'medium'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0)),
                    ),
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
