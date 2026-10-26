import 'package:flutter/material.dart';

class UserManualScreen extends StatelessWidget {
  const UserManualScreen({super.key});

  static const _sections = <_Section>[
    _Section(
      icon: Icons.rocket_launch,
      title: 'Quick start',
      steps: [
        'Open the Duct Sizer tab.',
        'Pick Rectangular or Round.',
        'Enter Airflow and Velocity (and Duct Height for rectangular ducts).',
        'The recommended duct size, friction loss, velocity pressure and free area update instantly.',
        'Tap "Add to Schedule Table" to save the result, or "Export PDF Job Sheet" to create a report.',
      ],
    ),
    _Section(
      icon: Icons.calculate,
      title: 'Tab 1 - Duct Sizer',
      steps: [
        'Rectangular / Round: choose the duct shape.',
        'Airflow: the air volume (CFM in Imperial, L/s in Metric).',
        'Velocity: the target air speed (fpm in Imperial, m/s in Metric).',
        'Duct Height: the fixed height available (e.g. ceiling clearance); the width is calculated.',
        'Live 2D Duct Cross-Section: a drawing of the resulting duct.',
        'Result card: recommended size, Huebscher circular equivalent, friction loss, velocity pressure and free area, plus the SMACNA / DW144 gauge suggestion.',
        'Refresh icon: resets the inputs to default values.',
      ],
    ),
    _Section(
      icon: Icons.table_chart,
      title: 'Tab 2 - Schedule Table',
      steps: [
        'Shows every duct segment you added, with the number of segments and total airflow.',
        'Segments are added from the Duct Sizer tab using "Add to Schedule Table".',
        'Export Schedule PDF creates a multi-segment report.',
      ],
    ),
    _Section(
      icon: Icons.swap_horiz,
      title: 'Tab 3 - Equal Friction',
      steps: [
        'A quick reference for common unit conversions: airflow, velocity, duct size, friction loss and velocity pressure.',
      ],
    ),
    _Section(
      icon: Icons.touch_app,
      title: 'Top bar buttons',
      steps: [
        'Imperial / Metric: switch the unit system. Your values convert automatically.',
        'Profile icon: save your name, email and company. They are stored only on your device and used on PDFs.',
        'Red reset icon: clears the app and starts from the beginning.',
        'Book icon: opens the Reference Library (SMACNA gauges, DW144, velocity limits).',
        'Medal icon (mobile app only): upgrade to Pro to remove ads.',
      ],
    ),
    _Section(
      icon: Icons.menu_book,
      title: 'Reference Library',
      steps: [
        'SMACNA Gauges: sheet-metal gauge, thickness, maximum duct dimension and reinforcement class.',
        'DW144 (UK/EU): duct construction thickness and class data.',
        'Velocity Limits: recommended air velocity ranges.',
      ],
    ),
    _Section(
      icon: Icons.picture_as_pdf,
      title: 'Exporting a PDF job sheet',
      steps: [
        'Tap "Export PDF Job Sheet".',
        'A short sponsored ad appears first. Wait for the countdown, then tap "Continue to PDF".',
        'Fill in the Job / System name, client location and technician name.',
        'Tap "Generate PDF" to download or share the report.',
        'The ad helps keep this calculator free.',
      ],
    ),
    _Section(
      icon: Icons.help_outline,
      title: 'Tips',
      steps: [
        'Typical comfort-duct velocities are 600 - 900 fpm for branches and up to about 1,500 fpm for mains.',
        'Results are for guidance. Always verify against local codes and the engineer of record.',
        'Your data stays on your device and is never sent to a server.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guide'),
        backgroundColor: const Color(0xFF0F1216),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _sections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final s = _sections[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(s.icon, color: const Color(0xFF10B981)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              s.title,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      for (final step in s.steps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('•  ',
                                  style: TextStyle(color: Color(0xFF06B6D4))),
                              Expanded(
                                child: Text(step,
                                    style: const TextStyle(
                                        color: Color(0xFFCBD5E1), fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Section {
  const _Section({required this.icon, required this.title, required this.steps});

  final IconData icon;
  final String title;
  final List<String> steps;
}
