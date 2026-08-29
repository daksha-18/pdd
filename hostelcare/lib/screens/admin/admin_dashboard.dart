import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/sentiment_analyzer.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic>? _data;
  List<dynamic>? _staffPerformance;
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
      final perfRes = await ApiService.get('${ApiConstants.analytics}/staff-performance');
      setState(() {
        _data = res['data'];
        _staffPerformance = perfRes['data'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final primary = cs.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 200,
                  pinned: true,
                  stretch: true,
                  backgroundColor: primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary, const Color(0xFF4F46E5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -30, top: -30,
                            child: Container(
                              width: 150, height: 150,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                          SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  FadeInDown(
                                    child: Text(
                                      'Admin Dashboard',
                                      style: GoogleFonts.outfit(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  FadeInDown(
                                    delay: const Duration(milliseconds: 100),
                                    child: Text(
                                      'Manage complaints & users',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FadeInUp(child: _overviewCards()),
                      const SizedBox(height: 24),
                      FadeInUp(delay: const Duration(milliseconds: 150), child: _staffFeedbackCard()),
                      const SizedBox(height: 24),
                      FadeInUp(delay: const Duration(milliseconds: 300), child: _resolutionCard()),
                      const SizedBox(height: 24),
                      FadeInUp(delay: const Duration(milliseconds: 450), child: _priorityChart()),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _overviewCards() {
    final o = _data?['overview'] ?? {};
    final resolvedVal = (o['resolved'] != null && (o['resolved'] as num) > 0)
        ? (o['resolved'] as num).toInt()
        : ((o['resolved'] ?? 0) + (o['closed'] ?? 0));
    final items = [
      {'label': 'Total', 'value': '${o['totalComplaints'] ?? 0}', 'icon': Icons.receipt_long_rounded, 'color': const Color(0xFF6366F1)},
      {'label': 'Pending', 'value': '${o['pending'] ?? 0}', 'icon': Icons.hourglass_empty_rounded, 'color': const Color(0xFFF59E0B)},
      {'label': 'Active', 'value': '${(o['assigned'] ?? 0) + (o['inProgress'] ?? 0)}', 'icon': Icons.engineering_rounded, 'color': const Color(0xFF3B82F6)},
      {'label': 'Resolved', 'value': '$resolvedVal', 'icon': Icons.check_circle_rounded, 'color': const Color(0xFF10B981)},
    ];

    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);
    final childAspectRatio = width > 900 ? 1.8 : (width > 600 ? 1.5 : 1.1);

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final color = item['color'] as Color;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.1)),
            boxShadow: isDark ? [] : [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'] as IconData, color: color, size: 20),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['value'] as String,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? color : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    item['label'] as String,
                    style: GoogleFonts.inter(
                      color: isDark ? color.withOpacity(0.8) : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  Widget _staffFeedbackCard() {
    final perf = _staffPerformance ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.amber.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Staff Feedback Scores',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Student satisfaction ratings across all staff',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (perf.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),
            Text(
              'Staff Ratings Breakdown',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[300] : const Color(0xFF334155)),
            ),
            const SizedBox(height: 10),
            Column(
              children: perf.map((s) {
                final staffData = s['staff'] ?? {};
                final name = staffData['name'] ?? 'Staff';
                final spec = (staffData['specialization'] ?? 'general').toString().toUpperCase();
                final rating = (s['avgRating'] ?? 0.0).toDouble();
                final resolved = s['totalResolved'] ?? 0;

                final double avgSent = (s['averageSentimentScore'] ?? s['avgSentiment'] ?? 0.0).toDouble();
                final String sLabel = avgSent > 0.05 ? 'positive' : (avgSent < -0.05 ? 'negative' : 'neutral');
                final sentResult = SentimentAnalyzer.analyze('', serverScore: avgSent, serverLabel: sLabel);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.indigo.withOpacity(0.1),
                        child: Text(name[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('$spec • Resolved: $resolved', style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              rating > 0 ? rating.toStringAsFixed(1) : 'New',
                              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                            ),
                          ],
                        ),
                      ),
                      if (rating > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sentResult.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sentResult.color.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(sentResult.icon, color: sentResult.color, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                sentResult.formattedScore,
                                style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: sentResult.color),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
