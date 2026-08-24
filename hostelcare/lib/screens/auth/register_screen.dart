import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';

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
  String _selectedRole = 'student'; // 'student' or 'staff'
  String _selectedSpecialization = 'general';

  final List<String> _specializations = [
    'electrical',
    'plumbing',
    'internet',
    'cleaning',
    'general'
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _phoneCtrl.dispose();
    _blockCtrl.dispose();
    _roomCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      phone: _phoneCtrl.text.trim(),
      hostelBlock: _selectedRole == 'student' ? _blockCtrl.text.trim() : '',
      roomNumber: _selectedRole == 'student' ? _roomCtrl.text.trim() : '',
      role: _selectedRole,
      specialization:
          _selectedRole == 'staff' ? _selectedSpecialization : 'general',
    );
    if (!mounted) return;
    if (success) {
      // Show success message and go back to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Registration successful! Please wait for admin approval.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(auth.error ?? 'Registration failed'),
          backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Create Account', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FadeInDown(
                  child: Text(
                    'Join HostelCare+',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FadeInDown(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'Fill in your details to get started',
                    style: GoogleFonts.inter(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 32),

                // Role Toggle
                FadeInDown(
                  delay: const Duration(milliseconds: 150),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildRoleTab('student', 'Student', Icons.school_rounded)),
                        Expanded(child: _buildRoleTab('staff', 'Staff', Icons.engineering_rounded)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                ..._buildFields(),

                if (_selectedRole == 'staff') ...[
                  const SizedBox(height: 16),
                  FadeInUp(
                    delay: const Duration(milliseconds: 500),
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedSpecialization,
                      decoration: const InputDecoration(
                        labelText: 'Staff Specialization',
                        prefixIcon: Icon(Icons.build_outlined),
                      ),
                      items: _specializations
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s[0].toUpperCase() + s.substring(1))))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedSpecialization = val!),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
                FadeInUp(
                  delay: const Duration(milliseconds: 600),
                  child: Consumer<AuthProvider>(
                    builder: (_, auth, __) => SizedBox(
                      height: 60,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text('Create Account',
                                style: GoogleFonts.outfit(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeInUp(
                  delay: const Duration(milliseconds: 700),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account? ", style: GoogleFonts.inter(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign In', 
                          style: GoogleFonts.outfit(color: primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTab(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected && !isDark ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : [
            const BoxShadow(
              color: Colors.transparent,
              blurRadius: 0,
              offset: Offset.zero,
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? primary : (isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? primary : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    final isStudent = _selectedRole == 'student';
    final fields = [
      {
        'ctrl': _nameCtrl,
        'label': 'Full Name',
        'icon': Icons.person_outline,
        'validator': 'Name required',
        'delay': 200
      },
      {
        'ctrl': _emailCtrl,
        'label': 'Email Address',
        'icon': Icons.email_outlined,
        'validator': 'Valid email required',
        'delay': 250,
        'keyboard': TextInputType.emailAddress
      },
      {
        'ctrl': _phoneCtrl,
        'label': 'Phone Number',
        'icon': Icons.phone_outlined,
        'validator': null,
        'delay': 300,
        'keyboard': TextInputType.phone
      },
      if (isStudent) ...[
        {
          'ctrl': _blockCtrl,
          'label': 'Hostel Block',
          'icon': Icons.apartment_outlined,
          'validator': 'Block required',
          'delay': 350
        },
        {
          'ctrl': _roomCtrl,
          'label': 'Room Number',
          'icon': Icons.meeting_room_outlined,
          'validator': 'Room required',
          'delay': 400
        },
      ],
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
            decoration: InputDecoration(
                labelText: f['label'] as String,
                prefixIcon: Icon(f['icon'] as IconData)),
            validator: f['validator'] != null
                ? (v) =>
                    v == null || v.isEmpty ? f['validator'] as String : null
                : null,
          ),
        ),
      ));
    }

    // Password field
    widgets.add(FadeInUp(
      delay: const Duration(milliseconds: 450),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          controller: _passwordCtrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure)),
          ),
          validator: (v) =>
              v == null || v.length < 6 ? 'Min 6 characters' : null,
        ),
      ),
    ));

    return widgets;
  }
}
