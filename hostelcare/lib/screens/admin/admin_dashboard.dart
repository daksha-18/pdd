import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('${ApiConstants.analytics}/dashboard');
      setState(() { _data = res['data']; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(slivers: [
              SliverAppBar(
                expandedHeight: 140, pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [cs.primary, cs.primary.withOpacity(0.7)])),
                    child: SafeArea(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
                      const Text('Admin Dashboard', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Manage complaints & users', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                    ]))),
                  ),
                ),
              ),
              SliverPadding(padding: const EdgeInsets.all(16), sliver: SliverList(delegate: SliverChildListDelegate([
                FadeInUp(child: _overviewCards()),
                const SizedBox(height: 20),
                FadeInUp(delay: const Duration(milliseconds: 200), child: _categoryChart()),
                const SizedBox(height: 20),
                FadeInUp(delay: const Duration(milliseconds: 400), child: _resolutionCard()),
                const SizedBox(height: 20),
                FadeInUp(delay: const Duration(milliseconds: 600), child: _priorityChart()),
              ]))),
            ]),
          ),
    );
  }

  Widget _overviewCards() {
    final o = _data?['overview'] ?? {};
    final items = [
      {'label': 'Total', 'value': '${o['totalComplaints'] ?? 0}', 'icon': Icons.receipt_long, 'color': Colors.blue},
      {'label': 'Pending', 'value': '${o['pending'] ?? 0}', 'icon': Icons.hourglass_empty, 'color': Colors.orange},
      {'label': 'Active', 'value': '${(o['assigned'] ?? 0) + (o['inProgress'] ?? 0)}', 'icon': Icons.engineering, 'color': Colors.indigo},
      {'label': 'Resolved', 'value': '${o['resolved'] ?? 0}', 'icon': Icons.check_circle, 'color': Colors.green},
    ];
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.5,
      children: items.map((item) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [(item['color'] as Color).withOpacity(0.15), (item['color'] as Color).withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(16), border: Border.all(color: (item['color'] as Color).withOpacity(0.2)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(item['icon'] as IconData, color: item['color'] as Color, size: 28),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['value'] as String, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: item['color'] as Color)),
            Text(item['label'] as String, style: TextStyle(color: (item['color'] as Color).withOpacity(0.8), fontSize: 13)),
          ]),
        ]),
      )).toList(),
    );
  }

  Widget _categoryChart() {
    final dist = (_data?['categoryDistribution'] as List?) ?? [];
    if (dist.isEmpty) return const SizedBox();
    final colors = [Colors.amber, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('By Category', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      SizedBox(height: 200, child: PieChart(PieChartData(
        sections: dist.asMap().entries.map((e) {
          final d = e.value;
          return PieChartSectionData(
            value: (d['count'] as num).toDouble(), title: '${d['count']}',
            color: colors[e.key % colors.length], radius: 60,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          );
        }).toList(),
        centerSpaceRadius: 40, sectionsSpace: 2,
      ))),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 8, children: dist.asMap().entries.map((e) {
        final d = e.value;
        final cat = (d['_id'] ?? '').toString();
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[e.key % colors.length], borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text('${AppConstants.categoryIcons[cat] ?? ''} ${cat[0].toUpperCase()}${cat.substring(1)}', style: const TextStyle(fontSize: 12)),
        ]);
      }).toList()),
    ])));
  }

  Widget _resolutionCard() {
    final hours = _data?['avgResolutionHours'] ?? 0;
    final o = _data?['overview'] ?? {};
    return Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
      Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.timer_outlined, color: Colors.green, size: 30)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Avg Resolution Time', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text('$hours hours', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ])),
      Column(children: [
        Text('${o['totalStudents'] ?? 0}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Students', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 4),
        Text('${o['totalStaff'] ?? 0}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text('Staff', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ]),
    ])));
  }

  Widget _priorityChart() {
    final dist = (_data?['priorityDistribution'] as List?) ?? [];
    if (dist.isEmpty) return const SizedBox();
    final pColors = {'low': Colors.green, 'medium': Colors.orange, 'high': Colors.deepOrange, 'urgent': Colors.red};
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('By Priority', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      ...dist.map((d) {
        final p = d['_id'] ?? '';
        final count = d['count'] ?? 0;
        final total = dist.fold<num>(0, (s, e) => s + (e['count'] ?? 0));
        final pct = total > 0 ? count / total : 0.0;
        final c = pColors[p] ?? Colors.grey;
        return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('${p[0].toUpperCase()}${p.substring(1)}', style: TextStyle(fontWeight: FontWeight.w500, color: c)),
            Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: c)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: pct.toDouble(), backgroundColor: c.withOpacity(0.1), color: c, minHeight: 8)),
        ]));
      }),
    ])));
  }
}
