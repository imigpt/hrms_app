import 'package:flutter/material.dart';
import 'package:hrms_app/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Scaffold wrapper — back button + icon header + optional trailing widget
// ─────────────────────────────────────────────────────────────────────────────
class AdminSubScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;

  const AdminSubScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.06)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Standard pinky save button
// ─────────────────────────────────────────────────────────────────────────────
class AdminSaveButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;
  final String label;

  const AdminSaveButton({
    super.key,
    required this.saving,
    required this.onTap,
    this.label = 'Update',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: saving ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: saving
              ? AppTheme.primaryColor.withOpacity(0.55)
              : AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (saving)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.save_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section divider label
// ─────────────────────────────────────────────────────────────────────────────
class AdminSectionLabel extends StatelessWidget {
  final String label;
  final bool topPad;
  const AdminSectionLabel(this.label, {super.key, this.topPad = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPad ? 8 : 0, bottom: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single text field
// ─────────────────────────────────────────────────────────────────────────────
class AdminTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool readOnly;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const AdminTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.readOnly = false,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionLabel(label, topPad: false),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          obscureText: obscure,
          maxLines: obscure ? 1 : maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: readOnly ? Colors.grey[500] : Colors.white,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
            filled: true,
            fillColor: readOnly ? AppTheme.background : AppTheme.surfaceVariant,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.errorColor),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dropdown selector
// ─────────────────────────────────────────────────────────────────────────────
class AdminDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const AdminDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionLabel(label, topPad: false),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: AppTheme.cardColor,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.07)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          items: items,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Toggle row (label + switch)
// ─────────────────────────────────────────────────────────────────────────────
class AdminToggleRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdminToggleRow({
    super.key,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tag chip input (for IPs, statuses, etc.)
// ─────────────────────────────────────────────────────────────────────────────
class AdminChipInput extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> chips;
  final ValueChanged<List<String>> onChanged;

  const AdminChipInput({
    super.key,
    required this.label,
    required this.hint,
    required this.chips,
    required this.onChanged,
  });

  @override
  State<AdminChipInput> createState() => _AdminChipInputState();
}

class _AdminChipInputState extends State<AdminChipInput> {
  final _ctrl = TextEditingController();

  void _add() {
    final v = _ctrl.text.trim();
    if (v.isEmpty || widget.chips.contains(v)) return;
    widget.onChanged([...widget.chips, v]);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionLabel(widget.label, topPad: false),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ctrl,
                onFieldSubmitted: (_) => _add(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _add,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        if (widget.chips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.chips
                .map(
                  (c) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => widget.onChanged(
                            widget.chips.where((x) => x != c).toList(),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card wrapper for settings sections
// ─────────────────────────────────────────────────────────────────────────────
class AdminCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const AdminCard({super.key, this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.07), height: 20),
          ],
          ...children,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yes / No toggle buttons
// ─────────────────────────────────────────────────────────────────────────────
class AdminYesNoToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const AdminYesNoToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionLabel(label, topPad: false),
        const SizedBox(height: 8),
        Row(
          children: [
            _Btn('Yes', value, () => onChanged(true), const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            _Btn('No', !value, () => onChanged(false), const Color(0xFFEF4444)),
          ],
        ),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color activeColor;
  const _Btn(this.label, this.active, this.onTap, this.activeColor);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        decoration: BoxDecoration(
          color: active ? activeColor : AppTheme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? activeColor : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey[500],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Multi-select day/option chips row
// ─────────────────────────────────────────────────────────────────────────────
class AdminMultiChipSelect extends StatelessWidget {
  final String label;
  final List<String> options;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const AdminMultiChipSelect({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionLabel(label, topPad: false),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final active = selected.contains(o);
            return GestureDetector(
              onTap: () {
                final next = active
                    ? selected.where((x) => x != o).toList()
                    : [...selected, o];
                onChanged(next);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: active ? AppTheme.primaryColor : AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active
                        ? AppTheme.primaryColor
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  o[0].toUpperCase() + o.substring(1),
                  style: TextStyle(
                    color: active ? Colors.white : Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / error / empty helpers
// ─────────────────────────────────────────────────────────────────────────────
Widget adminLoader() => const Center(
  child: Padding(
    padding: EdgeInsets.all(60),
    child: CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Color(0xFFf4879a)),
    ),
  ),
);

Widget adminError(String msg, VoidCallback retry) => Center(
  child: Padding(
    padding: const EdgeInsets.all(40),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.error_outline_rounded, color: Colors.grey[600], size: 48),
        const SizedBox(height: 12),
        Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: retry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFf4879a),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Small two-column row helper
// ─────────────────────────────────────────────────────────────────────────────
class AdminRow2 extends StatelessWidget {
  final Widget left;
  final Widget right;
  const AdminRow2({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Snack helper
// ─────────────────────────────────────────────────────────────────────────────
void showAdminSnack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: error
          ? const Color(0xFFEF4444)
          : const Color(0xFF22C55E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
