import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/token_storage_service.dart';

class ChatApiTestScreen extends StatefulWidget {
  const ChatApiTestScreen({super.key});

  @override
  State<ChatApiTestScreen> createState() => _ChatApiTestScreenState();
}

class _ChatApiTestScreenState extends State<ChatApiTestScreen> {
  final List<_TestResult> _results = [];
  bool _running = false;

  // Cross-test state
  String? _firstUserId;
  String? _testRoomId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAll());
  }

  Future<String?> _token() => TokenStorageService().getToken();

  Future<void> _runAll() async {
    setState(() {
      _running = true;
      _results.clear();
    });

    final tests = [
      _Test('1. Get Company Users'),
      _Test('2. Search Users'),
      _Test('3. Get Unread Count'),
      _Test('4. Get Chat Rooms'),
      _Test('5. Start Personal Chat'),
      _Test('6. Get Room Messages'),
      _Test('7. Mark Room as Read'),
      _Test('8. Send Message'),
    ];

    for (final test in tests) {
      _add(_TestResult(name: test.name, status: _Status.running));
      final result = await _run(test.name);
      _update(test.name, result);
    }

    setState(() => _running = false);
  }

  Future<_TestResult> _run(String name) async {
    final token = await _token();
    if (token == null) {
      return _TestResult(name: name, status: _Status.fail, detail: 'No token');
    }
    try {
      switch (name) {
        // ── Test 1: Get Company Users ──────────────────────────────────────
        case '1. Get Company Users':
          final res = await ChatService.getCompanyUsers(token: token);
          if (!res.success) {
            return _TestResult(
                name: name,
                status: _Status.fail,
                detail: 'success=false, count=${res.count}');
          }
          if (res.data.isNotEmpty) _firstUserId = res.data.first.id;
          return _TestResult(
            name: name,
            status: _Status.pass,
            detail: '${res.count} user(s)'
                '${_firstUserId != null ? ' — first id: $_firstUserId' : ''}',
          );

        // ── Test 2: Search Users ───────────────────────────────────────────
        case '2. Search Users':
          final res = await ChatService.searchUsers(token: token, query: 'a');
          if (!res.success) {
            return _TestResult(
                name: name, status: _Status.fail, detail: 'success=false');
          }
          return _TestResult(
            name: name,
            status: _Status.pass,
            detail: '${res.count} result(s) for "a"',
          );

        // ── Test 3: Get Unread Count ───────────────────────────────────────
        case '3. Get Unread Count':
          final res = await ChatService.getUnreadCount(token: token);
          if (!res.success) {
            return _TestResult(
                name: name, status: _Status.fail, detail: 'success=false');
          }
          return _TestResult(
            name: name,
            status: _Status.pass,
            detail: 'unread: ${res.count}',
          );

        // ── Test 4: Get Chat Rooms ─────────────────────────────────────────
        case '4. Get Chat Rooms':
          final res = await ChatService.getChatRooms(token: token);
          if (!res.success) {
            return _TestResult(
                name: name, status: _Status.fail, detail: 'success=false');
          }
          if (res.data.isNotEmpty) {
            _testRoomId ??= res.data.first.id;
          }
          return _TestResult(
            name: name,
            status: _Status.pass,
            detail: '${res.count} room(s)'
                '${_testRoomId != null ? ' — roomId: $_testRoomId' : ''}',
          );

        // ── Test 5: Start Personal Chat ────────────────────────────────────
        case '5. Start Personal Chat':
          if (_firstUserId == null) {
            return _TestResult(
                name: name,
                status: _Status.skip,
                detail: 'No userId from Test 1');
          }
          final res = await ChatService.getOrCreatePersonalChat(
              token: token, userId: _firstUserId!);
          if (!res.success) {
            return _TestResult(
                name: name, status: _Status.fail, detail: 'success=false');
          }
          _testRoomId ??= res.data.id;
          return _TestResult(
            name: name,
            status: _Status.pass,
            detail: 'room id: ${res.data.id} (type: ${res.data.type})',
          );

        // ── Test 6: Get Room Messages ──────────────────────────────────────
        case '6. Get Room Messages':
          if (_testRoomId == null) {
            return _TestResult(
                name: name,
                status: _Status.skip,
                detail: 'No roomId from Tests 4/5');
          }
          final res = await ChatService.getRoomMessages(
              token: token, roomId: _testRoomId!, limit: 20);
          if (!res.success) {
            return _TestResult(
                name: name, status: _Status.fail, detail: 'success=false');
          }
          return _TestResult(
            name: name,
            status: _Status.pass,
            detail:
                '${res.count} message(s), hasMore=${res.hasMore}',
          );

        // ── Test 7: Mark Room as Read ──────────────────────────────────────
        case '7. Mark Room as Read':
          if (_testRoomId == null) {
            return _TestResult(
                name: name,
                status: _Status.skip,
                detail: 'No roomId from Tests 4/5');
          }
          final res = await ChatService.markRoomAsRead(
              token: token, roomId: _testRoomId!);
          if (!res.success) {
            return _TestResult(
                name: name, status: _Status.fail, detail: 'success=false');
          }
          return _TestResult(
            name: name,
            status: _Status.pass,
            detail: 'modifiedCount=${res.modifiedCount}',
          );

        // ── Test 8: Send Message ───────────────────────────────────────────
        case '8. Send Message':
          if (_testRoomId == null) {
            return _TestResult(
                name: name,
                status: _Status.skip,
                detail: 'No roomId from Tests 4/5');
          }
          final res = await ChatService.sendRoomMessage(
            token: token,
            roomId: _testRoomId!,
            content: '[API Test] Connection check - ignore',
          );
          if (!res.success) {
            return _TestResult(
                name: name, status: _Status.fail, detail: 'success=false');
          }
          return _TestResult(
            name: name,
            status: _Status.pass,
            detail: 'msg id: ${res.data?.id ?? 'n/a'}',
          );

        default:
          return _TestResult(
              name: name, status: _Status.fail, detail: 'Unknown test');
      }
    } catch (e) {
      return _TestResult(name: name, status: _Status.fail, detail: 'Error: $e');
    }
  }

  void _add(_TestResult r) => setState(() => _results.add(r));

  void _update(String name, _TestResult updated) => setState(() {
        final idx = _results.indexWhere((r) => r.name == name);
        if (idx != -1) _results[idx] = updated;
      });

  @override
  Widget build(BuildContext context) {
    final passed = _results.where((r) => r.status == _Status.pass).length;
    final failed = _results.where((r) => r.status == _Status.fail).length;
    final skipped = _results.where((r) => r.status == _Status.skip).length;

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        title: const Text('Chat API Tests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_running)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.pinkAccent),
              onPressed: _runAll,
              tooltip: 'Re-run',
            ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          if (!_running && _results.isNotEmpty)
            Container(
              width: double.infinity,
              color: const Color(0xFF0F0F0F),
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Text(
                'Passed: $passed  Failed: $failed  Skipped: $skipped',
                style: TextStyle(
                  color: failed > 0 ? Colors.redAccent : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          if (_running)
            const LinearProgressIndicator(
                backgroundColor: Color(0xFF0F0F0F),
                color: Colors.pinkAccent),

          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _results.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = _results[i];
                return _ResultTile(result: r);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting types
// ─────────────────────────────────────────────────────────────────────────────

class _Test {
  final String name;
  _Test(this.name);
}

enum _Status { running, pass, fail, skip }

class _TestResult {
  final String name;
  final _Status status;
  final String? detail;
  _TestResult({required this.name, required this.status, this.detail});
}

class _ResultTile extends StatelessWidget {
  final _TestResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (result.status) {
      case _Status.pass:
        color = Colors.greenAccent;
        icon = Icons.check_circle_outline;
        break;
      case _Status.fail:
        color = Colors.redAccent;
        icon = Icons.error_outline;
        break;
      case _Status.skip:
        color = Colors.orangeAccent;
        icon = Icons.skip_next_outlined;
        break;
      case _Status.running:
        color = Colors.blueAccent;
        icon = Icons.hourglass_top_outlined;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F0F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          result.status == _Status.running
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: color),
                )
              : Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.name,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (result.detail != null) ...[
                  const SizedBox(height: 4),
                  Text(result.detail!,
                      style:
                          TextStyle(color: color, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
