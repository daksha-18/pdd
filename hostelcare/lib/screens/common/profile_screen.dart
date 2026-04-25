import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final user = auth.user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          FadeInDown(child: Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              CircleAvatar(radius: 40, backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(user?.name?.isNotEmpty == true ? user!.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold))),
              const SizedBox(height: 12),
              Text(user?.name ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text((user?.role ?? 'student').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 1)),
              ),
            ]),
          )),
          const SizedBox(height: 20),
          FadeInUp(delay: const Duration(milliseconds: 200), child: _buildSection(context, [
            _infoTile(Icons.apartment, 'Hostel Block', user?.hostelBlock ?? 'Not set'),
            _infoTile(Icons.meeting_room, 'Room Number', user?.roomNumber ?? 'Not set'),
            _infoTile(Icons.phone, 'Phone', user?.phone ?? 'Not set'),
          ])),
          const SizedBox(height: 16),
          FadeInUp(delay: const Duration(milliseconds: 400), child: _buildSection(context, [
            ListTile(
              leading: Icon(theme.isDark ? Icons.dark_mode : Icons.light_mode, color: cs.primary),
              title: const Text('Dark Mode'),
              trailing: Switch(value: theme.isDark, onChanged: (_) => theme.toggleTheme()),
            ),
          ])),
          const SizedBox(height: 16),
          FadeInUp(delay: const Duration(milliseconds: 500), child: _buildSection(context, [
            _actionTile(Icons.edit, 'Edit Profile', () => _showEditProfile(context)),
            _actionTile(Icons.lock_outline, 'Change Password', () => _showChangePassword(context)),
          ])),
          const SizedBox(height: 16),
          FadeInUp(delay: const Duration(milliseconds: 600), child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              },
            ),
          )),
          const SizedBox(height: 20),
          FadeIn(delay: const Duration(milliseconds: 700), child: Text('HostelCare+ v1.0.0', style: TextStyle(color: Colors.grey[400], fontSize: 12))),
        ]),
      ),
    );
  }

  Widget _buildSection(BuildContext context, List<Widget> children) {
    return Card(child: Column(children: children));
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return ListTile(leading: Icon(icon), title: Text(title, style: const TextStyle(fontSize: 13)), subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)));
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap);
  }

  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final nameCtrl = TextEditingController(text: auth.user?.name);
    final phoneCtrl = TextEditingController(text: auth.user?.phone);
    final blockCtrl = TextEditingController(text: auth.user?.hostelBlock);
    final roomCtrl = TextEditingController(text: auth.user?.roomNumber);

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Edit Profile', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
        const SizedBox(height: 12),
        TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
        const SizedBox(height: 12),
        TextField(controller: blockCtrl, decoration: const InputDecoration(labelText: 'Hostel Block')),
        const SizedBox(height: 12),
        TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room Number')),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await auth.updateProfile(name: nameCtrl.text, phone: phoneCtrl.text, hostelBlock: blockCtrl.text, roomNumber: roomCtrl.text);
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: const Text('Save Changes'),
        ),
      ]),
    ));
  }

  void _showChangePassword(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Change Password', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        TextField(controller: currentCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Current Password')),
        const SizedBox(height: 12),
        TextField(controller: newCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password')),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Update Password')),
      ]),
    ));
  }
}
