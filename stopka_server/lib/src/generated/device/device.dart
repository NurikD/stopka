/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _is;

/// An anonymous installation of the app. There is no user account: the app
/// registers once and keeps the returned token in secure storage.
abstract class Device
    implements _is.TableRow<_is.UuidValue?>, _is.ProtocolSerialization {
  Device._({
    this.id,
    required this.tokenHash,
    required this.appVersion,
    this.ipHash,
    required this.createdAt,
    required this.lastSeenAt,
    bool? blocked,
  }) : blocked = blocked ?? false;

  factory Device({
    _is.UuidValue? id,
    required String tokenHash,
    required String appVersion,
    String? ipHash,
    required DateTime createdAt,
    required DateTime lastSeenAt,
    bool? blocked,
  }) = _DeviceImpl;

  factory Device.fromJson(Map<String, dynamic> jsonSerialization) {
    return Device(
      id: jsonSerialization['id'] == null
          ? null
          : _is.UuidValueJsonExtension.fromJson(jsonSerialization['id']),
      tokenHash: jsonSerialization['tokenHash'] as String,
      appVersion: jsonSerialization['appVersion'] as String,
      ipHash: jsonSerialization['ipHash'] as String?,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastSeenAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastSeenAt'],
      ),
      blocked: jsonSerialization['blocked'] == null
          ? null
          : _is.BoolJsonExtension.fromJson(jsonSerialization['blocked']),
    );
  }

  static final t = DeviceTable();

  static const db = DeviceRepository._();

  @override
  _is.UuidValue? id;

  /// SHA-256 of the device token. The token itself is never stored.
  String tokenHash;

  String appVersion;

  /// SHA-256 of the client IP and a server secret, only used to cap how many
  /// devices one address can register per day.
  String? ipHash;

  DateTime createdAt;

  DateTime lastSeenAt;

  bool blocked;

  @override
  _is.Table<_is.UuidValue?> get table => t;

  /// Returns a shallow copy of this [Device]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Device copyWith({
    _is.UuidValue? id,
    String? tokenHash,
    String? appVersion,
    String? ipHash,
    DateTime? createdAt,
    DateTime? lastSeenAt,
    bool? blocked,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Device',
      if (id != null) 'id': id?.toJson(),
      'tokenHash': tokenHash,
      'appVersion': appVersion,
      if (ipHash != null) 'ipHash': ipHash,
      'createdAt': createdAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
      'blocked': blocked,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Device',
      if (id != null) 'id': id?.toJson(),
      'tokenHash': tokenHash,
      'appVersion': appVersion,
      if (ipHash != null) 'ipHash': ipHash,
      'createdAt': createdAt.toJson(),
      'lastSeenAt': lastSeenAt.toJson(),
      'blocked': blocked,
    };
  }

  static DeviceInclude include() {
    return DeviceInclude._();
  }

  static DeviceIncludeList includeList({
    _is.WhereExpressionBuilder<DeviceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceTable>? orderBy,
    _is.OrderByListBuilder<DeviceTable>? orderByList,
    DeviceInclude? include,
  }) {
    return DeviceIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Device.t),
      orderByList: orderByList?.call(Device.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceImpl extends Device {
  _DeviceImpl({
    _is.UuidValue? id,
    required String tokenHash,
    required String appVersion,
    String? ipHash,
    required DateTime createdAt,
    required DateTime lastSeenAt,
    bool? blocked,
  }) : super._(
         id: id,
         tokenHash: tokenHash,
         appVersion: appVersion,
         ipHash: ipHash,
         createdAt: createdAt,
         lastSeenAt: lastSeenAt,
         blocked: blocked,
       );

  /// Returns a shallow copy of this [Device]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Device copyWith({
    Object? id = _Undefined,
    String? tokenHash,
    String? appVersion,
    Object? ipHash = _Undefined,
    DateTime? createdAt,
    DateTime? lastSeenAt,
    bool? blocked,
  }) {
    return Device(
      id: id is _is.UuidValue? ? id : this.id,
      tokenHash: tokenHash ?? this.tokenHash,
      appVersion: appVersion ?? this.appVersion,
      ipHash: ipHash is String? ? ipHash : this.ipHash,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      blocked: blocked ?? this.blocked,
    );
  }
}

class DeviceUpdateTable extends _is.UpdateTable<DeviceTable> {
  DeviceUpdateTable(super.table);

  _is.ColumnValue<String, String> tokenHash(String value) => _is.ColumnValue(
    table.tokenHash,
    value,
  );

  _is.ColumnValue<String, String> appVersion(String value) => _is.ColumnValue(
    table.appVersion,
    value,
  );

  _is.ColumnValue<String, String> ipHash(String? value) => _is.ColumnValue(
    table.ipHash,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );

  _is.ColumnValue<DateTime, DateTime> lastSeenAt(DateTime value) =>
      _is.ColumnValue(
        table.lastSeenAt,
        value,
      );

  _is.ColumnValue<bool, bool> blocked(bool value) => _is.ColumnValue(
    table.blocked,
    value,
  );
}

class DeviceTable extends _is.Table<_is.UuidValue?> {
  DeviceTable({super.tableRelation}) : super(tableName: 'device') {
    updateTable = DeviceUpdateTable(this);
    tokenHash = _is.ColumnString(
      'tokenHash',
      this,
    );
    appVersion = _is.ColumnString(
      'appVersion',
      this,
    );
    ipHash = _is.ColumnString(
      'ipHash',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
    lastSeenAt = _is.ColumnDateTime(
      'lastSeenAt',
      this,
    );
    blocked = _is.ColumnBool(
      'blocked',
      this,
      hasDefault: true,
    );
  }

  late final DeviceUpdateTable updateTable;

  /// SHA-256 of the device token. The token itself is never stored.
  late final _is.ColumnString tokenHash;

  late final _is.ColumnString appVersion;

  /// SHA-256 of the client IP and a server secret, only used to cap how many
  /// devices one address can register per day.
  late final _is.ColumnString ipHash;

  late final _is.ColumnDateTime createdAt;

  late final _is.ColumnDateTime lastSeenAt;

  late final _is.ColumnBool blocked;

  @override
  List<_is.Column> get columns => [
    id,
    tokenHash,
    appVersion,
    ipHash,
    createdAt,
    lastSeenAt,
    blocked,
  ];
}

class DeviceInclude extends _is.IncludeObject {
  DeviceInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<_is.UuidValue?> get table => Device.t;
}

class DeviceIncludeList extends _is.IncludeList {
  DeviceIncludeList._({
    _is.WhereExpressionBuilder<DeviceTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Device.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<_is.UuidValue?> get table => Device.t;
}

class DeviceRepository {
  const DeviceRepository._();

  /// Returns a list of [Device]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Device>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceTable>? orderBy,
    _is.OrderByListBuilder<DeviceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Device>(
      where: where?.call(Device.t),
      orderBy: orderBy?.call(Device.t),
      orderByList: orderByList?.call(Device.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Device] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Device?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceTable>? where,
    int? offset,
    _is.OrderByBuilder<DeviceTable>? orderBy,
    _is.OrderByListBuilder<DeviceTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Device>(
      where: where?.call(Device.t),
      orderBy: orderBy?.call(Device.t),
      orderByList: orderByList?.call(Device.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Device] by its [id] or null if no such row exists.
  Future<Device?> findById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Device>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Device]s in the list and returns the inserted rows.
  ///
  /// The returned [Device]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Device>> insert(
    _is.DatabaseSession session,
    List<Device> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Device>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Device] and returns the inserted row.
  ///
  /// The returned [Device] will have its `id` field set.
  Future<Device> insertRow(
    _is.DatabaseSession session,
    Device row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Device>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Device]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [Device]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Device>> upsert(
    _is.DatabaseSession session,
    List<Device> rows, {
    required _is.ColumnSelections<DeviceTable> conflictColumns,
    _is.ColumnSelections<DeviceTable>? updateColumns,
    _is.WhereExpressionBuilder<DeviceTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Device>(
      rows,
      conflictColumns: conflictColumns(Device.t),
      updateColumns: updateColumns?.call(Device.t),
      updateWhere: updateWhere?.call(Device.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Device] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [Device] will have its `id` field set.
  Future<Device?> upsertRow(
    _is.DatabaseSession session,
    Device row, {
    required _is.ColumnSelections<DeviceTable> conflictColumns,
    _is.ColumnSelections<DeviceTable>? updateColumns,
    _is.WhereExpressionBuilder<DeviceTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Device>(
      row,
      conflictColumns: conflictColumns(Device.t),
      updateColumns: updateColumns?.call(Device.t),
      updateWhere: updateWhere?.call(Device.t),
      transaction: transaction,
    );
  }

  /// Updates all [Device]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Device>> update(
    _is.DatabaseSession session,
    List<Device> rows, {
    _is.ColumnSelections<DeviceTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Device>(
      rows,
      columns: columns?.call(Device.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Device]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Device> updateRow(
    _is.DatabaseSession session,
    Device row, {
    _is.ColumnSelections<DeviceTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Device>(
      row,
      columns: columns?.call(Device.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Device] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Device?> updateById(
    _is.DatabaseSession session,
    _is.UuidValue id, {
    required _is.ColumnValueListBuilder<DeviceUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Device>(
      id,
      columnValues: columnValues(Device.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Device]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Device>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<DeviceUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<DeviceTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<DeviceTable>? orderBy,
    _is.OrderByListBuilder<DeviceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Device>(
      columnValues: columnValues(Device.t.updateTable),
      where: where(Device.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Device.t),
      orderByList: orderByList?.call(Device.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Device]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Device>> delete(
    _is.DatabaseSession session,
    List<Device> rows, {
    _is.OrderByBuilder<DeviceTable>? orderBy,
    _is.OrderByListBuilder<DeviceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Device>(
      rows,
      orderBy: orderBy?.call(Device.t),
      orderByList: orderByList?.call(Device.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Device].
  Future<Device> deleteRow(
    _is.DatabaseSession session,
    Device row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Device>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Device>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeviceTable> where,
    _is.OrderByBuilder<DeviceTable>? orderBy,
    _is.OrderByListBuilder<DeviceTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Device>(
      where: where(Device.t),
      orderBy: orderBy?.call(Device.t),
      orderByList: orderByList?.call(Device.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<DeviceTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Device>(
      where: where?.call(Device.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Device] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<DeviceTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Device>(
      where: where(Device.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
