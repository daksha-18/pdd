import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../screens/student/student_home.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passwordCtrl.dispose();
    _phoneCtrl.dispose(); _blockCtrl.dispose(); _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameCtrl.text.trim(), _emailCtrl.text.trim(), _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(), hostelBlock: _blockCtrl.text.trim(), roomNumber: _roomCtrl.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const StudentHome()), (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Registration failed'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInDown(child: Text('Join HostelCare', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                const SizedBox(height: 8),
                FadeInDown(delay: const Duration(milliseconds: 100), child: Text('Create your student account', style: TextStyle(color: Colors.grey[600]))),
                const SizedBox(height: 32),
                ..._buildFields(),
                const SizedBox(height: 32),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Consumer<AuthProvider>(
                    builder: (_, auth, __) => SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: auth.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
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

  List<Widget> _buildFields() {
    final fields = [
      {'ctrl': _nameCtrl, 'label': 'Full Name', 'icon': Icons.person_outline, 'validator': 'Name required', 'delay': 200},
      {'ctrl': _emailCtrl, 'label': 'Email', 'icon': Icons.email_outlined, 'validator': 'Valid email required', 'delay': 250, 'keyboard': TextInputType.emailAddress},
      {'ctrl': _phoneCtrl, 'label': 'Phone Number', 'icon': Icons.phone_outlined, 'validator': null, 'delay': 350, 'keyboard': TextInputType.phone},
      {'ctrl': _blockCtrl, 'label': 'Hostel Block', 'icon': Icons.apartment_outlined, 'validator': 'Hostel block required', 'delay': 400},
      {'ctrl': _roomCtrl, 'label': 'Room Number', 'icon': Icons.meeting_room_outlined, 'validator': 'Room number required', 'delay': 450},
    ];
    final widgets = <Widget>[];
    for (final f in fields) {
      widgets.add(FadeInUp(
        delay: Duration(milliseconds: f['delay'] as int),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            controller: f['ctrl'] as TextEditingController,
            keyboardType: f['keyboard'] as TextInputType? ?? TextInputType.text,
            decoration: InputDecoration(labelText: f['label'] as String, prefixIcon: Icon(f['icon'] as IconData)),
            validator: f['validator'] != null ? (v) => v == null || v.isEmpty ? f['validator'] as String : null : null,
          ),
        ),
      ));
    }
    // Password field
    widgets.add(FadeInUp(
      delay: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: _passwordCtrl, obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password', prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscure = !_obscure)),
          ),
          validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
        ),
      ),
    ));
    return widgets;
  }
}
