import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_app/features/policies/data/models/policy_model.dart';
import 'package:hrms_app/features/policies/presentation/providers/policies_notifier.dart';

CompanyPolicy _policy({
  required String id,
  required String title,
  String location = 'Head Office',
}) {
  return CompanyPolicy(
    id: id,
    title: title,
    location: location,
    description: '',
    isActive: true,
  );
}

void main() {
  group('PoliciesNotifier', () {
    test('loadPolicies fetches policies and updates state', () async {
      final list = [
        _policy(id: 'p1', title: 'Attendance Policy'),
        _policy(id: 'p2', title: 'Leave Policy'),
      ];

      final notifier = PoliciesNotifier(
        getPolicies: ({required token, String? search}) async {
          return PolicyListResponse(success: true, count: list.length, data: list);
        },
      );

      await notifier.loadPolicies(token: 'token');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.totalCount, 2);
      expect(notifier.state.policies.length, 2);
      expect(notifier.state.policies.first.id, 'p1');
    });

    test('searchPolicies forwards query and stores searchQuery', () async {
      String? receivedSearch;
      final notifier = PoliciesNotifier(
        getPolicies: ({required token, String? search}) async {
          receivedSearch = search;
          return PolicyListResponse(success: true, count: 0, data: const []);
        },
      );

      await notifier.searchPolicies(token: 'token', query: 'leave');

      expect(receivedSearch, 'leave');
      expect(notifier.state.searchQuery, 'leave');
    });

    test('createPolicy refreshes list after successful create', () async {
      var created = false;
      final notifier = PoliciesNotifier(
        createPolicy: ({
          required token,
          required title,
          String description = '',
          String location = 'Head Office',
          file,
          String? fileName,
        }) async {
          created = true;
        },
        getPolicies: ({required token, String? search}) async {
          final data = created
              ? [_policy(id: 'p1', title: 'New Policy')]
              : <CompanyPolicy>[];
          return PolicyListResponse(success: true, count: data.length, data: data);
        },
      );

      await notifier.loadPolicies(token: 'token');
      expect(notifier.state.policies, isEmpty);

      await notifier.createPolicy(token: 'token', title: 'New Policy');

      expect(created, true);
      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.policies.length, 1);
      expect(notifier.state.policies.first.title, 'New Policy');
    });

    test('deletePolicy removes item from current state', () async {
      final notifier = PoliciesNotifier(
        getPolicies: ({required token, String? search}) async {
          final data = [
            _policy(id: 'p1', title: 'Policy 1'),
            _policy(id: 'p2', title: 'Policy 2'),
          ];
          return PolicyListResponse(success: true, count: data.length, data: data);
        },
        deletePolicy: ({required token, required id}) async {},
      );

      await notifier.loadPolicies(token: 'token');
      await notifier.deletePolicy(token: 'token', id: 'p2');

      expect(notifier.state.policies.length, 1);
      expect(notifier.state.policies.first.id, 'p1');
      expect(notifier.state.totalCount, 1);
      expect(notifier.state.errorMessage, isNull);
    });

    test('loadPolicies sets error message on failure', () async {
      final notifier = PoliciesNotifier(
        getPolicies: ({required token, String? search}) async {
          throw Exception('network');
        },
      );

      await notifier.loadPolicies(token: 'token');

      expect(notifier.state.isLoading, false);
      expect(notifier.state.errorMessage, contains('Failed to load policies'));
      expect(notifier.state.errorMessage, contains('network'));
    });

    test('reset restores initial defaults', () async {
      final notifier = PoliciesNotifier(
        getPolicies: ({required token, String? search}) async {
          final data = [_policy(id: 'p1', title: 'Policy 1')];
          return PolicyListResponse(success: true, count: data.length, data: data);
        },
      );

      await notifier.searchPolicies(token: 'token', query: 'policy');
      notifier.reset();

      expect(notifier.state.policies, isEmpty);
      expect(notifier.state.searchQuery, '');
      expect(notifier.state.isLoading, false);
      expect(notifier.state.isSubmitting, false);
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.totalCount, 0);
    });
  });
}
