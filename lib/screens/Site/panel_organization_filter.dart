import '../Social/social_api.dart';

/// Organization identifiers are only used for presentation; the server scopes data.
Map<String, String> panelOrganizationOptions(
  Json data,
  List<Json> rows, {
  required bool fa,
  String mode = 'branch',
  bool includeFixedScope = false,
}) {
  final options = <String, String>{};
  if (panelFixedBranchScope(data) && !includeFixedScope) return options;
  if (mode == 'owner') {
    for (final organization in objects(data['organizations'] ?? [])) {
      options['owner:${organization['id']}'] = '${organization['name'] ?? ''}';
    }
    return options;
  }
  if (mode == 'points') {
    options['academy'] = fa ? 'آموزشگاه' : 'Academy';
    for (final organization in objects(data['organizations'] ?? [])) {
      if (organization['id'] != null && '${organization['id']}' != '0')
        options['branch:${organization['id']}'] = '${organization['name']}';
    }
    return options;
  }
  // The website always offers the academy scope, even when it has no rows.
  options['academy'] = fa ? 'آموزشگاه' : 'Academy';
  for (final owner in objects(data['owners'] ?? [])) {
    if (owner['kind'] == 'branch') {
      options['owner:${owner['userId']}'] = '${owner['name']}';
    }
  }
  for (final branch in objects(data['branches'] ?? [])) {
    if (branch['id'] != null) {
      if (branch['kind'] == 'academy') continue;
      options['branch:${branch['branchId'] ?? branch['id']}'] =
          '${branch['name'] ?? branch['title'] ?? branch['id']}';
    }
  }
  for (final organization in [
    ...objects(data['organizations'] ?? []),
    ...objects(optionalObject(data['staff_catalog'])['organizations'] ?? []),
  ]) {
    if (organization['kind'] == 'academy') {
      options['academy'] = fa ? 'آموزشگاه' : 'Academy';
    } else if (organization['kind'] == 'branch') {
      final id =
          organization['branchId'] ??
          organization['entityId'] ??
          organization['id'];
      options['branch:$id'] = '${organization['name'] ?? id}';
    }
  }
  for (final row in rows) {
    final organization = optionalObject(row['organization']);
    final kind = row['organizationKind'] ?? organization['kind'];
    final id = row['branchId'] ?? row['branch_id'] ?? organization['branchId'];
    if (kind == 'academy' ||
        ((row.containsKey('branchId') || row.containsKey('branch_id')) &&
            (id == null || '$id' == '0'))) {
      options['academy'] = fa ? 'آموزشگاه' : 'Academy';
    } else if (id != null && '$id' != '0') {
      options.putIfAbsent(
        'branch:$id',
        () =>
            '${row['branchName'] ?? row['branch_name'] ?? organization['name'] ?? id}',
      );
    }
  }
  return options;
}

bool panelFixedBranchScope(Json data) =>
    data['branchContext'] == true ||
    data['branch_account'] == true ||
    optionalObject(data['permissions'])['isBranchContext'] == true ||
    optionalObject(data['staff_catalog'])['organization_selection'] == 'fixed';

bool panelMatchesOrganization(
  Json row,
  String selection, [
  Json data = const {},
]) {
  if (selection.isEmpty) return true;
  if (selection.startsWith('owner:'))
    return selection.substring(6) ==
        '${row['ownerId'] ?? row['owner_id'] ?? row['user_id'] ?? row['organizationUserId']}';
  final organization = optionalObject(row['organization']);
  final owner = objects(
    data['owners'] ?? [],
  ).where((owner) => '${owner['userId']}' == '${row['ownerId']}').firstOrNull;
  final branch =
      row['branchId'] ?? row['branch_id'] ?? organization['branchId'];
  if (selection == 'academy') {
    return (row['ownerKind'] ??
                owner?['kind'] ??
                row['organizationKind'] ??
                organization['kind']) ==
            'academy' ||
        ((row.containsKey('branchId') || row.containsKey('branch_id')) &&
            (branch == null || '$branch' == '0'));
  }
  return selection == 'branch:$branch';
}
