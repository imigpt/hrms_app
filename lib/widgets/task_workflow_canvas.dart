// lib/widgets/task_workflow_canvas.dart
// Flutter port of TaskWorkflowCanvas.tsx
// Visualises user-defined workflow steps with diagram + list views,
// node selection, properties panel, and per-step complete action.

import 'dart:math' as math;
import 'package:flutter/material.dart';

// ── Layout constants ────────────────────────────────────────────────────────
const double _kNw   = 148; // node width
const double _kNh   = 50;  // node height
const double _kGapX = 44;  // horizontal gap
const double _kGapY = 64;  // vertical gap
const double _kPad  = 20;  // canvas padding
const int    _kRowS = 4;   // nodes per row

// ── Step style helpers ──────────────────────────────────────────────────────
Color _stroke(String? s) {
  switch (s) {
    case 'active':    return const Color(0xFF7c3aed);
    case 'completed': return const Color(0xFF059669);
    case 'skipped':   return const Color(0xFF374151);
    default:          return const Color(0xFF475569);
  }
}

Color _stepBg(String? s) {
  switch (s) {
    case 'active':    return const Color(0xFF1a1028);
    case 'completed': return const Color(0xFF0f2318);
    case 'skipped':   return const Color(0xFF111827);
    default:          return const Color(0xFF1e2330);
  }
}

Color _stepTextColor(String? s) {
  switch (s) {
    case 'active':    return const Color(0xFFc4b5fd);
    case 'completed': return const Color(0xFF6ee7b7);
    case 'skipped':   return const Color(0xFF6b7280);
    default:          return const Color(0xFF94a3b8);
  }
}

Color _roleColor(String? role) {
  switch (role?.toLowerCase()) {
    case 'admin':    return const Color(0xFFef4444);
    case 'hr':       return const Color(0xFFa855f7);
    case 'employee': return const Color(0xFF22c55e);
    default:         return const Color(0xFF3b82f6);
  }
}

// ── Layout helpers ──────────────────────────────────────────────────────────
List<Offset> _computePositions(int count) {
  return List.generate(count, (i) {
    final row = i ~/ _kRowS;
    final col = row % 2 == 0 ? i % _kRowS : _kRowS - 1 - (i % _kRowS);
    return Offset(_kPad + col * (_kNw + _kGapX), _kPad + row * (_kNh + _kGapY));
  });
}

Size _computeDiagramSize(int count) {
  if (count == 0) return const Size(320, 120);
  final rows = (count / _kRowS).ceil();
  final cols = math.min(count, _kRowS);
  return Size(
    _kPad * 2 + cols * _kNw + (cols - 1) * _kGapX,
    _kPad * 2 + rows * _kNh + (rows - 1) * _kGapY + 26, // +26 for legend
  );
}

// ── Diagram CustomPainter ───────────────────────────────────────────────────
class _DiagramPainter extends CustomPainter {
  final List<dynamic> steps;
  final List<Offset> positions;
  final int? selectedIdx;

  const _DiagramPainter({
    required this.steps,
    required this.positions,
    this.selectedIdx,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawArrows(canvas);
    _drawNodes(canvas);
    _drawLegend(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFF1a2332);
    for (double x = 0; x < size.width; x += 24) {
      for (double y = 0; y < size.height; y += 24) {
        canvas.drawCircle(Offset(x + 1, y + 1), 0.8, p);
      }
    }
  }

  void _drawArrows(Canvas canvas) {
    for (int i = 0; i < positions.length - 1; i++) {
      final a    = positions[i];
      final b    = positions[i + 1];
      final step = steps[i];
      final s    = step['status']?.toString();
      final color = s == 'completed'
          ? const Color(0xFF059669)
          : s == 'active'
              ? const Color(0xFF7c3aed)
              : const Color(0xFF374151);
      final isWrap = a.dy != b.dy;
      final paint = Paint()
        ..color       = color
        ..strokeWidth = s == 'completed' ? 2.0 : 1.5
        ..style       = PaintingStyle.stroke;
      final path = _arrowPath(a, b, isWrap);
      if (s == 'pending' || s == null) {
        _drawDashed(canvas, path, paint);
      } else {
        canvas.drawPath(path, paint);
      }
      _drawHead(canvas, color, a, b, isWrap);
    }
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final end = math.min(d + (draw ? 5.0 : 3.0), m.length);
        if (draw) canvas.drawPath(m.extractPath(d, end), paint);
        d = end;
        draw = !draw;
      }
    }
  }

  Path _arrowPath(Offset a, Offset b, bool wrap) {
    if (wrap) {
      final sx = a.dx + _kNw / 2, sy = a.dy + _kNh;
      final ex = b.dx + _kNw / 2, ey = b.dy;
      final my = (sy + ey) / 2;
      return Path()..moveTo(sx, sy)..cubicTo(sx, my, ex, my, ex, ey);
    }
    final sx = a.dx + _kNw, sy = a.dy + _kNh / 2;
    final ex = b.dx,         ey = sy;
    final mx = (sx + ex) / 2;
    return Path()..moveTo(sx, sy)..cubicTo(mx, sy, mx, ey, ex, ey);
  }

  void _drawHead(Canvas canvas, Color color, Offset a, Offset b, bool wrap) {
    double tx, ty, angle;
    if (wrap) {
      tx = b.dx + _kNw / 2; ty = b.dy;          angle = math.pi / 2;
    } else {
      tx = b.dx;             ty = b.dy + _kNh / 2; angle = 0;
    }
    const sz = 6.0;
    canvas.drawPath(
      Path()
        ..moveTo(tx, ty)
        ..lineTo(tx - sz * math.cos(angle - math.pi / 6), ty - sz * math.sin(angle - math.pi / 6))
        ..lineTo(tx - sz * math.cos(angle + math.pi / 6), ty - sz * math.sin(angle + math.pi / 6))
        ..close(),
      Paint()..color = color..style = PaintingStyle.fill,
    );
  }

  void _drawNodes(Canvas canvas) {
    for (int i = 0; i < positions.length; i++) {
      final pos  = positions[i];
      final step = steps[i];
      final s    = step['status']?.toString();
      final isSel = selectedIdx == i;

      // Selection ring
      if (isSel) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(pos.dx - 5, pos.dy - 5, _kNw + 10, _kNh + 10),
            const Radius.circular(13),
          ),
          Paint()
            ..color       = const Color(0xFFf59e0b)
            ..style       = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }

      // Node body
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(pos.dx, pos.dy, _kNw, _kNh),
        const Radius.circular(9),
      );
      canvas.drawRRect(rr, Paint()..color = _stepBg(s));
      canvas.drawRRect(
        rr,
        Paint()
          ..color       = _stroke(s)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = s == 'active' ? 2.5 : 1.5,
      );

      // Step number
      _txt(canvas, '${i + 1}', pos.dx + 10, pos.dy + 4, 9,
          FontWeight.w700, _stroke(s).withOpacity(0.7));

      // Title (truncated)
      final title = step['title']?.toString() ?? '';
      final disp  = title.length > 14 ? '${title.substring(0, 13)}…' : title;
      _txtC(canvas, disp, pos.dx + _kNw / 2, pos.dy + _kNh / 2 - 8,
          12, FontWeight.w600, _stepTextColor(s));

      // Status label
      if (s == 'completed') {
        _txtC(canvas, '✓ done', pos.dx + _kNw / 2, pos.dy + _kNh - 14,
            8, FontWeight.normal, const Color(0xFF059669).withOpacity(0.7));
      } else if (s == 'active') {
        _txtC(canvas, '● active', pos.dx + _kNw / 2, pos.dy + _kNh - 14,
            8, FontWeight.normal, const Color(0xFFa78bfa));
      }

      // Role dot
      final role = step['responsibleRole']?.toString();
      if (role != null && role != 'any') {
        canvas.drawCircle(
          Offset(pos.dx + _kNw - 10, pos.dy + 10),
          4,
          Paint()..color = _roleColor(role).withOpacity(0.85),
        );
      }
    }
  }

  void _drawLegend(Canvas canvas, Size size) {
    final y = size.height - 14;
    _leg(canvas, _kPad,        y, const Color(0xFF0f2318), const Color(0xFF059669), 'Completed');
    _leg(canvas, _kPad + 88,   y, const Color(0xFF1a1028), const Color(0xFF7c3aed), 'Active');
    _leg(canvas, _kPad + 152,  y, const Color(0xFF1e2330), const Color(0xFF475569), 'Pending');
  }

  void _leg(Canvas canvas, double x, double y, Color bg, Color stroke, String label) {
    final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x, y - 6, 8, 8), const Radius.circular(2));
    canvas.drawRRect(rr, Paint()..color = bg);
    canvas.drawRRect(rr, Paint()..color = stroke..style = PaintingStyle.stroke..strokeWidth = 1.5);
    _txt(canvas, label, x + 12, y - 5, 9, FontWeight.normal, const Color(0xFF64748b));
  }

  void _txt(Canvas canvas, String s, double x, double y, double sz,
      FontWeight w, Color c) {
    (TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: c, fontSize: sz, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout())
        .paint(canvas, Offset(x, y));
  }

  void _txtC(Canvas canvas, String s, double cx, double cy, double sz,
      FontWeight w, Color c) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: c, fontSize: sz, fontWeight: w)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy));
  }

  @override
  bool shouldRepaint(_DiagramPainter old) =>
      old.steps != steps || old.selectedIdx != selectedIdx;
}

// ── Main widget ─────────────────────────────────────────────────────────────
class TaskWorkflowCanvas extends StatefulWidget {
  final String workflowName;
  final List<dynamic> steps;
  final int currentStepIndex;
  final Future<void> Function(int stepIndex, String comment)? onCompleteStep;
  final bool completing;

  const TaskWorkflowCanvas({
    super.key,
    required this.workflowName,
    required this.steps,
    required this.currentStepIndex,
    this.onCompleteStep,
    this.completing = false,
  });

  @override
  State<TaskWorkflowCanvas> createState() => _TaskWorkflowCanvasState();
}

class _TaskWorkflowCanvasState extends State<TaskWorkflowCanvas> {
  String _view = 'diagram'; // 'diagram' | 'list'
  int?   _selectedIdx;
  final  _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedIdx = widget.currentStepIndex < widget.steps.length
        ? widget.currentStepIndex
        : null;
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.steps.where((s) => s['status'] == 'completed').length;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0d1117),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(done),
          _view == 'diagram' ? _buildDiagram() : _buildListView(),
          if (_selectedIdx != null) _buildPropsPanel(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(int done) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    widget.workflowName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$done/${widget.steps.length} done',
                    style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          // Toggle buttons
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2A2A2A)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                _toggleBtn('diagram', Icons.grid_view_rounded, 'Diagram'),
                _toggleBtn('list',    Icons.list_rounded,      'List'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String view, IconData icon, String label) {
    final active = _view == view;
    return GestureDetector(
      onTap: () => setState(() => _view = view),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFF8FA3) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: active ? Colors.white : const Color(0xFF9E9E9E)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.white : const Color(0xFF9E9E9E))),
          ],
        ),
      ),
    );
  }

  // ── Diagram view ──────────────────────────────────────────────────────────
  Widget _buildDiagram() {
    if (widget.steps.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No steps defined', style: TextStyle(color: Color(0xFF9E9E9E)))),
      );
    }
    final positions = _computePositions(widget.steps.length);
    final diagSize  = _computeDiagramSize(widget.steps.length);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: GestureDetector(
        onTapUp: (d) {
          final localPos = d.localPosition;
          for (int i = 0; i < positions.length; i++) {
            final p = positions[i];
            if (localPos.dx >= p.dx && localPos.dx <= p.dx + _kNw &&
                localPos.dy >= p.dy && localPos.dy <= p.dy + _kNh) {
              setState(() => _selectedIdx = _selectedIdx == i ? null : i);
              return;
            }
          }
          setState(() => _selectedIdx = null);
        },
        child: CustomPaint(
          painter: _DiagramPainter(
            steps:       widget.steps,
            positions:   positions,
            selectedIdx: _selectedIdx,
          ),
          size: diagSize,
        ),
      ),
    );
  }

  // ── List view ─────────────────────────────────────────────────────────────
  Widget _buildListView() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: widget.steps.asMap().entries.map((e) {
          final i    = e.key;
          final step = e.value;
          final s    = step['status']?.toString() ?? 'pending';
          final isA  = s == 'active';
          final isD  = s == 'completed';
          return GestureDetector(
            onTap: () => setState(() => _selectedIdx = _selectedIdx == i ? null : i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _stepBg(s),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _stroke(s).withOpacity(isA ? 0.5 : 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status icon circle
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _stepBg(s),
                      border: Border.all(color: _stroke(s), width: 2),
                    ),
                    child: Center(
                      child: isD
                          ? Icon(Icons.check, size: 12, color: _stroke(s))
                          : isA
                              ? Container(
                                  width: 8, height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF7c3aed),
                                  ),
                                )
                              : Text('${i + 1}', style: TextStyle(color: _stepTextColor(s), fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                step['title']?.toString() ?? '',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  decoration: isD ? TextDecoration.lineThrough : null,
                                  decorationColor: const Color(0xFF9E9E9E),
                                ),
                              ),
                            ),
                            if (isA)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7c3aed).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFF7c3aed).withOpacity(0.4)),
                                ),
                                child: const Text('Active',
                                    style: TextStyle(color: Color(0xFFc4b5fd), fontSize: 9, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        if ((step['description']?.toString() ?? '').isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(step['description']?.toString() ?? '',
                              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10)),
                        ],
                        if (isD && step['completedBy'] != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.person_outline, size: 11, color: Color(0xFF9E9E9E)),
                              const SizedBox(width: 3),
                              Text(_nameFrom(step['completedBy']),
                                  style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10)),
                            ],
                          ),
                        ],
                        if ((step['comment']?.toString() ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text('"${step['comment']}"',
                              style: const TextStyle(
                                  color: Color(0xFF6b7280), fontSize: 10, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Properties panel ──────────────────────────────────────────────────────
  Widget _buildPropsPanel() {
    final idx  = _selectedIdx!;
    if (idx >= widget.steps.length) return const SizedBox.shrink();
    final step = widget.steps[idx];
    final s    = step['status']?.toString() ?? 'pending';
    final isA  = s == 'active';
    final isD  = s == 'completed';
    final role = step['responsibleRole']?.toString() ?? 'any';

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _stroke(s).withOpacity(isA ? 0.4 : 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row + close
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Step ${idx + 1}',
                        style: const TextStyle(
                            color: Color(0xFF9E9E9E), fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(step['title']?.toString() ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedIdx = null),
                child: const Icon(Icons.close, color: Color(0xFF9E9E9E), size: 16),
              ),
            ],
          ),
          if ((step['description']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(step['description']?.toString() ?? '',
                style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('Status', s.toUpperCase(), _stroke(s)),
              if (role != 'any') _chip('Role', role.toUpperCase(), _roleColor(role)),
            ],
          ),
          if (isD) ...[
            const SizedBox(height: 8),
            if (step['completedBy'] != null)
              Row(children: [
                const Icon(Icons.person_outline, size: 13, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('Completed by ${_nameFrom(step['completedBy'])}',
                      style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 11)),
                ),
              ]),
            if ((step['comment']?.toString() ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('"${step['comment']}"',
                  style: const TextStyle(
                      color: Color(0xFF6b7280), fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ],
          // ── Complete step action (active step only) ──
          if (isA && widget.onCompleteStep != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF2A2A2A)),
            const SizedBox(height: 8),
            const Text('Complete this step',
                style: TextStyle(
                    color: Color(0xFF9E9E9E), fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: _commentCtrl,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              decoration: InputDecoration(
                hintText: 'Optional comment…',
                hintStyle: const TextStyle(color: Color(0xFF6b7280), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFF0D0D0D),
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF2A2A2A))),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: Color(0xFF7c3aed))),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: widget.completing
                    ? const SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 14),
                label: Text(widget.completing ? 'Completing…' : 'Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: widget.completing
                    ? null
                    : () async {
                        final comment = _commentCtrl.text.trim();
                        await widget.onCompleteStep!(idx, comment);
                        _commentCtrl.clear();
                      },
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: RichText(
        text: TextSpan(children: [
          TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10)),
          TextSpan(
              text: value,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  static String _nameFrom(dynamic v) {
    if (v is Map) return v['name']?.toString() ?? v['employeeId']?.toString() ?? 'Unknown';
    return v?.toString() ?? 'Unknown';
  }
}
