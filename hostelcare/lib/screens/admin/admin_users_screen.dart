import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

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
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('User created!'),
                                    backgroundColor: Colors.green));
                          } catch (e) {
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
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.grey[600] : const Color(0xFF94A3B8)),
          onSelected: (val) {
            if (val == 'approve') _approveUser(u);
            if (val == 'reject') _rejectUser(u);
            if (val == 'deactivate') _deactivateUser(u);
          },
          itemBuilder: (ctx) => [
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User approved!'), backgroundColor: Colors.green));
    } catch (e) {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User rejected!'), backgroundColor: Colors.red));
      } catch (e) {
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User deactivated!'), backgroundColor: Colors.green));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red));
      }
    }
  }
}
