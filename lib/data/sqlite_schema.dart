/// Storage schema version is independent of the portable JSON backup version.
const storageSchemaVersion = 1;

/// Existing model fields, with nested values encoded as JSON in their own column.
/// References are validated by GardenData: some are intentionally provenance
/// (e.g. entries survive deletion of a recurring rule or savings goal).
const entityColumns = <String, Map<String, String>>{
  'entries': {
    'title': 'TEXT',
    'amount': 'INTEGER',
    'date': 'TEXT',
    'createdAt': 'TEXT',
    'category': 'TEXT',
    'kind': 'TEXT',
    'notes': 'TEXT',
    'splitId': 'TEXT',
    'goalId': 'TEXT',
    'importRef': 'TEXT',
    'recurringId': 'TEXT',
    'paymentId': 'TEXT',
  },
  'tasks': {
    'title': 'TEXT',
    'date': 'TEXT',
    'amount': 'INTEGER',
    'direction': 'TEXT',
    'completed': 'BOOLEAN',
    'notes': 'TEXT',
    'personId': 'TEXT',
  },
  'goals': {
    'title': 'TEXT',
    'target': 'INTEGER',
    'date': 'TEXT',
    'icon': 'TEXT',
  },
  'contributions': {'goalId': 'TEXT', 'amount': 'INTEGER', 'date': 'TEXT'},
  'people': {'name': 'TEXT'},
  'splits': {
    'title': 'TEXT',
    'total': 'INTEGER',
    'date': 'TEXT',
    'method': 'TEXT',
    'portions': 'JSON',
    'payerId': 'TEXT',
    'groupId': 'TEXT',
    'items': 'JSON',
    'notes': 'TEXT',
  },
  'payments': {
    'splitId': 'TEXT',
    'personId': 'TEXT',
    'amount': 'INTEGER',
    'date': 'TEXT',
    'note': 'TEXT',
  },
  'groups': {
    'name': 'TEXT',
    'emoji': 'TEXT',
    'memberIds': 'JSON',
    'createdAt': 'TEXT',
    'archived': 'BOOLEAN',
  },
  'groupSettlements': {
    'groupId': 'TEXT',
    'fromId': 'TEXT',
    'toId': 'TEXT',
    'amount': 'INTEGER',
    'date': 'TEXT',
    'note': 'TEXT',
  },
  'recurring': {
    'title': 'TEXT',
    'amount': 'INTEGER',
    'category': 'TEXT',
    'kind': 'TEXT',
    'frequency': 'TEXT',
    'dayOfMonth': 'INTEGER',
    'weekday': 'INTEGER',
    'startDate': 'TEXT',
    'endDate': 'TEXT',
    'paused': 'BOOLEAN',
    'lastGeneratedPeriod': 'TEXT',
  },
};
const mapTables = ['activity', 'budgets', 'importMappings'];
const settingKeys = [
  'schemaVersion',
  'themePack',
  'profile',
  'appLock',
  'theme',
  'currency',
];
