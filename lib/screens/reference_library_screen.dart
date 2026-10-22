import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ReferenceLibraryScreen extends StatefulWidget {
  const ReferenceLibraryScreen({super.key});

  @override
  State<ReferenceLibraryScreen> createState() => _ReferenceLibraryScreenState();
}

class _ReferenceLibraryScreenState extends State<ReferenceLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _smacnaData = [];
  List<Map<String, dynamic>> _dw144Data = [];
  List<Map<String, dynamic>> _velocityData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOfflineData();
  }

  Future<void> _loadOfflineData() async {
    try {
      final gauges = await DatabaseService.instance.getSmacnaGauges();
      final dw144 = await DatabaseService.instance.getDw144Standards();
      final velocities = await DatabaseService.instance.getVelocityGuidelines();
      setState(() {
        _smacnaData = gauges;
        _dw144Data = dw144;
        _velocityData = velocities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Reference Library'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF10B981),
          tabs: const [
            Tab(text: 'SMACNA Gauges'),
            Tab(text: 'DW144 (UK/EU)'),
            Tab(text: 'Velocity Limits'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSmacnaTab(),
                _buildDw144Tab(),
                _buildVelocityTab(),
              ],
            ),
    );
  }

  Widget _buildSmacnaTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _smacnaData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = _smacnaData[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${row["gauge"]} Gauge Galvanized',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                    Text(
                      '${row["thickness_in"]}" (${row["thickness_mm"]} mm)',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Max Dimension (1" wg): ${row["max_dim_1in_wg"]}'),
                Text('Max Dimension (2" wg): ${row["max_dim_2in_wg"]}'),
                Text('Reinforcement: ${row["reinforcement_class"]}', style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDw144Tab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _dw144Data.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = _dw144Data[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${row["thickness_mm"]} mm Sheet Thickness',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                    ),
                    Text(
                      'Max Side: ${row["max_side_mm"]} mm',
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Pressure Standard: ${row["pressure_class"]} (Max ${row["max_pressure_pa"]} Pa)'),
                Text('Joint / Flange Type: ${row["joint_type"]}', style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVelocityTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _velocityData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final row = _velocityData[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row["application"]} - ${row["duct_location"]}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF06B6D4)),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recommended: ${row["fpm_recommended"]} (${row["ms_recommended"]})'),
                    Text('Max: ${row["fpm_max"]}'),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Acoustic Standard: ${row["noise_criteria"]}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
