import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final themeData = Theme.of(context);
    final cs = themeData.colorScheme;
    final primary = cs.primary;
    final isDark = themeData.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: themeData.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            FadeInDown(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, const Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(
                          user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                          style: GoogleFonts.outfit(
                            fontSize: 40,
                            color: primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      user?.name ?? '',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        (user?.role ?? 'student').toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _buildSection(context, [
                _infoTile(Icons.apartment_rounded, 'Hostel Block', (user?.hostelBlock != null && user!.hostelBlock!.isNotEmpty) ? user.hostelBlock! : 'Not set', isDark),
                const Divider(indent: 56, height: 1),
                _infoTile(Icons.meeting_room_rounded, 'Room Number', (user?.roomNumber != null && user!.roomNumber!.isNotEmpty) ? user.roomNumber! : 'Not set', isDark),
                const Divider(indent: 56, height: 1),
                _infoTile(Icons.phone_iphone_rounded, 'Phone', (user?.phone != null && user!.phone!.isNotEmpty) ? user.phone! : 'Not set', isDark),
              ], isDark),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: _buildSection(context, [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: primary, size: 20),
                  ),
                  title: Text('Dark Mode', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  trailing: Switch.adaptive(
                    value: theme.isDark,
                    activeTrackColor: primary,
                    onChanged: (_) => theme.toggleTheme(),
                  ),
                ),
              ], isDark),
            ),
            const SizedBox(height: 24),
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              child: _buildSection(context, [
                _actionTile(Icons.edit_note_rounded, 'Edit Profile', () => _showEditProfile(context), primary, isDark),
                const Divider(indent: 56, height: 1),
                _actionTile(Icons.lock_reset_rounded, 'Change Password', () => _showChangePassword(context), primary, isDark),
              ], isDark),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout_rounded),
                  label: Text('Sign Out', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    foregroundColor: Colors.red,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 40),
            FadeIn(
              delay: const Duration(milliseconds: 700),
              child: Column(
                children: [
                  Text(
                    'HostelCare+ Connected Community',
                    style: GoogleFonts.outfit(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'v1.2.0 • Build with ❤️',
                    style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoTile(IconData icon, String title, String value, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isDark ? Colors.indigo[300] : const Color(0xFF6366F1))?.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? Colors.indigo[300] : const Color(0xFF6366F1), size: 20),
      ),
      title: Text(title, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B), fontWeight: FontWeight.w500)),
      subtitle: Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A))),
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap, Color primary, bool isDark) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primary, size: 20),
      ),
      title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.chevron_right_rounded, color: isDark ? Colors.grey[600] : const Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  void _showEditProfile(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final nameCtrl = TextEditingController(text: auth.user?.name);
    final phoneCtrl = TextEditingController(text: auth.user?.phone);
    final blockCtrl = TextEditingController(text: auth.user?.hostelBlock);
    final roomCtrl = TextEditingController(text: auth.user?.roomNumber);

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Edit Profile',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: blockCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Hostel Block')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: roomCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Room Number')),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        await auth.updateProfile(
                            name: nameCtrl.text,
                            phone: phoneCtrl.text,
                            hostelBlock: blockCtrl.text,
                            roomNumber: roomCtrl.text);
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

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) => Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Change Password',
                        style: Theme.of(ctx)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(
                        controller: currentCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                            labelText: 'Current Password')),
                    const SizedBox(height: 12),
                    TextField(
                        controller: newCtrl,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'New Password')),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Update Password')),
                  ]),
            ));
  }
}
