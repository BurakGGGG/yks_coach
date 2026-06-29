/// Firestore schema versioning for `users/{uid}` documents.
///
/// Every user document carries a `schemaVersion` field. When the on-disk shape
/// of a user document (or the way its fields are interpreted) changes in a way
/// that older clients/documents would read incorrectly, bump
/// [kCurrentSchemaVersion] and add a migration step inside [migrateUserData].
///
/// This keeps a single, testable place that understands every historical
/// document shape, so the rest of the app can assume it always sees the current
/// version. v1 is the launch baseline.
library;

/// The schema version this build writes and expects after migration.
const int kCurrentSchemaVersion = 1;

/// Upgrades a raw `users/{uid}` document map to [kCurrentSchemaVersion].
///
/// The function is pure and returns a new map; it never mutates [data]. Each
/// version bump appends one `if (version < N)` block that reshapes the data and
/// advances `version`, so migrations compose forward from any older document.
Map<String, dynamic> migrateUserData(Map<String, dynamic> data) {
  final result = Map<String, dynamic>.of(data);
  var version = (result['schemaVersion'] as num?)?.toInt() ?? 0;

  // v0 -> v1: documents created before `schemaVersion` existed. The baseline
  // shape is unchanged, so there is nothing to reshape — we only stamp the
  // version so future migrations have a known starting point.
  if (version < 1) {
    version = 1;
  }

  // Future migrations go here, e.g.:
  // if (version < 2) { ...reshape...; version = 2; }

  result['schemaVersion'] = version;
  return result;
}
