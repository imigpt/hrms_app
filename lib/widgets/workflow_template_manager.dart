// lib/widgets/workflow_template_manager.dart
// Comprehensive Workflow Template Manager
// Handles full CRUD operations and step management

import 'package:flutter/material.dart';
import '../services/workflow_service.dart';

class WorkflowTemplateManager extends StatefulWidget {
  final String token;
  final Function(Map<String, dynamic>)? onSelectTemplate;

  const WorkflowTemplateManager({
    super.key,
    required this.token,
    this.onSelectTemplate,
  });

  @override
  State<WorkflowTemplateManager> createState() => _WorkflowTemplateManagerState();
}

class _WorkflowTemplateManagerState extends State<WorkflowTemplateManager> {
  // Colors
  final Color _cardDark = const Color(0xFF141414);
  final Color _inputDark = const Color(0xFF1F1F1F);
  final Color _accentPink = const Color(0xFFFF8FA3);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _textGrey = const Color(0xFF9E9E9E);

  // State
  List<dynamic> _workflows = [];
  bool _loading = true;
  String _panel = 'list'; // 'list' | 'create' | 'edit'
  Map<String, dynamic>? _editingWorkflow;

  // Form state
  String _formName = '';
  String _formDesc = '';
  bool _formShared = false;
  List<Map<String, dynamic>> _formSteps = [];
  bool _saving = false;

  // Dedicated controllers prevent cursor-jump on every rebuild
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadWorkflows();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkflows() async {
    setState(() => _loading = true);
    try {
      final res = await WorkflowService.getTemplates(widget.token);
      if (!mounted) return;
      
      setState(() {
        if (res is Map<String, dynamic>) {
          _workflows = (res['data'] as List<dynamic>?) ?? [];
        } else if (res is List<dynamic>) {
          _workflows = res;
        }
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFEF5350)),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveWorkflow() async {
    if (_formName.trim().isEmpty) {
      _showError('Workflow name is required');
      return;
    }

    final validSteps = _formSteps.where((s) => (s['title'] as String?)?.trim().isNotEmpty == true).toList();
    if (validSteps.isEmpty) {
      _showError('Add at least one step with a title');
      return;
    }

    setState(() => _saving = true);
    try {
      if (_panel == 'create') {
        await WorkflowService.createTemplate(
          widget.token,
          name: _formName.trim(),
          description: _formDesc.isEmpty ? null : _formDesc,
        );
      } else if (_panel == 'edit' && _editingWorkflow != null) {
        await WorkflowService.updateTemplate(
          widget.token,
          _editingWorkflow!['_id'],
          name: _formName.trim(),
          description: _formDesc,
          isShared: _formShared,
          steps: validSteps.asMap().entries.map((e) => {
            'order': e.key + 1,
            'title': e.value['title'] ?? '',
            'description': e.value['description'] ?? '',
            'responsibleRole': e.value['responsibleRole'] ?? 'any',
          }).toList(),
        );
      }

      if (mounted) {
        final wasCreate = _panel == 'create';
        await _loadWorkflows();
        setState(() => _panel = 'list');
        _showSuccess('Workflow ${wasCreate ? 'created' : 'updated'}');
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteWorkflow(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardDark,
        title: const Text('Delete Workflow?', style: TextStyle(color: Colors.white)),
        content: Text('Delete "$name"? Tasks using it will keep their copy.',
            style: TextStyle(color: _textGrey.withValues(alpha: 0.8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: TextStyle(color: _textGrey))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Color(0xFFEF5350)))),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await WorkflowService.deleteTemplate(widget.token, id);
      if (mounted) {
        await _loadWorkflows();
        _showSuccess('"$name" deleted');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _duplicateWorkflow(String id, String name) async {
    try {
      await WorkflowService.duplicateTemplate(widget.token, id);
      if (mounted) {
        await _loadWorkflows();
        _showSuccess('Copy of "$name" created');
      }
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF5350)),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: _accentGreen),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return const Color(0xFFEF5350);
      case 'hr': return const Color(0xFF9C27B0);
      case 'employee': return _accentGreen;
      default: return _textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollController) => Column(
        children: [
          _panel == 'list' ? _buildListHeader() : _buildFormHeader(),
          Expanded(
            child: _panel == 'list'
                ? _buildListView(scrollController)
                : _buildFormView(scrollController),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Workflow Templates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 2),
            Text('Manage your workflow templates', style: TextStyle(fontSize: 11, color: _textGrey.withValues(alpha: 0.6))),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                _nameController.clear();
                _descController.clear();
                setState(() {
                  _panel = 'create';
                  _editingWorkflow = null;
                  _formName = '';
                  _formDesc = '';
                  _formShared = false;
                  _formSteps = [{'order': 1, 'title': '', 'description': '', 'responsibleRole': 'any'}];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: _accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: _accentGreen),
                    const SizedBox(width: 3),
                    Text('New', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _accentGreen)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(Icons.close, color: _textGrey, size: 20),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildFormHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)))),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            _panel == 'create' ? 'Create Template' : 'Edit "${_editingWorkflow?['name']}"',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(onTap: () => setState(() => _panel = 'list'), child: Icon(Icons.close, color: _textGrey, size: 20)),
      ],
    ),
  );

  Widget _buildListView(ScrollController scrollController) => _loading
      ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(_accentPink)))
      : _workflows.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.layers_clear_outlined, size: 48, color: _textGrey.withValues(alpha: 0.4)), const SizedBox(height: 12), Text('No workflows yet', style: TextStyle(color: _textGrey.withValues(alpha: 0.7)))]))
          : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _workflows.length,
              itemBuilder: (context, index) {
                final wf = _workflows[index] as Map<String, dynamic>?;
                if (wf == null) return const SizedBox.shrink();

                final wfId      = wf['_id']?.toString() ?? '';
                final wfName    = wf['name']?.toString() ?? 'Unnamed';
                final wfDesc    = wf['description']?.toString() ?? '';
                final wfShared  = wf['isShared'] as bool? ?? false;
                final wfSteps   = ((wf['steps'] as List?) ?? []).map((s) => (s as Map<String, dynamic>?) ?? <String, dynamic>{}).toList();
                final createdBy = wf['createdBy'];
                final creatorName = createdBy is Map ? (createdBy['name']?.toString() ?? '') : '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _inputDark.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Name row + action buttons ────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(wfName,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                    ),
                                    if (wfShared)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _accentGreen.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(children: [
                                          Icon(Icons.people_outline, size: 10, color: _accentGreen),
                                          const SizedBox(width: 2),
                                          Text('Shared', style: TextStyle(fontSize: 8, color: _accentGreen, fontWeight: FontWeight.w500)),
                                        ]),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Text(
                                      '${wfSteps.length} step${wfSteps.length != 1 ? 's' : ''}',
                                      style: TextStyle(fontSize: 10, color: _textGrey.withValues(alpha: 0.5)),
                                    ),
                                    if (creatorName.isNotEmpty) ...[  
                                      Text('  ·  ', style: TextStyle(fontSize: 10, color: _textGrey.withValues(alpha: 0.3))),
                                      Icon(Icons.person_outline, size: 10, color: _textGrey.withValues(alpha: 0.4)),
                                      const SizedBox(width: 2),
                                      Text(creatorName, style: TextStyle(fontSize: 10, color: _textGrey.withValues(alpha: 0.5))),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ── Buttons column ─────────────────────────────────
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (widget.onSelectTemplate != null)
                                GestureDetector(
                                  onTap: () => widget.onSelectTemplate!.call(wf),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _accentPink.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: _accentPink.withValues(alpha: 0.3)),
                                    ),
                                    child: Text('Use',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: _accentPink,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _nameController.text = wfName;
                                      _descController.text = wfDesc;
                                      setState(() {
                                        _panel = 'edit';
                                        _editingWorkflow = wf;
                                        _formName = wfName;
                                        _formDesc = wfDesc;
                                        _formShared = wfShared;
                                        _formSteps = wfSteps
                                            .map((s) => Map<String, dynamic>.from(s))
                                            .toList();
                                      });
                                    },
                                    child: Icon(Icons.edit_outlined, size: 15, color: _textGrey.withValues(alpha: 0.6)),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => _duplicateWorkflow(wfId, wfName),
                                    child: Icon(Icons.content_copy_outlined, size: 15, color: _textGrey.withValues(alpha: 0.6)),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => _deleteWorkflow(wfId, wfName),
                                    child: const Icon(Icons.delete_outline, size: 15, color: Color(0xFFEF5350)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      // ── Description ──────────────────────────────────────────
                      if (wfDesc.isNotEmpty) ...[  
                        const SizedBox(height: 6),
                        Text(
                          wfDesc,
                          style: TextStyle(fontSize: 11, color: _textGrey.withValues(alpha: 0.6)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      // ── Step previews with role dots ──────────────────────────
                      if (wfSteps.isNotEmpty) ...[  
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            ...wfSteps.take(5).map((s) {
                              final role  = s['responsibleRole']?.toString() ?? 'any';
                              final title = s['title']?.toString() ?? '';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _roleColor(role).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: _roleColor(role).withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle, color: _roleColor(role)),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      title.length > 14 ? '${title.substring(0, 13)}…' : title,
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: _textGrey.withValues(alpha: 0.8)),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (wfSteps.length > 5)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _textGrey.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '+${wfSteps.length - 5} more',
                                  style: TextStyle(fontSize: 9, color: _textGrey.withValues(alpha: 0.6)),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );

  Widget _buildFormView(ScrollController scrollController) => ListView(
    controller: scrollController,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    children: [
      Text('Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 6),
      TextField(
        onChanged: (val) => setState(() => _formName = val),
        controller: _nameController,
        decoration: InputDecoration(
          hintText: 'Workflow name',
          filled: true,
          fillColor: _inputDark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 16),
      Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
      const SizedBox(height: 6),
      TextField(
        onChanged: (val) => setState(() => _formDesc = val),
        controller: _descController,
        maxLines: 2,
        decoration: InputDecoration(
          hintText: 'Optional description',
          filled: true,
          fillColor: _inputDark,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07))),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        style: const TextStyle(color: Colors.white),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Share with team', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          Switch(
            value: _formShared,
            onChanged: (val) => setState(() => _formShared = val),
            activeColor: _accentGreen,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Steps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
          GestureDetector(
            onTap: () => setState(() => _formSteps.add({'order': _formSteps.length + 1, 'title': '', 'description': '', 'responsibleRole': 'any'})),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: _accentGreen.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 12, color: _accentGreen), const SizedBox(width: 2), Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _accentGreen))]),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      ..._formSteps.asMap().entries.map((e) {
        final idx  = e.key;
        final step = e.value;
        final role = step['responsibleRole']?.toString() ?? 'any';
        return Padding(
          // ValueKey so Flutter reconciles correctly when steps are reordered
          key: ValueKey('step_${step['_id'] ?? idx}'),
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: _inputDark.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title row ───────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: _accentPink.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text('${idx + 1}',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: _accentPink)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      // initialValue + no-setState onChanged = no cursor jump on rebuild
                      child: TextFormField(
                        key: ValueKey('title_${step['_id'] ?? idx}'),
                        initialValue: step['title']?.toString() ?? '',
                        onChanged: (val) => _formSteps[idx]['title'] = val,
                        decoration: InputDecoration(
                          hintText: 'Step title *',
                          hintStyle: TextStyle(color: _textGrey.withValues(alpha: 0.5), fontSize: 12),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    GestureDetector(
                      onTap: idx > 0
                          ? () => setState(() {
                                final tmp = _formSteps[idx];
                                _formSteps[idx] = _formSteps[idx - 1];
                                _formSteps[idx - 1] = tmp;
                              })
                          : null,
                      child: Icon(Icons.keyboard_arrow_up,
                          size: 18,
                          color: idx > 0 ? _accentGreen : _textGrey.withValues(alpha: 0.25)),
                    ),
                    GestureDetector(
                      onTap: idx < _formSteps.length - 1
                          ? () => setState(() {
                                final tmp = _formSteps[idx];
                                _formSteps[idx] = _formSteps[idx + 1];
                                _formSteps[idx + 1] = tmp;
                              })
                          : null,
                      child: Icon(Icons.keyboard_arrow_down,
                          size: 18,
                          color: idx < _formSteps.length - 1
                              ? _accentGreen
                              : _textGrey.withValues(alpha: 0.25)),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _formSteps.length > 1
                          ? () => setState(() => _formSteps.removeAt(idx))
                          : null,
                      child: Icon(Icons.close,
                          size: 15,
                          color: _formSteps.length > 1
                              ? const Color(0xFFEF5350)
                              : _textGrey.withValues(alpha: 0.25)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // ── Description field ────────────────────────────────────────
                TextFormField(
                  key: ValueKey('desc_${step['_id'] ?? idx}'),
                  initialValue: step['description']?.toString() ?? '',
                  onChanged: (val) => _formSteps[idx]['description'] = val,
                  maxLines: 1,
                  decoration: InputDecoration(
                    hintText: 'Step description (optional)',
                    hintStyle: TextStyle(color: _textGrey.withValues(alpha: 0.4), fontSize: 11),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    isCollapsed: true,
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(height: 8),
                // ── Role selector ────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor(role).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _roleColor(role).withValues(alpha: 0.25)),
                  ),
                  child: DropdownButton<String>(
                    value: role,
                    onChanged: (val) =>
                        setState(() => _formSteps[idx]['responsibleRole'] = val ?? 'any'),
                    isExpanded: true,
                    dropdownColor: _inputDark,
                    underline: const SizedBox(),
                    isDense: true,
                    icon: Icon(Icons.expand_more, size: 16, color: _roleColor(role)),
                    items: ['any', 'admin', 'hr', 'employee']
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Row(children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: _roleColor(r)),
                                ),
                                const SizedBox(width: 8),
                                Text(r.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _roleColor(r))),
                              ]),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _saving ? null : _saveWorkflow,
          style: ElevatedButton.styleFrom(backgroundColor: _accentPink, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: _saving ? SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: const AlwaysStoppedAnimation<Color>(Colors.white))) : Text(_panel == 'create' ? 'Create' : 'Save', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
        ),
      ),
      const SizedBox(height: 20),
    ],
  );
}
