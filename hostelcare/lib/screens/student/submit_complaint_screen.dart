import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:animate_do/animate_do.dart';
import '../../providers/auth_provider.dart';
import '../../providers/complaint_provider.dart';
import '../../utils/constants.dart';

class SubmitComplaintScreen extends StatefulWidget {
  final String? prefilledBlock;
  final String? prefilledRoom;
  final bool qrScanned;
  const SubmitComplaintScreen(
      {super.key,
      this.prefilledBlock,
      this.prefilledRoom,
      this.qrScanned = false});
  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _blockCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  String _category = 'electrical';
  String _priority = 'medium';
  bool _isCommonArea = false;
  final List<XFile> _images = [];

  String _deriveFloorFromRoom(String room) {
    final clean = room.trim();
    if (clean.isEmpty) return '';
    final match = RegExp(r'\d+').firstMatch(clean);
    if (match == null) return '';
    final numStr = match.group(0)!;
    final num = int.tryParse(numStr);
    if (num == null) return '';

    int floorNum;
    if (numStr.length >= 3) {
      floorNum = num ~/ 100;
    } else {
      floorNum = 0;
    }

    if (floorNum == 0) return 'Ground';
    if (floorNum == 1) return '1st';
    if (floorNum == 2) return '2nd';
    if (floorNum == 3) return '3rd';
    return '${floorNum}th';
  }

  void _onRoomChanged() {
    final derived = _deriveFloorFromRoom(_roomCtrl.text);
    if (derived.isNotEmpty) {
      _floorCtrl.text = derived;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _blockCtrl.text = widget.prefilledBlock ?? user?.hostelBlock ?? '';
    _roomCtrl.text = widget.prefilledRoom ?? user?.roomNumber ?? '';
    _floorCtrl.text = _deriveFloorFromRoom(_roomCtrl.text);
    _roomCtrl.addListener(_onRoomChanged);
  }

  @override
  void dispose() {
    _roomCtrl.removeListener(_onRoomChanged);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _blockCtrl.dispose();
    _roomCtrl.dispose();
    _floorCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Max 3 images')));
      return;
    }
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (_) => SafeArea(
              child: Wrap(children: [
                ListTile(
                    leading: const Icon(Icons.camera_alt),
                    title: const Text('Camera'),
                    onTap: () => Navigator.pop(context, ImageSource.camera)),
                ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Gallery'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery)),
              ]),
            ));
    if (source == null) return;
    final picked = await picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1024);
    if (picked != null) setState(() => _images.add(picked));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ComplaintProvider>();
    final success = await provider.submitComplaint(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      hostelBlock: _blockCtrl.text.trim(),
      roomNumber: _roomCtrl.text.trim(),
      floor: _floorCtrl.text.trim(),
      priority: _priority,
      images: _images.isNotEmpty ? _images : null,
      qrScanned: widget.qrScanned,
      isCommonArea: _isCommonArea,
    );
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Complaint submitted!'),
          backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(provider.error ?? 'Failed'),
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
        title: Text('Submit Complaint', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeInDown(child: _buildCategorySelector()),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 100),
                child: TextFormField(
                  controller: _titleCtrl,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: GoogleFonts.outfit(),
                    hintText: 'What is the issue?',
                    prefixIcon: Icon(Icons.title_rounded, color: primary),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Please enter a title' : null,
                ),
              ),
              const SizedBox(height: 16),
              FadeInUp(
                delay: const Duration(milliseconds: 150),
                child: TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    labelText: 'Description',
                    labelStyle: GoogleFonts.outfit(),
                    hintText: 'Describe the problem in detail...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.description_rounded, color: primary),
                    ),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Please provide details' : null,
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 180),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isCommonArea
                        ? primary.withOpacity(0.1)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isCommonArea ? primary : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: SwitchListTile(
                    activeColor: primary,
                    value: _isCommonArea,
                    onChanged: (val) => setState(() => _isCommonArea = val),
                    title: Text(
                      'Common Area Issue',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    subtitle: Text(
                      'e.g. WiFi, Washroom, Mess, Corridor (Allow others to Upvote)',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                    ),
                    secondary: Icon(Icons.people_outline_rounded, color: _isCommonArea ? primary : Colors.grey[500]),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: _buildPrioritySelector(),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, size: 18, color: primary),
                          const SizedBox(width: 8),
                          Text('Location Details', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _blockCtrl,
                              decoration: InputDecoration(
                                labelText: 'Block',
                                hintText: 'A / B / C',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Req' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _roomCtrl,
                              decoration: InputDecoration(
                                labelText: 'Room',
                                hintText: '101',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Req' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _floorCtrl,
                              decoration: InputDecoration(
                                labelText: 'Floor',
                                hintText: '2nd',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 300),
                child: _buildImagePicker(),
              ),
              const SizedBox(height: 40),
              FadeInUp(
                delay: const Duration(milliseconds: 400),
                child: Consumer<ComplaintProvider>(
                  builder: (_, p, __) => Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: p.isLoading ? null : _submit,
                      icon: p.isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send_rounded, size: 20),
                      label: Text(
                        p.isLoading ? 'SUBMITTING...' : 'SUBMIT COMPLAINT',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    const cats = AppConstants.categories;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Category',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cats.map((c) {
            final selected = c == _category;
            return ChoiceChip(
              label: Text(
                  '${AppConstants.categoryIcons[c] ?? ''} ${c[0].toUpperCase()}${c.substring(1)}'),
              selected: selected,
              onSelected: (_) => setState(() => _category = c),
              selectedColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
            );
          }).toList()),
    ]);
  }

  Widget _buildPrioritySelector() {
    final colors = {
      'low': Colors.green,
      'medium': Colors.orange,
      'high': Colors.deepOrange,
      'urgent': Colors.red
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Priority',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(
          children: AppConstants.priorities.map((p) {
        final selected = p == _priority;
        final color = colors[p]!;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priority = p),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: selected ? color : Colors.grey.withOpacity(0.3)),
              ),
              child: Center(
                  child: Text(p[0].toUpperCase() + p.substring(1),
                      style: TextStyle(
                          color: selected ? color : Colors.grey,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 12))),
            ),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildImagePicker() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Attach Photos (${_images.length}/3)',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      SizedBox(
        height: 100,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          ..._images.asMap().entries.map((e) => Stack(children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.3))),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.network(e.value.path, fit: BoxFit.cover)
                        : Image.file(File(e.value.path), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                    top: 4,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(e.key)),
                      child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white)),
                    )),
              ])),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      style: BorderStyle.solid)),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: Colors.grey[400]),
                    const SizedBox(height: 4),
                    Text('Add',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12))
                  ]),
            ),
          ),
        ]),
      ),
    ]);
  }
}
