import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  List<dynamic> _users = [];
  bool _loading = true;
  final _tabs = ['All', 'Students', 'Staff', 'Admins'];
  final _roles = [null, 'student', 'staff', 'admin'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) _load(); });
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      String url = '${ApiConstants.admin}/users?limit=50';
      final role = _roles[_tabCtrl.index];
      if (role != null) url += '&role=$role';
      final res = await ApiService.get(url);
      setState(() { _users = res['data'] ?? []; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'staff';
    String spec = 'general';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => AlertDialog(
      title: const Text('Create User'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 8),
        TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 8),
        TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(value: role, decoration: const InputDecoration(labelText: 'Role'),
          items: ['staff', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r[0].toUpperCase() + r.substring(1)))).toList(),
          onChanged: (v) => setSt(() => role = v!)),
        if (role == 'staff') ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(value: spec, decoration: const InputDecoration(labelText: 'Specialization'),
            items: ['general', 'electrical', 'plumbing', 'internet', 'cleaning'].map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
            onChanged: (v) => setSt(() => spec = v!)),
        ],
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          try {
            await ApiService.post('${ApiConstants.admin}/users', {'name': nameCtrl.text, 'email': emailCtrl.text, 'password': passCtrl.text, 'role': role, 'specialization': spec});
            Navigator.pop(ctx);
            _load();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User created!'), backgroundColor: Colors.green));
          } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: Colors.red)); }
        }, child: const Text('Create')),
      ],
    )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'), centerTitle: true,
        bottom: TabBar(controller: _tabCtrl, tabs: _tabs.map((t) => Tab(text: t)).toList()),
        actions: [IconButton(icon: const Icon(Icons.person_add), onPressed: _showCreateDialog)],
      ),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _users.length,
              itemBuilder: (_, i) {
                final u = _users[i];
                final roleColors = {'student': Colors.blue, 'staff': Colors.green, 'admin': Colors.purple};
                final rc = roleColors[u['role']] ?? Colors.grey;
                return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                  leading: CircleAvatar(backgroundColor: rc.withOpacity(0.15), child: Text(u['name']?[0] ?? '?', style: TextStyle(color: rc, fontWeight: FontWeight.bold))),
                  title: Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${u['email']} • ${u['role']}'),
                  trailing: Switch(value: u['isActive'] ?? true, onChanged: (v) async {
                    await ApiService.put('${ApiConstants.admin}/users/${u['_id']}', {'isActive': v});
                    _load();
                  }),
                ));
              },
            ),
          ),
    );
  }
}
