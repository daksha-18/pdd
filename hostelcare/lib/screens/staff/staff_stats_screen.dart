import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class StaffStatsScreen extends StatefulWidget {
  const StaffStatsScreen({super.key});
  @override
  State<StaffStatsScreen> createState() => _StaffStatsScreenState();
}

class _StaffStatsScreenState extends State<StaffStatsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('${ApiConstants.staff}/stats');
      setState(() { _stats = res['data']; _loading = false; });
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My Performance'), centerTitle: true),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                FadeInDown(child: Container(
                  width: double.infinity, padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.7)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [
                    const Icon(Icons.emoji_events_rounded, size: 48, color: Colors.white),
                    const SizedBox(height: 12),
                    Text('${_stats?['total'] ?? 0}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Total Tasks', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
                  ]),
                )),
                const SizedBox(height: 20),
                FadeInUp(delay: const Duration(milliseconds: 200), child: Row(children: [
                  Expanded(child: _statCard('Assigned', '${_stats?['assigned'] ?? 0}', Colors.blue, Icons.assignment)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('In Progress', '${_stats?['inProgress'] ?? 0}', Colors.orange, Icons.engineering)),
                  const SizedBox(width: 12),
                  Expanded(child: _statCard('Resolved', '${_stats?['resolved'] ?? 0}', Colors.green, Icons.check_circle)),
                ])),
                const SizedBox(height: 20),
                FadeInUp(delay: const Duration(milliseconds: 400), child: _completionRate()),
              ]),
            ),
          ),
    );
  }

  Widget _statCard(String label, String count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(count, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _completionRate() {
    final total = _stats?['total'] ?? 0;
    final resolved = _stats?['resolved'] ?? 0;
    final rate = total > 0 ? (resolved / total * 100).round() : 0;
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Completion Rate', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text('$rate%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: rate > 70 ? Colors.green : Colors.orange)),
      ]),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(value: total > 0 ? resolved / total : 0, minHeight: 12, backgroundColor: Colors.grey.withOpacity(0.1), color: rate > 70 ? Colors.green : Colors.orange),
      ),
    ])));
  }
}
