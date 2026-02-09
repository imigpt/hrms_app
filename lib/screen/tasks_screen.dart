import 'package:flutter/material.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  // -- Theme Colors --
  final Color _bgDark = const Color(0xFF050505);
  final Color _cardDark = const Color(0xFF141414);
  final Color _inputDark = const Color(0xFF1F1F1F);
  final Color _accentPink = const Color(0xFFFF8FA3);
  final Color _accentGreen = const Color(0xFF00C853);
  final Color _accentOrange = const Color(0xFFFFAB00);
  final Color _accentPurple = const Color(0xFF651FFF);
  final Color _textWhite = Colors.white;
  final Color _textGrey = const Color(0xFF9E9E9E);

  late TabController _tabController;
  
  // -- Form Controllers --
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedPriority = "Medium";

  // -- Search State --
  String _searchQuery = "";

  // -- Dummy Data --
  final List<Map<String, dynamic>> _tasks = [
    {
      "title": "Fix Attendance Bug",
      "desc": "Resolve the overflow issue on mobile devices.",
      "date": "Feb 8",
      "priority": "High",
      "status": "In Progress",
      "progress": 0.65,
    },
    {
      "title": "Update Profile UI",
      "desc": "Implement the new dark theme design.",
      "date": "Feb 10",
      "priority": "Medium",
      "status": "Pending",
      "progress": 0.0,
    },
     {
      "title": "Client Meeting",
      "desc": "Discuss Q1 roadmap.",
      "date": "Feb 6",
      "priority": "Low",
      "status": "Completed",
      "progress": 1.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dateController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // --- Search Logic ---
  List<Map<String, dynamic>> _getFilteredTasks() {
    if (_searchQuery.isEmpty) {
      return _tasks;
    }
    return _tasks.where((task) {
      final titleLower = task['title'].toString().toLowerCase();
      final descLower = task['desc'].toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();
      return titleLower.contains(searchLower) || descLower.contains(searchLower);
    }).toList();
  }

  // --- Date Picker Logic ---
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: _accentPink,
              onPrimary: Colors.black,
              surface: _cardDark,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: _cardDark,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        const List<String> months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        _dateController.text = "${months[picked.month - 1]} ${picked.day}, ${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get filtered list based on search
    final displayTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: _bgDark,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 600;

            return Column(
              children: [
                _buildHeader(context, isMobile),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 24),

                        isMobile ? _buildMobileStats() : _buildDesktopStats(),
                        const SizedBox(height: 30),

                        // Tabs
                        Container(
                          height: 45,
                          decoration: BoxDecoration(
                            color: _cardDark,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            indicator: BoxDecoration(
                              color: _accentPink,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            labelColor: Colors.black,
                            unselectedLabelColor: _textGrey,
                            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            padding: const EdgeInsets.all(4),
                            tabs: const [
                              Tab(text: "All"),
                              Tab(text: "In Progress"),
                              Tab(text: "Pending"),
                              Tab(text: "Done"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // List View with Filtered Data
                        displayTasks.isEmpty 
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 50),
                              child: Text("No tasks found", style: TextStyle(color: _textGrey)),
                            )
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayTasks.length,
                            itemBuilder: (context, index) {
                              return _buildTaskCard(displayTasks[index]);
                            },
                          ),
                        const SizedBox(height: 80), 
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader(BuildContext context, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: _cardDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("My Tasks", style: TextStyle(color: _textWhite, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("Feb 06, 2026", style: TextStyle(color: _textGrey, fontSize: 13)),
                ],
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _handleCreateTask(context),
            icon: const Icon(Icons.add, size: 20),
            label: isMobile ? const SizedBox.shrink() : const Text("New Task"),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentPink,
              foregroundColor: Colors.black,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _inputDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextField(
        style: TextStyle(color: _textWhite),
        onChanged: (value) {
          // Update search state
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "Search tasks...",
          hintStyle: TextStyle(color: _textGrey.withOpacity(0.5)),
          icon: Icon(Icons.search, color: _textGrey),
        ),
      ),
    );
  }

  Widget _buildDesktopStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("Total", "12", Icons.folder_open, _accentPurple)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("Running", "3", Icons.timer, _accentOrange)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("Done", "5", Icons.check_circle, _accentGreen)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard("Upcoming", "4", Icons.calendar_today, Colors.blueAccent)),
      ],
    );
  }

  Widget _buildMobileStats() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard("Total", "12", Icons.folder_open, _accentPurple),
        _buildStatCard("Running", "3", Icons.timer, _accentOrange),
        _buildStatCard("Done", "5", Icons.check_circle, _accentGreen),
        _buildStatCard("Upcoming", "4", Icons.calendar_today, Colors.blueAccent),
      ],
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(count, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          Text(label, style: TextStyle(color: _textGrey, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    Color priorityColor;
    switch (task['priority']) {
      case "High": priorityColor = Colors.redAccent; break;
      case "Medium": priorityColor = _accentOrange; break;
      default: priorityColor = _accentGreen;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: priorityColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task['priority'], 
                              style: TextStyle(color: priorityColor, fontSize: 11, fontWeight: FontWeight.bold)
                            ),
                          ),
                          Icon(Icons.more_horiz, color: _textGrey, size: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(task['title'], style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(task['desc'], maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: _textGrey, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 16),
                      if (task['status'] != "Completed") ...[
                        Row(
                          children: [
                            Text("Progress", style: TextStyle(color: _textGrey, fontSize: 11)),
                            const Spacer(),
                            Text("${(task['progress'] * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: task['progress'],
                            minHeight: 6,
                            backgroundColor: Colors.black,
                            color: priorityColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          Icon(Icons.access_time_filled, color: _textGrey, size: 14),
                          const SizedBox(width: 6),
                          Text(task['date'], style: TextStyle(color: _textGrey, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- CREATE TASK LOGIC ---

  void _handleCreateTask(BuildContext context) {
    _dateController.clear();
    _titleController.clear();
    _descController.clear();

    if (MediaQuery.of(context).size.width < 600) {
      _showMobileBottomSheet(context);
    } else {
      _showDesktopDialog(context);
    }
  }

  void _submitTask(BuildContext context) {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final date = _dateController.text.trim().isEmpty ? "Today" : _dateController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a task title"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _tasks.insert(0, {
        "title": title,
        "desc": desc.isEmpty ? "No description" : desc,
        "date": date,
        "priority": _selectedPriority,
        "status": "Pending",
        "progress": 0.0,
      });
    });

    Navigator.pop(context);
  }

  void _showMobileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            // Handles keyboard overlapping
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            // FIX: Wrapped in SingleChildScrollView to prevent overflow
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 20),
                  const Text("New Task", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildFormContent(context),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDesktopDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("New Task", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildFormContent(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- THE IMPROVED FORM ---
  Widget _buildFormContent(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label("Title"),
            _inputField("e.g. Redesign Home Page", controller: _titleController),
            const SizedBox(height: 16),
            
            _label("Description"),
            _inputField("Add details...", maxLines: 3, controller: _descController),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("Priority"),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: _inputDark, borderRadius: BorderRadius.circular(12)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPriority,
                          isExpanded: true,
                          dropdownColor: _cardDark,
                          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                          style: const TextStyle(color: Colors.white),
                          items: ["Low", "Medium", "High"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setState(() => _selectedPriority = val!),
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _label("Due Date"),
                    // Custom Date Picker Field
                    TextFormField(
                      controller: _dateController,
                      readOnly: true, 
                      style: const TextStyle(color: Colors.white),
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        hintText: "Select Date",
                        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                        filled: true,
                        fillColor: _inputDark,
                        suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFFFF8FA3), size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _submitTask(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentPink,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("Create Task", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _label(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)));

  Widget _inputField(String hint, {int maxLines = 1, TextEditingController? controller}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
        filled: true,
        fillColor: _inputDark,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}