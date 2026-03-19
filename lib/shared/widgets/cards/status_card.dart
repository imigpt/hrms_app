import 'package:flutter/material.dart';

class StatusCard extends StatelessWidget {
  final Duration workedDuration;
  final double progress; // 0.0 – 1.0
  final Duration totalOfficeHours;
  final DateTime? checkInTime;

  const StatusCard({
    super.key,
    required this.workedDuration,
    required this.progress,
    this.totalOfficeHours = const Duration(hours: 8),
    this.checkInTime,
  });

  // ── helpers ───────────────────────────────────────────────────────────────
  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).abs();
    if (h > 0 && m > 0) return '$h hrs $m mins';
    if (h > 0) return '$h hrs';
    return '$m mins';
  }

  Duration get _lateTime {
    final diff = totalOfficeHours - workedDuration;
    return diff.isNegative ? Duration.zero : diff;
  }

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 18,
                color: Colors.redAccent.shade100,
              ),
              const SizedBox(width: 6),
              const Text(
                'Working Hour Details',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Detail rows ───────────────────────────────────────────────
          _DetailRow(
            color: Colors.grey,
            label: 'Total office time',
            value: _fmt(totalOfficeHours),
          ),
          const SizedBox(height: 10),
          _DetailRow(
            color: Colors.greenAccent,
            label: 'Total worked time',
            value: _fmt(workedDuration),
          ),
          const SizedBox(height: 10),
          _DetailRow(
            color: Colors.redAccent,
            label: 'Total Late time',
            value: _fmt(_lateTime),
          ),

          const SizedBox(height: 14),

          // ── Progress bar ──────────────────────────────────────────────
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedProgress,
              backgroundColor: Colors.grey[800],
              color: Colors.greenAccent,
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Private helper widget ──────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _DetailRow({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
