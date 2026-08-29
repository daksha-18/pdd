import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/sentiment_analyzer.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _users = [];
  bool _loading = true;
  final _tabs = ['All', 'Students', 'Staff', 'Admins'];
  final _roles = [null, 'student', 'staff', 'admin'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) _load();
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      String url = '${ApiConstants.admin}/users?limit=50';
      final role = _roles[_tabCtrl.index];
      if (role != null) url += '&role=$role';
      final res = await ApiService.get(url);
      setState(() {
        _users = res['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'staff';
    String spec = 'general';
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setSt) => AlertDialog(
                  title: const Text('Create User'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: passCtrl,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'Password')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: ['staff', 'admin']
                            .map((r) => DropdownMenuItem(
                                value: r,
                                child:
                                    Text(r[0].toUpperCase() + r.substring(1))))
                            .toList(),
                        onChanged: (v) => setSt(() => role = v!)),
                    if (role == 'staff') ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                          initialValue: spec,
                          decoration: const InputDecoration(
                              labelText: 'Specialization'),
                          items: [
                            'general',
                            'electrical',
                            'plumbing',
                            'internet',
                            'cleaning'
                          ]
                              .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(
                                      s[0].toUpperCase() + s.substring(1))))
                              .toList(),
                          onChanged: (v) => setSt(() => spec = v!)),
                    ],
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () async {
                          try {
                            await ApiService.post(
                                '${ApiConstants.admin}/users', {
                              'name': nameCtrl.text,
                              'email': emailCtrl.text,
                              'password': passCtrl.text,
                              'role': role,
                              'specialization': spec
                            });
                            Navigator.pop(ctx);
                            _load();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('User created!'),
                                    backgroundColor: Colors.green));
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('$e'),
                                backgroundColor: Colors.red));
                          }
                        },
                        child: const Text('Create')),
                  ],
                )));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('User Management', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
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
              icon: Icon(Icons.person_add_rounded, color: primary),
              onPressed: _showCreateDialog,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabCtrl,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              color: primary,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  return FadeInUp(
                    delay: Duration(milliseconds: i * 30),
                    child: _buildUserCard(_users[i]),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final roleColors = {
      'student': const Color(0xFF3B82F6),
      'staff': const Color(0xFF10B981),
      'admin': const Color(0xFF6366F1)
    };
    final rc = roleColors[u['role']] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: rc.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              u['name']?[0] ?? '?',
              style: GoogleFonts.outfit(color: rc, fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ),
        title: Text(
          u['name'] ?? '',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              u['email'] ?? '',
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: rc.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    u['role'].toString().toUpperCase(),
                    style: GoogleFonts.outfit(color: rc, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
                if (u['role'] == 'staff') ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (u['specialization'] ?? 'general').toString().toUpperCase(),
                      style: GoogleFonts.inter(color: isDark ? Colors.grey[400] : const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
            if (u['role'] == 'staff') ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _showStaffFeedbackModal(u),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        (u['averageRating'] != null && (u['averageRating'] as num) > 0)
                            ? '${(u['averageRating'] as num).toStringAsFixed(1)} / 5.0 (${u['totalRatingsCount'] ?? 0} reviews)'
                            : 'No ratings yet',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.amber[300] : Colors.amber[900],
                        ),
                      ),
                      Builder(builder: (context) {
                        final double sScore = ((u['averageSentimentScore'] ?? u['avgSentiment'] ?? 0.0) as num).toDouble();
                        if (sScore == 0) return const SizedBox.shrink();
                        final String sLabel = sScore > 0.05 ? 'positive' : (sScore < -0.05 ? 'negative' : 'neutral');
                        final sent = SentimentAnalyzer.analyze('', serverScore: sScore, serverLabel: sLabel);
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: sent.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Icon(sent.icon, color: sent.color, size: 12),
                                const SizedBox(width: 2),
                                Text(
                                  sent.formattedScore,
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: sent.color),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right_rounded, size: 14, color: isDark ? Colors.amber[300] : Colors.amber[900]),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.grey[600] : const Color(0xFF94A3B8)),
          onSelected: (val) {
            if (val == 'feedback') _showStaffFeedbackModal(u);
            if (val == 'approve') _approveUser(u);
            if (val == 'reject') _rejectUser(u);
            if (val == 'deactivate') _deactivateUser(u);
          },
          itemBuilder: (ctx) => [
            if (u['role'] == 'staff')
              const PopupMenuItem(value: 'feedback', child: ListTile(leading: Icon(Icons.star_outline_rounded, color: Colors.amber), title: Text('View Feedback'), dense: true)),
            if (!(u['isApproved'] ?? false)) ...[
              const PopupMenuItem(value: 'approve', child: ListTile(leading: Icon(Icons.check_circle_outline, color: Colors.green), title: Text('Approve'), dense: true)),
              const PopupMenuItem(value: 'reject', child: ListTile(leading: Icon(Icons.cancel_outlined, color: Colors.red), title: Text('Reject'), dense: true)),
            ],
            const PopupMenuItem(value: 'deactivate', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Deactivate'), dense: true)),
          ],
        ),
      ),
    );
  }

  Future<void> _approveUser(Map<String, dynamic> u) async {
    try {
      await ApiService.put('${ApiConstants.admin}/users/${u['_id']}/approve', {});
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User approved!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectUser(Map<String, dynamic> u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: Text('Are you sure you want to reject ${u['name']}? This will permanently delete the application.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reject', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.delete('${ApiConstants.admin}/users/${u['_id']}/reject');
        _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User rejected!'), backgroundColor: Colors.red));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deactivateUser(Map<String, dynamic> u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Deactivation'),
        content: Text('Are you sure you want to deactivate ${u['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Deactivate', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.delete('${ApiConstants.admin}/users/${u['_id']}');
        _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deactivated!'), backgroundColor: Colors.green));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _showStaffFeedbackModal(Map<String, dynamic> staff) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final staffId = (staff['_id'] ?? staff['id'] ?? '').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: FutureBuilder<Map<String, dynamic>>(
            future: ApiService.get('${ApiConstants.admin}/staff/$staffId/feedback'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null || snapshot.data!['success'] == false) {
                final errorText = snapshot.hasError ? snapshot.error.toString() : (snapshot.data?['message'] ?? 'No feedback available');
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, color: Colors.grey[400], size: 48),
                      const SizedBox(height: 12),
                      Text('No feedback available yet', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(
                        errorText.contains('404') || errorText.contains('not found') || errorText.contains('Not found')
                            ? 'No student feedback records found for this staff member.'
                            : errorText,
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              final resData = snapshot.data!['data'] ?? {};
              final staffInfo = resData['staff'] ?? staff;
              final List<dynamic> feedbacks = resData['feedbacks'] ?? [];
              final avgRating = (staffInfo['averageRating'] ?? 0.0).toDouble();
              final totalRatings = staffInfo['totalRatingsCount'] ?? feedbacks.length;

              double avgSentScore = (staffInfo['averageSentimentScore'] ?? 0.0).toDouble();
              if (avgSentScore == 0.0 && feedbacks.isNotEmpty) {
                double sum = 0.0;
                for (var f in feedbacks) {
                  final double s = (f['sentimentScore'] is num) ? (f['sentimentScore'] as num).toDouble() : SentimentAnalyzer.analyze(f['comment'] ?? '').score;
                  sum += s;
                }
                avgSentScore = sum / feedbacks.length;
              }
              final String sLabel = avgSentScore > 0.05 ? 'positive' : (avgSentScore < -0.05 ? 'negative' : 'neutral');
              final totalSentResult = SentimentAnalyzer.analyze('', serverScore: avgSentScore, serverLabel: sLabel);

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey[700] : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(staffInfo['name'] ?? 'Staff Feedback', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Specialization: ${(staffInfo['specialization'] ?? 'general').toString().toUpperCase()}', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.amber.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                              ),
                            ],
                          ),
                        ),
                        if (totalRatings > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: totalSentResult.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: totalSentResult.color.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(totalSentResult.icon, color: totalSentResult.color, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  totalSentResult.formattedScore,
                                  style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: totalSentResult.color),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          Text('$totalRatings', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Total Reviews', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                        ]),
                        Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),
                        Column(children: [
                          Row(
                            children: List.generate(5, (i) => Icon(
                              i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: Colors.amber, size: 14,
                            )),
                          ),
                          const SizedBox(height: 2),
                          Text('Satisfaction Score', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                        ]),
                        if (totalRatings > 0) ...[
                          Container(width: 1, height: 24, color: Colors.grey.withOpacity(0.3)),
                          Column(children: [
                            Text(
                              totalSentResult.formattedScore,
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: totalSentResult.color),
                            ),
                            Text('Total Response Score', style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  Expanded(
                    child: feedbacks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text('No student feedback yet for this staff member', style: GoogleFonts.inter(color: Colors.grey[500])),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(24),
                            itemCount: feedbacks.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) {
                              final fb = feedbacks[i];
                              final ratingVal = fb['rating'] ?? 0;
                              final student = fb['student'] ?? {};
                              final studentName = student['name'] ?? 'Student';
                              final roomInfo = '${student['hostelBlock'] ?? ''} ${student['roomNumber'] ?? ''}'.trim();
                              final comment = fb['comment'] ?? '';

                              final double? sScore = (fb['sentimentScore'] is num) ? (fb['sentimentScore'] as num).toDouble() : null;
                              final String? sLabel = fb['sentimentLabel']?.toString();
                              final sent = SentimentAnalyzer.analyze(comment, serverScore: sScore, serverLabel: sLabel);

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: Colors.blue.withOpacity(0.1),
                                          child: Text(studentName[0].toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.blue)),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(studentName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                                              if (roomInfo.isNotEmpty)
                                                Text(roomInfo, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500])),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(5, (sIdx) => Icon(
                                            sIdx < ratingVal ? Icons.star_rounded : Icons.star_outline_rounded,
                                            color: Colors.amber,
                                            size: 16,
                                          )),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: sent.color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: sent.color.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(sent.icon, color: sent.color, size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Response: ${sent.displayText}',
                                            style: GoogleFonts.inter(color: sent.color, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (comment.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        '"$comment"',
                                        style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: isDark ? Colors.grey[300] : const Color(0xFF334155)),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Complaint: ${fb['complaintId'] ?? ''} • ${fb['title'] ?? ''}',
                                      style: GoogleFonts.inter(fontSize: 11, color: Colors.grey[500]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
