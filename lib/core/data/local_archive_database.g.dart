// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_archive_database.dart';

// ignore_for_file: type=lint
class $ProfilesLocalTable extends ProfilesLocal
    with TableInfo<$ProfilesLocalTable, ProfilesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfilesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarUrlMeta = const VerificationMeta(
    'avatarUrl',
  );
  @override
  late final GeneratedColumn<String> avatarUrl = GeneratedColumn<String>(
    'avatar_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bioMeta = const VerificationMeta('bio');
  @override
  late final GeneratedColumn<String> bio = GeneratedColumn<String>(
    'bio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    username,
    displayName,
    avatarUrl,
    bio,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfilesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('avatar_url')) {
      context.handle(
        _avatarUrlMeta,
        avatarUrl.isAcceptableOrUnknown(data['avatar_url']!, _avatarUrlMeta),
      );
    }
    if (data.containsKey('bio')) {
      context.handle(
        _bioMeta,
        bio.isAcceptableOrUnknown(data['bio']!, _bioMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  ProfilesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfilesLocalData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      ),
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      avatarUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_url'],
      ),
      bio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bio'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $ProfilesLocalTable createAlias(String alias) {
    return $ProfilesLocalTable(attachedDatabase, alias);
  }
}

class ProfilesLocalData extends DataClass
    implements Insertable<ProfilesLocalData> {
  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;
  final String? bio;
  final String? createdAt;
  final String? updatedAt;
  const ProfilesLocalData({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
    this.bio,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || username != null) {
      map['username'] = Variable<String>(username);
    }
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    if (!nullToAbsent || avatarUrl != null) {
      map['avatar_url'] = Variable<String>(avatarUrl);
    }
    if (!nullToAbsent || bio != null) {
      map['bio'] = Variable<String>(bio);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  ProfilesLocalCompanion toCompanion(bool nullToAbsent) {
    return ProfilesLocalCompanion(
      userId: Value(userId),
      username: username == null && nullToAbsent
          ? const Value.absent()
          : Value(username),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      avatarUrl: avatarUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarUrl),
      bio: bio == null && nullToAbsent ? const Value.absent() : Value(bio),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory ProfilesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfilesLocalData(
      userId: serializer.fromJson<String>(json['userId']),
      username: serializer.fromJson<String?>(json['username']),
      displayName: serializer.fromJson<String?>(json['displayName']),
      avatarUrl: serializer.fromJson<String?>(json['avatarUrl']),
      bio: serializer.fromJson<String?>(json['bio']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'username': serializer.toJson<String?>(username),
      'displayName': serializer.toJson<String?>(displayName),
      'avatarUrl': serializer.toJson<String?>(avatarUrl),
      'bio': serializer.toJson<String?>(bio),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  ProfilesLocalData copyWith({
    String? userId,
    Value<String?> username = const Value.absent(),
    Value<String?> displayName = const Value.absent(),
    Value<String?> avatarUrl = const Value.absent(),
    Value<String?> bio = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => ProfilesLocalData(
    userId: userId ?? this.userId,
    username: username.present ? username.value : this.username,
    displayName: displayName.present ? displayName.value : this.displayName,
    avatarUrl: avatarUrl.present ? avatarUrl.value : this.avatarUrl,
    bio: bio.present ? bio.value : this.bio,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  ProfilesLocalData copyWithCompanion(ProfilesLocalCompanion data) {
    return ProfilesLocalData(
      userId: data.userId.present ? data.userId.value : this.userId,
      username: data.username.present ? data.username.value : this.username,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarUrl: data.avatarUrl.present ? data.avatarUrl.value : this.avatarUrl,
      bio: data.bio.present ? data.bio.value : this.bio,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesLocalData(')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bio: $bio, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    username,
    displayName,
    avatarUrl,
    bio,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfilesLocalData &&
          other.userId == this.userId &&
          other.username == this.username &&
          other.displayName == this.displayName &&
          other.avatarUrl == this.avatarUrl &&
          other.bio == this.bio &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProfilesLocalCompanion extends UpdateCompanion<ProfilesLocalData> {
  final Value<String> userId;
  final Value<String?> username;
  final Value<String?> displayName;
  final Value<String?> avatarUrl;
  final Value<String?> bio;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const ProfilesLocalCompanion({
    this.userId = const Value.absent(),
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfilesLocalCompanion.insert({
    required String userId,
    this.username = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarUrl = const Value.absent(),
    this.bio = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<ProfilesLocalData> custom({
    Expression<String>? userId,
    Expression<String>? username,
    Expression<String>? displayName,
    Expression<String>? avatarUrl,
    Expression<String>? bio,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (username != null) 'username': username,
      if (displayName != null) 'display_name': displayName,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
      if (bio != null) 'bio': bio,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfilesLocalCompanion copyWith({
    Value<String>? userId,
    Value<String?>? username,
    Value<String?>? displayName,
    Value<String?>? avatarUrl,
    Value<String?>? bio,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfilesLocalCompanion(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarUrl.present) {
      map['avatar_url'] = Variable<String>(avatarUrl.value);
    }
    if (bio.present) {
      map['bio'] = Variable<String>(bio.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfilesLocalCompanion(')
          ..write('userId: $userId, ')
          ..write('username: $username, ')
          ..write('displayName: $displayName, ')
          ..write('avatarUrl: $avatarUrl, ')
          ..write('bio: $bio, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectiblesLocalTable extends CollectiblesLocal
    with TableInfo<$CollectiblesLocalTable, CollectiblesLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectiblesLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesMeta = const VerificationMeta('series');
  @override
  late final GeneratedColumn<String> series = GeneratedColumn<String>(
    'series',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _franchiseMeta = const VerificationMeta(
    'franchise',
  );
  @override
  late final GeneratedColumn<String> franchise = GeneratedColumn<String>(
    'franchise',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lineOrSeriesMeta = const VerificationMeta(
    'lineOrSeries',
  );
  @override
  late final GeneratedColumn<String> lineOrSeries = GeneratedColumn<String>(
    'line_or_series',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _characterOrSubjectMeta =
      const VerificationMeta('characterOrSubject');
  @override
  late final GeneratedColumn<String> characterOrSubject =
      GeneratedColumn<String>(
        'character_or_subject',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta(
    'releaseYear',
  );
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boxStatusMeta = const VerificationMeta(
    'boxStatus',
  );
  @override
  late final GeneratedColumn<String> boxStatus = GeneratedColumn<String>(
    'box_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemNumberMeta = const VerificationMeta(
    'itemNumber',
  );
  @override
  late final GeneratedColumn<String> itemNumber = GeneratedColumn<String>(
    'item_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _itemConditionMeta = const VerificationMeta(
    'itemCondition',
  );
  @override
  late final GeneratedColumn<String> itemCondition = GeneratedColumn<String>(
    'item_condition',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _purchasePriceMeta = const VerificationMeta(
    'purchasePrice',
  );
  @override
  late final GeneratedColumn<double> purchasePrice = GeneratedColumn<double>(
    'purchase_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimatedValueMeta = const VerificationMeta(
    'estimatedValue',
  );
  @override
  late final GeneratedColumn<double> estimatedValue = GeneratedColumn<double>(
    'estimated_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _acquiredOnMeta = const VerificationMeta(
    'acquiredOn',
  );
  @override
  late final GeneratedColumn<String> acquiredOn = GeneratedColumn<String>(
    'acquired_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isGrailMeta = const VerificationMeta(
    'isGrail',
  );
  @override
  late final GeneratedColumn<bool> isGrail = GeneratedColumn<bool>(
    'is_grail',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_grail" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDuplicateMeta = const VerificationMeta(
    'isDuplicate',
  );
  @override
  late final GeneratedColumn<bool> isDuplicate = GeneratedColumn<bool>(
    'is_duplicate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_duplicate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _openToTradeMeta = const VerificationMeta(
    'openToTrade',
  );
  @override
  late final GeneratedColumn<bool> openToTrade = GeneratedColumn<bool>(
    'open_to_trade',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("open_to_trade" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  @override
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    barcode,
    title,
    category,
    description,
    brand,
    series,
    franchise,
    lineOrSeries,
    characterOrSubject,
    releaseYear,
    boxStatus,
    itemNumber,
    itemCondition,
    quantity,
    purchasePrice,
    estimatedValue,
    acquiredOn,
    notes,
    isFavorite,
    isGrail,
    isDuplicate,
    openToTrade,
    tagsJson,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collectibles_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectiblesLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('series')) {
      context.handle(
        _seriesMeta,
        series.isAcceptableOrUnknown(data['series']!, _seriesMeta),
      );
    }
    if (data.containsKey('franchise')) {
      context.handle(
        _franchiseMeta,
        franchise.isAcceptableOrUnknown(data['franchise']!, _franchiseMeta),
      );
    }
    if (data.containsKey('line_or_series')) {
      context.handle(
        _lineOrSeriesMeta,
        lineOrSeries.isAcceptableOrUnknown(
          data['line_or_series']!,
          _lineOrSeriesMeta,
        ),
      );
    }
    if (data.containsKey('character_or_subject')) {
      context.handle(
        _characterOrSubjectMeta,
        characterOrSubject.isAcceptableOrUnknown(
          data['character_or_subject']!,
          _characterOrSubjectMeta,
        ),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(
        _releaseYearMeta,
        releaseYear.isAcceptableOrUnknown(
          data['release_year']!,
          _releaseYearMeta,
        ),
      );
    }
    if (data.containsKey('box_status')) {
      context.handle(
        _boxStatusMeta,
        boxStatus.isAcceptableOrUnknown(data['box_status']!, _boxStatusMeta),
      );
    }
    if (data.containsKey('item_number')) {
      context.handle(
        _itemNumberMeta,
        itemNumber.isAcceptableOrUnknown(data['item_number']!, _itemNumberMeta),
      );
    }
    if (data.containsKey('item_condition')) {
      context.handle(
        _itemConditionMeta,
        itemCondition.isAcceptableOrUnknown(
          data['item_condition']!,
          _itemConditionMeta,
        ),
      );
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('purchase_price')) {
      context.handle(
        _purchasePriceMeta,
        purchasePrice.isAcceptableOrUnknown(
          data['purchase_price']!,
          _purchasePriceMeta,
        ),
      );
    }
    if (data.containsKey('estimated_value')) {
      context.handle(
        _estimatedValueMeta,
        estimatedValue.isAcceptableOrUnknown(
          data['estimated_value']!,
          _estimatedValueMeta,
        ),
      );
    }
    if (data.containsKey('acquired_on')) {
      context.handle(
        _acquiredOnMeta,
        acquiredOn.isAcceptableOrUnknown(data['acquired_on']!, _acquiredOnMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_grail')) {
      context.handle(
        _isGrailMeta,
        isGrail.isAcceptableOrUnknown(data['is_grail']!, _isGrailMeta),
      );
    }
    if (data.containsKey('is_duplicate')) {
      context.handle(
        _isDuplicateMeta,
        isDuplicate.isAcceptableOrUnknown(
          data['is_duplicate']!,
          _isDuplicateMeta,
        ),
      );
    }
    if (data.containsKey('open_to_trade')) {
      context.handle(
        _openToTradeMeta,
        openToTrade.isAcceptableOrUnknown(
          data['open_to_trade']!,
          _openToTradeMeta,
        ),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectiblesLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectiblesLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      series: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series'],
      ),
      franchise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}franchise'],
      ),
      lineOrSeries: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_or_series'],
      ),
      characterOrSubject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_or_subject'],
      ),
      releaseYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_year'],
      ),
      boxStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_status'],
      ),
      itemNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_number'],
      ),
      itemCondition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_condition'],
      ),
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      purchasePrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}purchase_price'],
      ),
      estimatedValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}estimated_value'],
      ),
      acquiredOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}acquired_on'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isGrail: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_grail'],
      )!,
      isDuplicate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_duplicate'],
      )!,
      openToTrade: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}open_to_trade'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $CollectiblesLocalTable createAlias(String alias) {
    return $CollectiblesLocalTable(attachedDatabase, alias);
  }
}

class CollectiblesLocalData extends DataClass
    implements Insertable<CollectiblesLocalData> {
  final String id;
  final String userId;
  final String? barcode;
  final String title;
  final String category;
  final String? description;
  final String? brand;
  final String? series;
  final String? franchise;
  final String? lineOrSeries;
  final String? characterOrSubject;
  final int? releaseYear;
  final String? boxStatus;
  final String? itemNumber;
  final String? itemCondition;
  final int quantity;
  final double? purchasePrice;
  final double? estimatedValue;
  final String? acquiredOn;
  final String? notes;
  final bool isFavorite;
  final bool isGrail;
  final bool isDuplicate;
  final bool openToTrade;
  final String tagsJson;
  final String? createdAt;
  final String? updatedAt;
  const CollectiblesLocalData({
    required this.id,
    required this.userId,
    this.barcode,
    required this.title,
    required this.category,
    this.description,
    this.brand,
    this.series,
    this.franchise,
    this.lineOrSeries,
    this.characterOrSubject,
    this.releaseYear,
    this.boxStatus,
    this.itemNumber,
    this.itemCondition,
    required this.quantity,
    this.purchasePrice,
    this.estimatedValue,
    this.acquiredOn,
    this.notes,
    required this.isFavorite,
    required this.isGrail,
    required this.isDuplicate,
    required this.openToTrade,
    required this.tagsJson,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || series != null) {
      map['series'] = Variable<String>(series);
    }
    if (!nullToAbsent || franchise != null) {
      map['franchise'] = Variable<String>(franchise);
    }
    if (!nullToAbsent || lineOrSeries != null) {
      map['line_or_series'] = Variable<String>(lineOrSeries);
    }
    if (!nullToAbsent || characterOrSubject != null) {
      map['character_or_subject'] = Variable<String>(characterOrSubject);
    }
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    if (!nullToAbsent || boxStatus != null) {
      map['box_status'] = Variable<String>(boxStatus);
    }
    if (!nullToAbsent || itemNumber != null) {
      map['item_number'] = Variable<String>(itemNumber);
    }
    if (!nullToAbsent || itemCondition != null) {
      map['item_condition'] = Variable<String>(itemCondition);
    }
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || purchasePrice != null) {
      map['purchase_price'] = Variable<double>(purchasePrice);
    }
    if (!nullToAbsent || estimatedValue != null) {
      map['estimated_value'] = Variable<double>(estimatedValue);
    }
    if (!nullToAbsent || acquiredOn != null) {
      map['acquired_on'] = Variable<String>(acquiredOn);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_grail'] = Variable<bool>(isGrail);
    map['is_duplicate'] = Variable<bool>(isDuplicate);
    map['open_to_trade'] = Variable<bool>(openToTrade);
    map['tags_json'] = Variable<String>(tagsJson);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  CollectiblesLocalCompanion toCompanion(bool nullToAbsent) {
    return CollectiblesLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      title: Value(title),
      category: Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      series: series == null && nullToAbsent
          ? const Value.absent()
          : Value(series),
      franchise: franchise == null && nullToAbsent
          ? const Value.absent()
          : Value(franchise),
      lineOrSeries: lineOrSeries == null && nullToAbsent
          ? const Value.absent()
          : Value(lineOrSeries),
      characterOrSubject: characterOrSubject == null && nullToAbsent
          ? const Value.absent()
          : Value(characterOrSubject),
      releaseYear: releaseYear == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseYear),
      boxStatus: boxStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(boxStatus),
      itemNumber: itemNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(itemNumber),
      itemCondition: itemCondition == null && nullToAbsent
          ? const Value.absent()
          : Value(itemCondition),
      quantity: Value(quantity),
      purchasePrice: purchasePrice == null && nullToAbsent
          ? const Value.absent()
          : Value(purchasePrice),
      estimatedValue: estimatedValue == null && nullToAbsent
          ? const Value.absent()
          : Value(estimatedValue),
      acquiredOn: acquiredOn == null && nullToAbsent
          ? const Value.absent()
          : Value(acquiredOn),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isFavorite: Value(isFavorite),
      isGrail: Value(isGrail),
      isDuplicate: Value(isDuplicate),
      openToTrade: Value(openToTrade),
      tagsJson: Value(tagsJson),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory CollectiblesLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectiblesLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      brand: serializer.fromJson<String?>(json['brand']),
      series: serializer.fromJson<String?>(json['series']),
      franchise: serializer.fromJson<String?>(json['franchise']),
      lineOrSeries: serializer.fromJson<String?>(json['lineOrSeries']),
      characterOrSubject: serializer.fromJson<String?>(
        json['characterOrSubject'],
      ),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      boxStatus: serializer.fromJson<String?>(json['boxStatus']),
      itemNumber: serializer.fromJson<String?>(json['itemNumber']),
      itemCondition: serializer.fromJson<String?>(json['itemCondition']),
      quantity: serializer.fromJson<int>(json['quantity']),
      purchasePrice: serializer.fromJson<double?>(json['purchasePrice']),
      estimatedValue: serializer.fromJson<double?>(json['estimatedValue']),
      acquiredOn: serializer.fromJson<String?>(json['acquiredOn']),
      notes: serializer.fromJson<String?>(json['notes']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isGrail: serializer.fromJson<bool>(json['isGrail']),
      isDuplicate: serializer.fromJson<bool>(json['isDuplicate']),
      openToTrade: serializer.fromJson<bool>(json['openToTrade']),
      tagsJson: serializer.fromJson<String>(json['tagsJson']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'barcode': serializer.toJson<String?>(barcode),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String?>(description),
      'brand': serializer.toJson<String?>(brand),
      'series': serializer.toJson<String?>(series),
      'franchise': serializer.toJson<String?>(franchise),
      'lineOrSeries': serializer.toJson<String?>(lineOrSeries),
      'characterOrSubject': serializer.toJson<String?>(characterOrSubject),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'boxStatus': serializer.toJson<String?>(boxStatus),
      'itemNumber': serializer.toJson<String?>(itemNumber),
      'itemCondition': serializer.toJson<String?>(itemCondition),
      'quantity': serializer.toJson<int>(quantity),
      'purchasePrice': serializer.toJson<double?>(purchasePrice),
      'estimatedValue': serializer.toJson<double?>(estimatedValue),
      'acquiredOn': serializer.toJson<String?>(acquiredOn),
      'notes': serializer.toJson<String?>(notes),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isGrail': serializer.toJson<bool>(isGrail),
      'isDuplicate': serializer.toJson<bool>(isDuplicate),
      'openToTrade': serializer.toJson<bool>(openToTrade),
      'tagsJson': serializer.toJson<String>(tagsJson),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  CollectiblesLocalData copyWith({
    String? id,
    String? userId,
    Value<String?> barcode = const Value.absent(),
    String? title,
    String? category,
    Value<String?> description = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> series = const Value.absent(),
    Value<String?> franchise = const Value.absent(),
    Value<String?> lineOrSeries = const Value.absent(),
    Value<String?> characterOrSubject = const Value.absent(),
    Value<int?> releaseYear = const Value.absent(),
    Value<String?> boxStatus = const Value.absent(),
    Value<String?> itemNumber = const Value.absent(),
    Value<String?> itemCondition = const Value.absent(),
    int? quantity,
    Value<double?> purchasePrice = const Value.absent(),
    Value<double?> estimatedValue = const Value.absent(),
    Value<String?> acquiredOn = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isFavorite,
    bool? isGrail,
    bool? isDuplicate,
    bool? openToTrade,
    String? tagsJson,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => CollectiblesLocalData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    barcode: barcode.present ? barcode.value : this.barcode,
    title: title ?? this.title,
    category: category ?? this.category,
    description: description.present ? description.value : this.description,
    brand: brand.present ? brand.value : this.brand,
    series: series.present ? series.value : this.series,
    franchise: franchise.present ? franchise.value : this.franchise,
    lineOrSeries: lineOrSeries.present ? lineOrSeries.value : this.lineOrSeries,
    characterOrSubject: characterOrSubject.present
        ? characterOrSubject.value
        : this.characterOrSubject,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    boxStatus: boxStatus.present ? boxStatus.value : this.boxStatus,
    itemNumber: itemNumber.present ? itemNumber.value : this.itemNumber,
    itemCondition: itemCondition.present
        ? itemCondition.value
        : this.itemCondition,
    quantity: quantity ?? this.quantity,
    purchasePrice: purchasePrice.present
        ? purchasePrice.value
        : this.purchasePrice,
    estimatedValue: estimatedValue.present
        ? estimatedValue.value
        : this.estimatedValue,
    acquiredOn: acquiredOn.present ? acquiredOn.value : this.acquiredOn,
    notes: notes.present ? notes.value : this.notes,
    isFavorite: isFavorite ?? this.isFavorite,
    isGrail: isGrail ?? this.isGrail,
    isDuplicate: isDuplicate ?? this.isDuplicate,
    openToTrade: openToTrade ?? this.openToTrade,
    tagsJson: tagsJson ?? this.tagsJson,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  CollectiblesLocalData copyWithCompanion(CollectiblesLocalCompanion data) {
    return CollectiblesLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      brand: data.brand.present ? data.brand.value : this.brand,
      series: data.series.present ? data.series.value : this.series,
      franchise: data.franchise.present ? data.franchise.value : this.franchise,
      lineOrSeries: data.lineOrSeries.present
          ? data.lineOrSeries.value
          : this.lineOrSeries,
      characterOrSubject: data.characterOrSubject.present
          ? data.characterOrSubject.value
          : this.characterOrSubject,
      releaseYear: data.releaseYear.present
          ? data.releaseYear.value
          : this.releaseYear,
      boxStatus: data.boxStatus.present ? data.boxStatus.value : this.boxStatus,
      itemNumber: data.itemNumber.present
          ? data.itemNumber.value
          : this.itemNumber,
      itemCondition: data.itemCondition.present
          ? data.itemCondition.value
          : this.itemCondition,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      purchasePrice: data.purchasePrice.present
          ? data.purchasePrice.value
          : this.purchasePrice,
      estimatedValue: data.estimatedValue.present
          ? data.estimatedValue.value
          : this.estimatedValue,
      acquiredOn: data.acquiredOn.present
          ? data.acquiredOn.value
          : this.acquiredOn,
      notes: data.notes.present ? data.notes.value : this.notes,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isGrail: data.isGrail.present ? data.isGrail.value : this.isGrail,
      isDuplicate: data.isDuplicate.present
          ? data.isDuplicate.value
          : this.isDuplicate,
      openToTrade: data.openToTrade.present
          ? data.openToTrade.value
          : this.openToTrade,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectiblesLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('barcode: $barcode, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('brand: $brand, ')
          ..write('series: $series, ')
          ..write('franchise: $franchise, ')
          ..write('lineOrSeries: $lineOrSeries, ')
          ..write('characterOrSubject: $characterOrSubject, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('boxStatus: $boxStatus, ')
          ..write('itemNumber: $itemNumber, ')
          ..write('itemCondition: $itemCondition, ')
          ..write('quantity: $quantity, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('estimatedValue: $estimatedValue, ')
          ..write('acquiredOn: $acquiredOn, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isGrail: $isGrail, ')
          ..write('isDuplicate: $isDuplicate, ')
          ..write('openToTrade: $openToTrade, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    userId,
    barcode,
    title,
    category,
    description,
    brand,
    series,
    franchise,
    lineOrSeries,
    characterOrSubject,
    releaseYear,
    boxStatus,
    itemNumber,
    itemCondition,
    quantity,
    purchasePrice,
    estimatedValue,
    acquiredOn,
    notes,
    isFavorite,
    isGrail,
    isDuplicate,
    openToTrade,
    tagsJson,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectiblesLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.barcode == this.barcode &&
          other.title == this.title &&
          other.category == this.category &&
          other.description == this.description &&
          other.brand == this.brand &&
          other.series == this.series &&
          other.franchise == this.franchise &&
          other.lineOrSeries == this.lineOrSeries &&
          other.characterOrSubject == this.characterOrSubject &&
          other.releaseYear == this.releaseYear &&
          other.boxStatus == this.boxStatus &&
          other.itemNumber == this.itemNumber &&
          other.itemCondition == this.itemCondition &&
          other.quantity == this.quantity &&
          other.purchasePrice == this.purchasePrice &&
          other.estimatedValue == this.estimatedValue &&
          other.acquiredOn == this.acquiredOn &&
          other.notes == this.notes &&
          other.isFavorite == this.isFavorite &&
          other.isGrail == this.isGrail &&
          other.isDuplicate == this.isDuplicate &&
          other.openToTrade == this.openToTrade &&
          other.tagsJson == this.tagsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CollectiblesLocalCompanion
    extends UpdateCompanion<CollectiblesLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String?> barcode;
  final Value<String> title;
  final Value<String> category;
  final Value<String?> description;
  final Value<String?> brand;
  final Value<String?> series;
  final Value<String?> franchise;
  final Value<String?> lineOrSeries;
  final Value<String?> characterOrSubject;
  final Value<int?> releaseYear;
  final Value<String?> boxStatus;
  final Value<String?> itemNumber;
  final Value<String?> itemCondition;
  final Value<int> quantity;
  final Value<double?> purchasePrice;
  final Value<double?> estimatedValue;
  final Value<String?> acquiredOn;
  final Value<String?> notes;
  final Value<bool> isFavorite;
  final Value<bool> isGrail;
  final Value<bool> isDuplicate;
  final Value<bool> openToTrade;
  final Value<String> tagsJson;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const CollectiblesLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.barcode = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.brand = const Value.absent(),
    this.series = const Value.absent(),
    this.franchise = const Value.absent(),
    this.lineOrSeries = const Value.absent(),
    this.characterOrSubject = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.boxStatus = const Value.absent(),
    this.itemNumber = const Value.absent(),
    this.itemCondition = const Value.absent(),
    this.quantity = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.estimatedValue = const Value.absent(),
    this.acquiredOn = const Value.absent(),
    this.notes = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isGrail = const Value.absent(),
    this.isDuplicate = const Value.absent(),
    this.openToTrade = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectiblesLocalCompanion.insert({
    required String id,
    required String userId,
    this.barcode = const Value.absent(),
    required String title,
    required String category,
    this.description = const Value.absent(),
    this.brand = const Value.absent(),
    this.series = const Value.absent(),
    this.franchise = const Value.absent(),
    this.lineOrSeries = const Value.absent(),
    this.characterOrSubject = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.boxStatus = const Value.absent(),
    this.itemNumber = const Value.absent(),
    this.itemCondition = const Value.absent(),
    this.quantity = const Value.absent(),
    this.purchasePrice = const Value.absent(),
    this.estimatedValue = const Value.absent(),
    this.acquiredOn = const Value.absent(),
    this.notes = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isGrail = const Value.absent(),
    this.isDuplicate = const Value.absent(),
    this.openToTrade = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       title = Value(title),
       category = Value(category);
  static Insertable<CollectiblesLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? barcode,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? brand,
    Expression<String>? series,
    Expression<String>? franchise,
    Expression<String>? lineOrSeries,
    Expression<String>? characterOrSubject,
    Expression<int>? releaseYear,
    Expression<String>? boxStatus,
    Expression<String>? itemNumber,
    Expression<String>? itemCondition,
    Expression<int>? quantity,
    Expression<double>? purchasePrice,
    Expression<double>? estimatedValue,
    Expression<String>? acquiredOn,
    Expression<String>? notes,
    Expression<bool>? isFavorite,
    Expression<bool>? isGrail,
    Expression<bool>? isDuplicate,
    Expression<bool>? openToTrade,
    Expression<String>? tagsJson,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (barcode != null) 'barcode': barcode,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (brand != null) 'brand': brand,
      if (series != null) 'series': series,
      if (franchise != null) 'franchise': franchise,
      if (lineOrSeries != null) 'line_or_series': lineOrSeries,
      if (characterOrSubject != null)
        'character_or_subject': characterOrSubject,
      if (releaseYear != null) 'release_year': releaseYear,
      if (boxStatus != null) 'box_status': boxStatus,
      if (itemNumber != null) 'item_number': itemNumber,
      if (itemCondition != null) 'item_condition': itemCondition,
      if (quantity != null) 'quantity': quantity,
      if (purchasePrice != null) 'purchase_price': purchasePrice,
      if (estimatedValue != null) 'estimated_value': estimatedValue,
      if (acquiredOn != null) 'acquired_on': acquiredOn,
      if (notes != null) 'notes': notes,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isGrail != null) 'is_grail': isGrail,
      if (isDuplicate != null) 'is_duplicate': isDuplicate,
      if (openToTrade != null) 'open_to_trade': openToTrade,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectiblesLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String?>? barcode,
    Value<String>? title,
    Value<String>? category,
    Value<String?>? description,
    Value<String?>? brand,
    Value<String?>? series,
    Value<String?>? franchise,
    Value<String?>? lineOrSeries,
    Value<String?>? characterOrSubject,
    Value<int?>? releaseYear,
    Value<String?>? boxStatus,
    Value<String?>? itemNumber,
    Value<String?>? itemCondition,
    Value<int>? quantity,
    Value<double?>? purchasePrice,
    Value<double?>? estimatedValue,
    Value<String?>? acquiredOn,
    Value<String?>? notes,
    Value<bool>? isFavorite,
    Value<bool>? isGrail,
    Value<bool>? isDuplicate,
    Value<bool>? openToTrade,
    Value<String>? tagsJson,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return CollectiblesLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      barcode: barcode ?? this.barcode,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      series: series ?? this.series,
      franchise: franchise ?? this.franchise,
      lineOrSeries: lineOrSeries ?? this.lineOrSeries,
      characterOrSubject: characterOrSubject ?? this.characterOrSubject,
      releaseYear: releaseYear ?? this.releaseYear,
      boxStatus: boxStatus ?? this.boxStatus,
      itemNumber: itemNumber ?? this.itemNumber,
      itemCondition: itemCondition ?? this.itemCondition,
      quantity: quantity ?? this.quantity,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      estimatedValue: estimatedValue ?? this.estimatedValue,
      acquiredOn: acquiredOn ?? this.acquiredOn,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isGrail: isGrail ?? this.isGrail,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      openToTrade: openToTrade ?? this.openToTrade,
      tagsJson: tagsJson ?? this.tagsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (series.present) {
      map['series'] = Variable<String>(series.value);
    }
    if (franchise.present) {
      map['franchise'] = Variable<String>(franchise.value);
    }
    if (lineOrSeries.present) {
      map['line_or_series'] = Variable<String>(lineOrSeries.value);
    }
    if (characterOrSubject.present) {
      map['character_or_subject'] = Variable<String>(characterOrSubject.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (boxStatus.present) {
      map['box_status'] = Variable<String>(boxStatus.value);
    }
    if (itemNumber.present) {
      map['item_number'] = Variable<String>(itemNumber.value);
    }
    if (itemCondition.present) {
      map['item_condition'] = Variable<String>(itemCondition.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (purchasePrice.present) {
      map['purchase_price'] = Variable<double>(purchasePrice.value);
    }
    if (estimatedValue.present) {
      map['estimated_value'] = Variable<double>(estimatedValue.value);
    }
    if (acquiredOn.present) {
      map['acquired_on'] = Variable<String>(acquiredOn.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isGrail.present) {
      map['is_grail'] = Variable<bool>(isGrail.value);
    }
    if (isDuplicate.present) {
      map['is_duplicate'] = Variable<bool>(isDuplicate.value);
    }
    if (openToTrade.present) {
      map['open_to_trade'] = Variable<bool>(openToTrade.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectiblesLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('barcode: $barcode, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('brand: $brand, ')
          ..write('series: $series, ')
          ..write('franchise: $franchise, ')
          ..write('lineOrSeries: $lineOrSeries, ')
          ..write('characterOrSubject: $characterOrSubject, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('boxStatus: $boxStatus, ')
          ..write('itemNumber: $itemNumber, ')
          ..write('itemCondition: $itemCondition, ')
          ..write('quantity: $quantity, ')
          ..write('purchasePrice: $purchasePrice, ')
          ..write('estimatedValue: $estimatedValue, ')
          ..write('acquiredOn: $acquiredOn, ')
          ..write('notes: $notes, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isGrail: $isGrail, ')
          ..write('isDuplicate: $isDuplicate, ')
          ..write('openToTrade: $openToTrade, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectiblePhotosLocalTable extends CollectiblePhotosLocal
    with TableInfo<$CollectiblePhotosLocalTable, CollectiblePhotosLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectiblePhotosLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectibleIdMeta = const VerificationMeta(
    'collectibleId',
  );
  @override
  late final GeneratedColumn<String> collectibleId = GeneratedColumn<String>(
    'collectible_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storageBucketMeta = const VerificationMeta(
    'storageBucket',
  );
  @override
  late final GeneratedColumn<String> storageBucket = GeneratedColumn<String>(
    'storage_bucket',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storagePathMeta = const VerificationMeta(
    'storagePath',
  );
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
    'storage_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _captionMeta = const VerificationMeta(
    'caption',
  );
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
    'caption',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isPrimaryMeta = const VerificationMeta(
    'isPrimary',
  );
  @override
  late final GeneratedColumn<bool> isPrimary = GeneratedColumn<bool>(
    'is_primary',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_primary" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    collectibleId,
    storageBucket,
    storagePath,
    caption,
    isPrimary,
    displayOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collectible_photos_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectiblePhotosLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('collectible_id')) {
      context.handle(
        _collectibleIdMeta,
        collectibleId.isAcceptableOrUnknown(
          data['collectible_id']!,
          _collectibleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectibleIdMeta);
    }
    if (data.containsKey('storage_bucket')) {
      context.handle(
        _storageBucketMeta,
        storageBucket.isAcceptableOrUnknown(
          data['storage_bucket']!,
          _storageBucketMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storageBucketMeta);
    }
    if (data.containsKey('storage_path')) {
      context.handle(
        _storagePathMeta,
        storagePath.isAcceptableOrUnknown(
          data['storage_path']!,
          _storagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storagePathMeta);
    }
    if (data.containsKey('caption')) {
      context.handle(
        _captionMeta,
        caption.isAcceptableOrUnknown(data['caption']!, _captionMeta),
      );
    }
    if (data.containsKey('is_primary')) {
      context.handle(
        _isPrimaryMeta,
        isPrimary.isAcceptableOrUnknown(data['is_primary']!, _isPrimaryMeta),
      );
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectiblePhotosLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectiblePhotosLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      collectibleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collectible_id'],
      )!,
      storageBucket: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_bucket'],
      )!,
      storagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_path'],
      )!,
      caption: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}caption'],
      ),
      isPrimary: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_primary'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $CollectiblePhotosLocalTable createAlias(String alias) {
    return $CollectiblePhotosLocalTable(attachedDatabase, alias);
  }
}

class CollectiblePhotosLocalData extends DataClass
    implements Insertable<CollectiblePhotosLocalData> {
  final String id;
  final String userId;
  final String collectibleId;
  final String storageBucket;
  final String storagePath;
  final String? caption;
  final bool isPrimary;
  final int displayOrder;
  final String? createdAt;
  final String? updatedAt;
  const CollectiblePhotosLocalData({
    required this.id,
    required this.userId,
    required this.collectibleId,
    required this.storageBucket,
    required this.storagePath,
    this.caption,
    required this.isPrimary,
    required this.displayOrder,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['collectible_id'] = Variable<String>(collectibleId);
    map['storage_bucket'] = Variable<String>(storageBucket);
    map['storage_path'] = Variable<String>(storagePath);
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['is_primary'] = Variable<bool>(isPrimary);
    map['display_order'] = Variable<int>(displayOrder);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  CollectiblePhotosLocalCompanion toCompanion(bool nullToAbsent) {
    return CollectiblePhotosLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      collectibleId: Value(collectibleId),
      storageBucket: Value(storageBucket),
      storagePath: Value(storagePath),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      isPrimary: Value(isPrimary),
      displayOrder: Value(displayOrder),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory CollectiblePhotosLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectiblePhotosLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      collectibleId: serializer.fromJson<String>(json['collectibleId']),
      storageBucket: serializer.fromJson<String>(json['storageBucket']),
      storagePath: serializer.fromJson<String>(json['storagePath']),
      caption: serializer.fromJson<String?>(json['caption']),
      isPrimary: serializer.fromJson<bool>(json['isPrimary']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'collectibleId': serializer.toJson<String>(collectibleId),
      'storageBucket': serializer.toJson<String>(storageBucket),
      'storagePath': serializer.toJson<String>(storagePath),
      'caption': serializer.toJson<String?>(caption),
      'isPrimary': serializer.toJson<bool>(isPrimary),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  CollectiblePhotosLocalData copyWith({
    String? id,
    String? userId,
    String? collectibleId,
    String? storageBucket,
    String? storagePath,
    Value<String?> caption = const Value.absent(),
    bool? isPrimary,
    int? displayOrder,
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => CollectiblePhotosLocalData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    collectibleId: collectibleId ?? this.collectibleId,
    storageBucket: storageBucket ?? this.storageBucket,
    storagePath: storagePath ?? this.storagePath,
    caption: caption.present ? caption.value : this.caption,
    isPrimary: isPrimary ?? this.isPrimary,
    displayOrder: displayOrder ?? this.displayOrder,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  CollectiblePhotosLocalData copyWithCompanion(
    CollectiblePhotosLocalCompanion data,
  ) {
    return CollectiblePhotosLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      collectibleId: data.collectibleId.present
          ? data.collectibleId.value
          : this.collectibleId,
      storageBucket: data.storageBucket.present
          ? data.storageBucket.value
          : this.storageBucket,
      storagePath: data.storagePath.present
          ? data.storagePath.value
          : this.storagePath,
      caption: data.caption.present ? data.caption.value : this.caption,
      isPrimary: data.isPrimary.present ? data.isPrimary.value : this.isPrimary,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectiblePhotosLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('collectibleId: $collectibleId, ')
          ..write('storageBucket: $storageBucket, ')
          ..write('storagePath: $storagePath, ')
          ..write('caption: $caption, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    collectibleId,
    storageBucket,
    storagePath,
    caption,
    isPrimary,
    displayOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectiblePhotosLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.collectibleId == this.collectibleId &&
          other.storageBucket == this.storageBucket &&
          other.storagePath == this.storagePath &&
          other.caption == this.caption &&
          other.isPrimary == this.isPrimary &&
          other.displayOrder == this.displayOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CollectiblePhotosLocalCompanion
    extends UpdateCompanion<CollectiblePhotosLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> collectibleId;
  final Value<String> storageBucket;
  final Value<String> storagePath;
  final Value<String?> caption;
  final Value<bool> isPrimary;
  final Value<int> displayOrder;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const CollectiblePhotosLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.collectibleId = const Value.absent(),
    this.storageBucket = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.caption = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectiblePhotosLocalCompanion.insert({
    required String id,
    required String userId,
    required String collectibleId,
    required String storageBucket,
    required String storagePath,
    this.caption = const Value.absent(),
    this.isPrimary = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       collectibleId = Value(collectibleId),
       storageBucket = Value(storageBucket),
       storagePath = Value(storagePath);
  static Insertable<CollectiblePhotosLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? collectibleId,
    Expression<String>? storageBucket,
    Expression<String>? storagePath,
    Expression<String>? caption,
    Expression<bool>? isPrimary,
    Expression<int>? displayOrder,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (collectibleId != null) 'collectible_id': collectibleId,
      if (storageBucket != null) 'storage_bucket': storageBucket,
      if (storagePath != null) 'storage_path': storagePath,
      if (caption != null) 'caption': caption,
      if (isPrimary != null) 'is_primary': isPrimary,
      if (displayOrder != null) 'display_order': displayOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectiblePhotosLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? collectibleId,
    Value<String>? storageBucket,
    Value<String>? storagePath,
    Value<String?>? caption,
    Value<bool>? isPrimary,
    Value<int>? displayOrder,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return CollectiblePhotosLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      collectibleId: collectibleId ?? this.collectibleId,
      storageBucket: storageBucket ?? this.storageBucket,
      storagePath: storagePath ?? this.storagePath,
      caption: caption ?? this.caption,
      isPrimary: isPrimary ?? this.isPrimary,
      displayOrder: displayOrder ?? this.displayOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (collectibleId.present) {
      map['collectible_id'] = Variable<String>(collectibleId.value);
    }
    if (storageBucket.present) {
      map['storage_bucket'] = Variable<String>(storageBucket.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (isPrimary.present) {
      map['is_primary'] = Variable<bool>(isPrimary.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectiblePhotosLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('collectibleId: $collectibleId, ')
          ..write('storageBucket: $storageBucket, ')
          ..write('storagePath: $storagePath, ')
          ..write('caption: $caption, ')
          ..write('isPrimary: $isPrimary, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WishlistItemsLocalTable extends WishlistItemsLocal
    with TableInfo<$WishlistItemsLocalTable, WishlistItemsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WishlistItemsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _seriesMeta = const VerificationMeta('series');
  @override
  late final GeneratedColumn<String> series = GeneratedColumn<String>(
    'series',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _franchiseMeta = const VerificationMeta(
    'franchise',
  );
  @override
  late final GeneratedColumn<String> franchise = GeneratedColumn<String>(
    'franchise',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lineOrSeriesMeta = const VerificationMeta(
    'lineOrSeries',
  );
  @override
  late final GeneratedColumn<String> lineOrSeries = GeneratedColumn<String>(
    'line_or_series',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _characterOrSubjectMeta =
      const VerificationMeta('characterOrSubject');
  @override
  late final GeneratedColumn<String> characterOrSubject =
      GeneratedColumn<String>(
        'character_or_subject',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _releaseYearMeta = const VerificationMeta(
    'releaseYear',
  );
  @override
  late final GeneratedColumn<int> releaseYear = GeneratedColumn<int>(
    'release_year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _boxStatusMeta = const VerificationMeta(
    'boxStatus',
  );
  @override
  late final GeneratedColumn<String> boxStatus = GeneratedColumn<String>(
    'box_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetPriceMeta = const VerificationMeta(
    'targetPrice',
  );
  @override
  late final GeneratedColumn<double> targetPrice = GeneratedColumn<double>(
    'target_price',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    category,
    description,
    brand,
    series,
    franchise,
    lineOrSeries,
    characterOrSubject,
    releaseYear,
    boxStatus,
    priority,
    targetPrice,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'wishlist_items_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<WishlistItemsLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('series')) {
      context.handle(
        _seriesMeta,
        series.isAcceptableOrUnknown(data['series']!, _seriesMeta),
      );
    }
    if (data.containsKey('franchise')) {
      context.handle(
        _franchiseMeta,
        franchise.isAcceptableOrUnknown(data['franchise']!, _franchiseMeta),
      );
    }
    if (data.containsKey('line_or_series')) {
      context.handle(
        _lineOrSeriesMeta,
        lineOrSeries.isAcceptableOrUnknown(
          data['line_or_series']!,
          _lineOrSeriesMeta,
        ),
      );
    }
    if (data.containsKey('character_or_subject')) {
      context.handle(
        _characterOrSubjectMeta,
        characterOrSubject.isAcceptableOrUnknown(
          data['character_or_subject']!,
          _characterOrSubjectMeta,
        ),
      );
    }
    if (data.containsKey('release_year')) {
      context.handle(
        _releaseYearMeta,
        releaseYear.isAcceptableOrUnknown(
          data['release_year']!,
          _releaseYearMeta,
        ),
      );
    }
    if (data.containsKey('box_status')) {
      context.handle(
        _boxStatusMeta,
        boxStatus.isAcceptableOrUnknown(data['box_status']!, _boxStatusMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('target_price')) {
      context.handle(
        _targetPriceMeta,
        targetPrice.isAcceptableOrUnknown(
          data['target_price']!,
          _targetPriceMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WishlistItemsLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WishlistItemsLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      series: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}series'],
      ),
      franchise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}franchise'],
      ),
      lineOrSeries: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line_or_series'],
      ),
      characterOrSubject: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}character_or_subject'],
      ),
      releaseYear: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}release_year'],
      ),
      boxStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}box_status'],
      ),
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      ),
      targetPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_price'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  $WishlistItemsLocalTable createAlias(String alias) {
    return $WishlistItemsLocalTable(attachedDatabase, alias);
  }
}

class WishlistItemsLocalData extends DataClass
    implements Insertable<WishlistItemsLocalData> {
  final String id;
  final String userId;
  final String title;
  final String category;
  final String? description;
  final String? brand;
  final String? series;
  final String? franchise;
  final String? lineOrSeries;
  final String? characterOrSubject;
  final int? releaseYear;
  final String? boxStatus;
  final String? priority;
  final double? targetPrice;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  const WishlistItemsLocalData({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    this.description,
    this.brand,
    this.series,
    this.franchise,
    this.lineOrSeries,
    this.characterOrSubject,
    this.releaseYear,
    this.boxStatus,
    this.priority,
    this.targetPrice,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || series != null) {
      map['series'] = Variable<String>(series);
    }
    if (!nullToAbsent || franchise != null) {
      map['franchise'] = Variable<String>(franchise);
    }
    if (!nullToAbsent || lineOrSeries != null) {
      map['line_or_series'] = Variable<String>(lineOrSeries);
    }
    if (!nullToAbsent || characterOrSubject != null) {
      map['character_or_subject'] = Variable<String>(characterOrSubject);
    }
    if (!nullToAbsent || releaseYear != null) {
      map['release_year'] = Variable<int>(releaseYear);
    }
    if (!nullToAbsent || boxStatus != null) {
      map['box_status'] = Variable<String>(boxStatus);
    }
    if (!nullToAbsent || priority != null) {
      map['priority'] = Variable<String>(priority);
    }
    if (!nullToAbsent || targetPrice != null) {
      map['target_price'] = Variable<double>(targetPrice);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<String>(updatedAt);
    }
    return map;
  }

  WishlistItemsLocalCompanion toCompanion(bool nullToAbsent) {
    return WishlistItemsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      category: Value(category),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      series: series == null && nullToAbsent
          ? const Value.absent()
          : Value(series),
      franchise: franchise == null && nullToAbsent
          ? const Value.absent()
          : Value(franchise),
      lineOrSeries: lineOrSeries == null && nullToAbsent
          ? const Value.absent()
          : Value(lineOrSeries),
      characterOrSubject: characterOrSubject == null && nullToAbsent
          ? const Value.absent()
          : Value(characterOrSubject),
      releaseYear: releaseYear == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseYear),
      boxStatus: boxStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(boxStatus),
      priority: priority == null && nullToAbsent
          ? const Value.absent()
          : Value(priority),
      targetPrice: targetPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(targetPrice),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory WishlistItemsLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WishlistItemsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      category: serializer.fromJson<String>(json['category']),
      description: serializer.fromJson<String?>(json['description']),
      brand: serializer.fromJson<String?>(json['brand']),
      series: serializer.fromJson<String?>(json['series']),
      franchise: serializer.fromJson<String?>(json['franchise']),
      lineOrSeries: serializer.fromJson<String?>(json['lineOrSeries']),
      characterOrSubject: serializer.fromJson<String?>(
        json['characterOrSubject'],
      ),
      releaseYear: serializer.fromJson<int?>(json['releaseYear']),
      boxStatus: serializer.fromJson<String?>(json['boxStatus']),
      priority: serializer.fromJson<String?>(json['priority']),
      targetPrice: serializer.fromJson<double?>(json['targetPrice']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
      updatedAt: serializer.fromJson<String?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'category': serializer.toJson<String>(category),
      'description': serializer.toJson<String?>(description),
      'brand': serializer.toJson<String?>(brand),
      'series': serializer.toJson<String?>(series),
      'franchise': serializer.toJson<String?>(franchise),
      'lineOrSeries': serializer.toJson<String?>(lineOrSeries),
      'characterOrSubject': serializer.toJson<String?>(characterOrSubject),
      'releaseYear': serializer.toJson<int?>(releaseYear),
      'boxStatus': serializer.toJson<String?>(boxStatus),
      'priority': serializer.toJson<String?>(priority),
      'targetPrice': serializer.toJson<double?>(targetPrice),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<String?>(createdAt),
      'updatedAt': serializer.toJson<String?>(updatedAt),
    };
  }

  WishlistItemsLocalData copyWith({
    String? id,
    String? userId,
    String? title,
    String? category,
    Value<String?> description = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> series = const Value.absent(),
    Value<String?> franchise = const Value.absent(),
    Value<String?> lineOrSeries = const Value.absent(),
    Value<String?> characterOrSubject = const Value.absent(),
    Value<int?> releaseYear = const Value.absent(),
    Value<String?> boxStatus = const Value.absent(),
    Value<String?> priority = const Value.absent(),
    Value<double?> targetPrice = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> createdAt = const Value.absent(),
    Value<String?> updatedAt = const Value.absent(),
  }) => WishlistItemsLocalData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    category: category ?? this.category,
    description: description.present ? description.value : this.description,
    brand: brand.present ? brand.value : this.brand,
    series: series.present ? series.value : this.series,
    franchise: franchise.present ? franchise.value : this.franchise,
    lineOrSeries: lineOrSeries.present ? lineOrSeries.value : this.lineOrSeries,
    characterOrSubject: characterOrSubject.present
        ? characterOrSubject.value
        : this.characterOrSubject,
    releaseYear: releaseYear.present ? releaseYear.value : this.releaseYear,
    boxStatus: boxStatus.present ? boxStatus.value : this.boxStatus,
    priority: priority.present ? priority.value : this.priority,
    targetPrice: targetPrice.present ? targetPrice.value : this.targetPrice,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  WishlistItemsLocalData copyWithCompanion(WishlistItemsLocalCompanion data) {
    return WishlistItemsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      category: data.category.present ? data.category.value : this.category,
      description: data.description.present
          ? data.description.value
          : this.description,
      brand: data.brand.present ? data.brand.value : this.brand,
      series: data.series.present ? data.series.value : this.series,
      franchise: data.franchise.present ? data.franchise.value : this.franchise,
      lineOrSeries: data.lineOrSeries.present
          ? data.lineOrSeries.value
          : this.lineOrSeries,
      characterOrSubject: data.characterOrSubject.present
          ? data.characterOrSubject.value
          : this.characterOrSubject,
      releaseYear: data.releaseYear.present
          ? data.releaseYear.value
          : this.releaseYear,
      boxStatus: data.boxStatus.present ? data.boxStatus.value : this.boxStatus,
      priority: data.priority.present ? data.priority.value : this.priority,
      targetPrice: data.targetPrice.present
          ? data.targetPrice.value
          : this.targetPrice,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WishlistItemsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('brand: $brand, ')
          ..write('series: $series, ')
          ..write('franchise: $franchise, ')
          ..write('lineOrSeries: $lineOrSeries, ')
          ..write('characterOrSubject: $characterOrSubject, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('boxStatus: $boxStatus, ')
          ..write('priority: $priority, ')
          ..write('targetPrice: $targetPrice, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    category,
    description,
    brand,
    series,
    franchise,
    lineOrSeries,
    characterOrSubject,
    releaseYear,
    boxStatus,
    priority,
    targetPrice,
    notes,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WishlistItemsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.category == this.category &&
          other.description == this.description &&
          other.brand == this.brand &&
          other.series == this.series &&
          other.franchise == this.franchise &&
          other.lineOrSeries == this.lineOrSeries &&
          other.characterOrSubject == this.characterOrSubject &&
          other.releaseYear == this.releaseYear &&
          other.boxStatus == this.boxStatus &&
          other.priority == this.priority &&
          other.targetPrice == this.targetPrice &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WishlistItemsLocalCompanion
    extends UpdateCompanion<WishlistItemsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String> category;
  final Value<String?> description;
  final Value<String?> brand;
  final Value<String?> series;
  final Value<String?> franchise;
  final Value<String?> lineOrSeries;
  final Value<String?> characterOrSubject;
  final Value<int?> releaseYear;
  final Value<String?> boxStatus;
  final Value<String?> priority;
  final Value<double?> targetPrice;
  final Value<String?> notes;
  final Value<String?> createdAt;
  final Value<String?> updatedAt;
  final Value<int> rowid;
  const WishlistItemsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.category = const Value.absent(),
    this.description = const Value.absent(),
    this.brand = const Value.absent(),
    this.series = const Value.absent(),
    this.franchise = const Value.absent(),
    this.lineOrSeries = const Value.absent(),
    this.characterOrSubject = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.boxStatus = const Value.absent(),
    this.priority = const Value.absent(),
    this.targetPrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WishlistItemsLocalCompanion.insert({
    required String id,
    required String userId,
    required String title,
    required String category,
    this.description = const Value.absent(),
    this.brand = const Value.absent(),
    this.series = const Value.absent(),
    this.franchise = const Value.absent(),
    this.lineOrSeries = const Value.absent(),
    this.characterOrSubject = const Value.absent(),
    this.releaseYear = const Value.absent(),
    this.boxStatus = const Value.absent(),
    this.priority = const Value.absent(),
    this.targetPrice = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       title = Value(title),
       category = Value(category);
  static Insertable<WishlistItemsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? category,
    Expression<String>? description,
    Expression<String>? brand,
    Expression<String>? series,
    Expression<String>? franchise,
    Expression<String>? lineOrSeries,
    Expression<String>? characterOrSubject,
    Expression<int>? releaseYear,
    Expression<String>? boxStatus,
    Expression<String>? priority,
    Expression<double>? targetPrice,
    Expression<String>? notes,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (category != null) 'category': category,
      if (description != null) 'description': description,
      if (brand != null) 'brand': brand,
      if (series != null) 'series': series,
      if (franchise != null) 'franchise': franchise,
      if (lineOrSeries != null) 'line_or_series': lineOrSeries,
      if (characterOrSubject != null)
        'character_or_subject': characterOrSubject,
      if (releaseYear != null) 'release_year': releaseYear,
      if (boxStatus != null) 'box_status': boxStatus,
      if (priority != null) 'priority': priority,
      if (targetPrice != null) 'target_price': targetPrice,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WishlistItemsLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<String>? category,
    Value<String?>? description,
    Value<String?>? brand,
    Value<String?>? series,
    Value<String?>? franchise,
    Value<String?>? lineOrSeries,
    Value<String?>? characterOrSubject,
    Value<int?>? releaseYear,
    Value<String?>? boxStatus,
    Value<String?>? priority,
    Value<double?>? targetPrice,
    Value<String?>? notes,
    Value<String?>? createdAt,
    Value<String?>? updatedAt,
    Value<int>? rowid,
  }) {
    return WishlistItemsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      series: series ?? this.series,
      franchise: franchise ?? this.franchise,
      lineOrSeries: lineOrSeries ?? this.lineOrSeries,
      characterOrSubject: characterOrSubject ?? this.characterOrSubject,
      releaseYear: releaseYear ?? this.releaseYear,
      boxStatus: boxStatus ?? this.boxStatus,
      priority: priority ?? this.priority,
      targetPrice: targetPrice ?? this.targetPrice,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (series.present) {
      map['series'] = Variable<String>(series.value);
    }
    if (franchise.present) {
      map['franchise'] = Variable<String>(franchise.value);
    }
    if (lineOrSeries.present) {
      map['line_or_series'] = Variable<String>(lineOrSeries.value);
    }
    if (characterOrSubject.present) {
      map['character_or_subject'] = Variable<String>(characterOrSubject.value);
    }
    if (releaseYear.present) {
      map['release_year'] = Variable<int>(releaseYear.value);
    }
    if (boxStatus.present) {
      map['box_status'] = Variable<String>(boxStatus.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (targetPrice.present) {
      map['target_price'] = Variable<double>(targetPrice.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WishlistItemsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('category: $category, ')
          ..write('description: $description, ')
          ..write('brand: $brand, ')
          ..write('series: $series, ')
          ..write('franchise: $franchise, ')
          ..write('lineOrSeries: $lineOrSeries, ')
          ..write('characterOrSubject: $characterOrSubject, ')
          ..write('releaseYear: $releaseYear, ')
          ..write('boxStatus: $boxStatus, ')
          ..write('priority: $priority, ')
          ..write('targetPrice: $targetPrice, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsLocalTable extends TagsLocal
    with TableInfo<$TagsLocalTable, TagsLocalData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, userId, name, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagsLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TagsLocalData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagsLocalData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $TagsLocalTable createAlias(String alias) {
    return $TagsLocalTable(attachedDatabase, alias);
  }
}

class TagsLocalData extends DataClass implements Insertable<TagsLocalData> {
  final String id;
  final String userId;
  final String name;
  final String? createdAt;
  const TagsLocalData({
    required this.id,
    required this.userId,
    required this.name,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  TagsLocalCompanion toCompanion(bool nullToAbsent) {
    return TagsLocalCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory TagsLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagsLocalData(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  TagsLocalData copyWith({
    String? id,
    String? userId,
    String? name,
    Value<String?> createdAt = const Value.absent(),
  }) => TagsLocalData(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  TagsLocalData copyWithCompanion(TagsLocalCompanion data) {
    return TagsLocalData(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagsLocalData(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, userId, name, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagsLocalData &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.createdAt == this.createdAt);
}

class TagsLocalCompanion extends UpdateCompanion<TagsLocalData> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> createdAt;
  final Value<int> rowid;
  const TagsLocalCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsLocalCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name);
  static Insertable<TagsLocalData> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsLocalCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? createdAt,
    Value<int>? rowid,
  }) {
    return TagsLocalCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsLocalCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectibleTagLinksLocalTable extends CollectibleTagLinksLocal
    with
        TableInfo<
          $CollectibleTagLinksLocalTable,
          CollectibleTagLinksLocalData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectibleTagLinksLocalTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectibleIdMeta = const VerificationMeta(
    'collectibleId',
  );
  @override
  late final GeneratedColumn<String> collectibleId = GeneratedColumn<String>(
    'collectible_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    collectibleId,
    tagId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collectible_tag_links_local';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectibleTagLinksLocalData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('collectible_id')) {
      context.handle(
        _collectibleIdMeta,
        collectibleId.isAcceptableOrUnknown(
          data['collectible_id']!,
          _collectibleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectibleIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId, collectibleId, tagId};
  @override
  CollectibleTagLinksLocalData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectibleTagLinksLocalData(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      collectibleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collectible_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $CollectibleTagLinksLocalTable createAlias(String alias) {
    return $CollectibleTagLinksLocalTable(attachedDatabase, alias);
  }
}

class CollectibleTagLinksLocalData extends DataClass
    implements Insertable<CollectibleTagLinksLocalData> {
  final String userId;
  final String collectibleId;
  final String tagId;
  final String? createdAt;
  const CollectibleTagLinksLocalData({
    required this.userId,
    required this.collectibleId,
    required this.tagId,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    map['collectible_id'] = Variable<String>(collectibleId);
    map['tag_id'] = Variable<String>(tagId);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  CollectibleTagLinksLocalCompanion toCompanion(bool nullToAbsent) {
    return CollectibleTagLinksLocalCompanion(
      userId: Value(userId),
      collectibleId: Value(collectibleId),
      tagId: Value(tagId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory CollectibleTagLinksLocalData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectibleTagLinksLocalData(
      userId: serializer.fromJson<String>(json['userId']),
      collectibleId: serializer.fromJson<String>(json['collectibleId']),
      tagId: serializer.fromJson<String>(json['tagId']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'collectibleId': serializer.toJson<String>(collectibleId),
      'tagId': serializer.toJson<String>(tagId),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  CollectibleTagLinksLocalData copyWith({
    String? userId,
    String? collectibleId,
    String? tagId,
    Value<String?> createdAt = const Value.absent(),
  }) => CollectibleTagLinksLocalData(
    userId: userId ?? this.userId,
    collectibleId: collectibleId ?? this.collectibleId,
    tagId: tagId ?? this.tagId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  CollectibleTagLinksLocalData copyWithCompanion(
    CollectibleTagLinksLocalCompanion data,
  ) {
    return CollectibleTagLinksLocalData(
      userId: data.userId.present ? data.userId.value : this.userId,
      collectibleId: data.collectibleId.present
          ? data.collectibleId.value
          : this.collectibleId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectibleTagLinksLocalData(')
          ..write('userId: $userId, ')
          ..write('collectibleId: $collectibleId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(userId, collectibleId, tagId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectibleTagLinksLocalData &&
          other.userId == this.userId &&
          other.collectibleId == this.collectibleId &&
          other.tagId == this.tagId &&
          other.createdAt == this.createdAt);
}

class CollectibleTagLinksLocalCompanion
    extends UpdateCompanion<CollectibleTagLinksLocalData> {
  final Value<String> userId;
  final Value<String> collectibleId;
  final Value<String> tagId;
  final Value<String?> createdAt;
  final Value<int> rowid;
  const CollectibleTagLinksLocalCompanion({
    this.userId = const Value.absent(),
    this.collectibleId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectibleTagLinksLocalCompanion.insert({
    required String userId,
    required String collectibleId,
    required String tagId,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId),
       collectibleId = Value(collectibleId),
       tagId = Value(tagId);
  static Insertable<CollectibleTagLinksLocalData> custom({
    Expression<String>? userId,
    Expression<String>? collectibleId,
    Expression<String>? tagId,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (collectibleId != null) 'collectible_id': collectibleId,
      if (tagId != null) 'tag_id': tagId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectibleTagLinksLocalCompanion copyWith({
    Value<String>? userId,
    Value<String>? collectibleId,
    Value<String>? tagId,
    Value<String?>? createdAt,
    Value<int>? rowid,
  }) {
    return CollectibleTagLinksLocalCompanion(
      userId: userId ?? this.userId,
      collectibleId: collectibleId ?? this.collectibleId,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (collectibleId.present) {
      map['collectible_id'] = Variable<String>(collectibleId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectibleTagLinksLocalCompanion(')
          ..write('userId: $userId, ')
          ..write('collectibleId: $collectibleId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArchiveSyncStatesTable extends ArchiveSyncStates
    with TableInfo<$ArchiveSyncStatesTable, ArchiveSyncState> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArchiveSyncStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteSyncStampMeta = const VerificationMeta(
    'remoteSyncStamp',
  );
  @override
  late final GeneratedColumn<String> remoteSyncStamp = GeneratedColumn<String>(
    'remote_sync_stamp',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<String> lastSyncAt = GeneratedColumn<String>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSyncCheckAtMeta = const VerificationMeta(
    'lastSyncCheckAt',
  );
  @override
  late final GeneratedColumn<String> lastSyncCheckAt = GeneratedColumn<String>(
    'last_sync_check_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasCompletedInitialSyncMeta =
      const VerificationMeta('hasCompletedInitialSync');
  @override
  late final GeneratedColumn<bool> hasCompletedInitialSync =
      GeneratedColumn<bool>(
        'has_completed_initial_sync',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_completed_initial_sync" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  @override
  List<GeneratedColumn> get $columns => [
    userId,
    remoteSyncStamp,
    lastSyncAt,
    lastSyncCheckAt,
    hasCompletedInitialSync,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'archive_sync_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArchiveSyncState> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('remote_sync_stamp')) {
      context.handle(
        _remoteSyncStampMeta,
        remoteSyncStamp.isAcceptableOrUnknown(
          data['remote_sync_stamp']!,
          _remoteSyncStampMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_check_at')) {
      context.handle(
        _lastSyncCheckAtMeta,
        lastSyncCheckAt.isAcceptableOrUnknown(
          data['last_sync_check_at']!,
          _lastSyncCheckAtMeta,
        ),
      );
    }
    if (data.containsKey('has_completed_initial_sync')) {
      context.handle(
        _hasCompletedInitialSyncMeta,
        hasCompletedInitialSync.isAcceptableOrUnknown(
          data['has_completed_initial_sync']!,
          _hasCompletedInitialSyncMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userId};
  @override
  ArchiveSyncState map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArchiveSyncState(
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      remoteSyncStamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_sync_stamp'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_at'],
      ),
      lastSyncCheckAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_sync_check_at'],
      ),
      hasCompletedInitialSync: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_completed_initial_sync'],
      )!,
    );
  }

  @override
  $ArchiveSyncStatesTable createAlias(String alias) {
    return $ArchiveSyncStatesTable(attachedDatabase, alias);
  }
}

class ArchiveSyncState extends DataClass
    implements Insertable<ArchiveSyncState> {
  final String userId;
  final String? remoteSyncStamp;
  final String? lastSyncAt;
  final String? lastSyncCheckAt;
  final bool hasCompletedInitialSync;
  const ArchiveSyncState({
    required this.userId,
    this.remoteSyncStamp,
    this.lastSyncAt,
    this.lastSyncCheckAt,
    required this.hasCompletedInitialSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_id'] = Variable<String>(userId);
    if (!nullToAbsent || remoteSyncStamp != null) {
      map['remote_sync_stamp'] = Variable<String>(remoteSyncStamp);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<String>(lastSyncAt);
    }
    if (!nullToAbsent || lastSyncCheckAt != null) {
      map['last_sync_check_at'] = Variable<String>(lastSyncCheckAt);
    }
    map['has_completed_initial_sync'] = Variable<bool>(hasCompletedInitialSync);
    return map;
  }

  ArchiveSyncStatesCompanion toCompanion(bool nullToAbsent) {
    return ArchiveSyncStatesCompanion(
      userId: Value(userId),
      remoteSyncStamp: remoteSyncStamp == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteSyncStamp),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      lastSyncCheckAt: lastSyncCheckAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncCheckAt),
      hasCompletedInitialSync: Value(hasCompletedInitialSync),
    );
  }

  factory ArchiveSyncState.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArchiveSyncState(
      userId: serializer.fromJson<String>(json['userId']),
      remoteSyncStamp: serializer.fromJson<String?>(json['remoteSyncStamp']),
      lastSyncAt: serializer.fromJson<String?>(json['lastSyncAt']),
      lastSyncCheckAt: serializer.fromJson<String?>(json['lastSyncCheckAt']),
      hasCompletedInitialSync: serializer.fromJson<bool>(
        json['hasCompletedInitialSync'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userId': serializer.toJson<String>(userId),
      'remoteSyncStamp': serializer.toJson<String?>(remoteSyncStamp),
      'lastSyncAt': serializer.toJson<String?>(lastSyncAt),
      'lastSyncCheckAt': serializer.toJson<String?>(lastSyncCheckAt),
      'hasCompletedInitialSync': serializer.toJson<bool>(
        hasCompletedInitialSync,
      ),
    };
  }

  ArchiveSyncState copyWith({
    String? userId,
    Value<String?> remoteSyncStamp = const Value.absent(),
    Value<String?> lastSyncAt = const Value.absent(),
    Value<String?> lastSyncCheckAt = const Value.absent(),
    bool? hasCompletedInitialSync,
  }) => ArchiveSyncState(
    userId: userId ?? this.userId,
    remoteSyncStamp: remoteSyncStamp.present
        ? remoteSyncStamp.value
        : this.remoteSyncStamp,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    lastSyncCheckAt: lastSyncCheckAt.present
        ? lastSyncCheckAt.value
        : this.lastSyncCheckAt,
    hasCompletedInitialSync:
        hasCompletedInitialSync ?? this.hasCompletedInitialSync,
  );
  ArchiveSyncState copyWithCompanion(ArchiveSyncStatesCompanion data) {
    return ArchiveSyncState(
      userId: data.userId.present ? data.userId.value : this.userId,
      remoteSyncStamp: data.remoteSyncStamp.present
          ? data.remoteSyncStamp.value
          : this.remoteSyncStamp,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      lastSyncCheckAt: data.lastSyncCheckAt.present
          ? data.lastSyncCheckAt.value
          : this.lastSyncCheckAt,
      hasCompletedInitialSync: data.hasCompletedInitialSync.present
          ? data.hasCompletedInitialSync.value
          : this.hasCompletedInitialSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArchiveSyncState(')
          ..write('userId: $userId, ')
          ..write('remoteSyncStamp: $remoteSyncStamp, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncCheckAt: $lastSyncCheckAt, ')
          ..write('hasCompletedInitialSync: $hasCompletedInitialSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userId,
    remoteSyncStamp,
    lastSyncAt,
    lastSyncCheckAt,
    hasCompletedInitialSync,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArchiveSyncState &&
          other.userId == this.userId &&
          other.remoteSyncStamp == this.remoteSyncStamp &&
          other.lastSyncAt == this.lastSyncAt &&
          other.lastSyncCheckAt == this.lastSyncCheckAt &&
          other.hasCompletedInitialSync == this.hasCompletedInitialSync);
}

class ArchiveSyncStatesCompanion extends UpdateCompanion<ArchiveSyncState> {
  final Value<String> userId;
  final Value<String?> remoteSyncStamp;
  final Value<String?> lastSyncAt;
  final Value<String?> lastSyncCheckAt;
  final Value<bool> hasCompletedInitialSync;
  final Value<int> rowid;
  const ArchiveSyncStatesCompanion({
    this.userId = const Value.absent(),
    this.remoteSyncStamp = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncCheckAt = const Value.absent(),
    this.hasCompletedInitialSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArchiveSyncStatesCompanion.insert({
    required String userId,
    this.remoteSyncStamp = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.lastSyncCheckAt = const Value.absent(),
    this.hasCompletedInitialSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : userId = Value(userId);
  static Insertable<ArchiveSyncState> custom({
    Expression<String>? userId,
    Expression<String>? remoteSyncStamp,
    Expression<String>? lastSyncAt,
    Expression<String>? lastSyncCheckAt,
    Expression<bool>? hasCompletedInitialSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userId != null) 'user_id': userId,
      if (remoteSyncStamp != null) 'remote_sync_stamp': remoteSyncStamp,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (lastSyncCheckAt != null) 'last_sync_check_at': lastSyncCheckAt,
      if (hasCompletedInitialSync != null)
        'has_completed_initial_sync': hasCompletedInitialSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArchiveSyncStatesCompanion copyWith({
    Value<String>? userId,
    Value<String?>? remoteSyncStamp,
    Value<String?>? lastSyncAt,
    Value<String?>? lastSyncCheckAt,
    Value<bool>? hasCompletedInitialSync,
    Value<int>? rowid,
  }) {
    return ArchiveSyncStatesCompanion(
      userId: userId ?? this.userId,
      remoteSyncStamp: remoteSyncStamp ?? this.remoteSyncStamp,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncCheckAt: lastSyncCheckAt ?? this.lastSyncCheckAt,
      hasCompletedInitialSync:
          hasCompletedInitialSync ?? this.hasCompletedInitialSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (remoteSyncStamp.present) {
      map['remote_sync_stamp'] = Variable<String>(remoteSyncStamp.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<String>(lastSyncAt.value);
    }
    if (lastSyncCheckAt.present) {
      map['last_sync_check_at'] = Variable<String>(lastSyncCheckAt.value);
    }
    if (hasCompletedInitialSync.present) {
      map['has_completed_initial_sync'] = Variable<bool>(
        hasCompletedInitialSync.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArchiveSyncStatesCompanion(')
          ..write('userId: $userId, ')
          ..write('remoteSyncStamp: $remoteSyncStamp, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('lastSyncCheckAt: $lastSyncCheckAt, ')
          ..write('hasCompletedInitialSync: $hasCompletedInitialSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotoCacheEntriesTable extends PhotoCacheEntries
    with TableInfo<$PhotoCacheEntriesTable, PhotoCacheEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoCacheEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _photoIdMeta = const VerificationMeta(
    'photoId',
  );
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
    'photo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _collectibleIdMeta = const VerificationMeta(
    'collectibleId',
  );
  @override
  late final GeneratedColumn<String> collectibleId = GeneratedColumn<String>(
    'collectible_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _storagePathMeta = const VerificationMeta(
    'storagePath',
  );
  @override
  late final GeneratedColumn<String> storagePath = GeneratedColumn<String>(
    'storage_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUrlMeta = const VerificationMeta(
    'remoteUrl',
  );
  @override
  late final GeneratedColumn<String> remoteUrl = GeneratedColumn<String>(
    'remote_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteUrlExpiresAtMeta =
      const VerificationMeta('remoteUrlExpiresAt');
  @override
  late final GeneratedColumn<String> remoteUrlExpiresAt =
      GeneratedColumn<String>(
        'remote_url_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoUpdatedAtMeta = const VerificationMeta(
    'photoUpdatedAt',
  );
  @override
  late final GeneratedColumn<String> photoUpdatedAt = GeneratedColumn<String>(
    'photo_updated_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastTouchedAtMeta = const VerificationMeta(
    'lastTouchedAt',
  );
  @override
  late final GeneratedColumn<String> lastTouchedAt = GeneratedColumn<String>(
    'last_touched_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    photoId,
    userId,
    collectibleId,
    storagePath,
    localPath,
    remoteUrl,
    remoteUrlExpiresAt,
    byteSize,
    photoUpdatedAt,
    lastTouchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_cache_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PhotoCacheEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('photo_id')) {
      context.handle(
        _photoIdMeta,
        photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('collectible_id')) {
      context.handle(
        _collectibleIdMeta,
        collectibleId.isAcceptableOrUnknown(
          data['collectible_id']!,
          _collectibleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_collectibleIdMeta);
    }
    if (data.containsKey('storage_path')) {
      context.handle(
        _storagePathMeta,
        storagePath.isAcceptableOrUnknown(
          data['storage_path']!,
          _storagePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_storagePathMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('remote_url')) {
      context.handle(
        _remoteUrlMeta,
        remoteUrl.isAcceptableOrUnknown(data['remote_url']!, _remoteUrlMeta),
      );
    }
    if (data.containsKey('remote_url_expires_at')) {
      context.handle(
        _remoteUrlExpiresAtMeta,
        remoteUrlExpiresAt.isAcceptableOrUnknown(
          data['remote_url_expires_at']!,
          _remoteUrlExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    }
    if (data.containsKey('photo_updated_at')) {
      context.handle(
        _photoUpdatedAtMeta,
        photoUpdatedAt.isAcceptableOrUnknown(
          data['photo_updated_at']!,
          _photoUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_touched_at')) {
      context.handle(
        _lastTouchedAtMeta,
        lastTouchedAt.isAcceptableOrUnknown(
          data['last_touched_at']!,
          _lastTouchedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {photoId};
  @override
  PhotoCacheEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoCacheEntry(
      photoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      collectibleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}collectible_id'],
      )!,
      storagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}storage_path'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      remoteUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_url'],
      ),
      remoteUrlExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_url_expires_at'],
      ),
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      ),
      photoUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_updated_at'],
      ),
      lastTouchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_touched_at'],
      ),
    );
  }

  @override
  $PhotoCacheEntriesTable createAlias(String alias) {
    return $PhotoCacheEntriesTable(attachedDatabase, alias);
  }
}

class PhotoCacheEntry extends DataClass implements Insertable<PhotoCacheEntry> {
  final String photoId;
  final String userId;
  final String collectibleId;
  final String storagePath;
  final String? localPath;
  final String? remoteUrl;
  final String? remoteUrlExpiresAt;
  final int? byteSize;
  final String? photoUpdatedAt;
  final String? lastTouchedAt;
  const PhotoCacheEntry({
    required this.photoId,
    required this.userId,
    required this.collectibleId,
    required this.storagePath,
    this.localPath,
    this.remoteUrl,
    this.remoteUrlExpiresAt,
    this.byteSize,
    this.photoUpdatedAt,
    this.lastTouchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['photo_id'] = Variable<String>(photoId);
    map['user_id'] = Variable<String>(userId);
    map['collectible_id'] = Variable<String>(collectibleId);
    map['storage_path'] = Variable<String>(storagePath);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || remoteUrl != null) {
      map['remote_url'] = Variable<String>(remoteUrl);
    }
    if (!nullToAbsent || remoteUrlExpiresAt != null) {
      map['remote_url_expires_at'] = Variable<String>(remoteUrlExpiresAt);
    }
    if (!nullToAbsent || byteSize != null) {
      map['byte_size'] = Variable<int>(byteSize);
    }
    if (!nullToAbsent || photoUpdatedAt != null) {
      map['photo_updated_at'] = Variable<String>(photoUpdatedAt);
    }
    if (!nullToAbsent || lastTouchedAt != null) {
      map['last_touched_at'] = Variable<String>(lastTouchedAt);
    }
    return map;
  }

  PhotoCacheEntriesCompanion toCompanion(bool nullToAbsent) {
    return PhotoCacheEntriesCompanion(
      photoId: Value(photoId),
      userId: Value(userId),
      collectibleId: Value(collectibleId),
      storagePath: Value(storagePath),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      remoteUrl: remoteUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUrl),
      remoteUrlExpiresAt: remoteUrlExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUrlExpiresAt),
      byteSize: byteSize == null && nullToAbsent
          ? const Value.absent()
          : Value(byteSize),
      photoUpdatedAt: photoUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUpdatedAt),
      lastTouchedAt: lastTouchedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastTouchedAt),
    );
  }

  factory PhotoCacheEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoCacheEntry(
      photoId: serializer.fromJson<String>(json['photoId']),
      userId: serializer.fromJson<String>(json['userId']),
      collectibleId: serializer.fromJson<String>(json['collectibleId']),
      storagePath: serializer.fromJson<String>(json['storagePath']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      remoteUrl: serializer.fromJson<String?>(json['remoteUrl']),
      remoteUrlExpiresAt: serializer.fromJson<String?>(
        json['remoteUrlExpiresAt'],
      ),
      byteSize: serializer.fromJson<int?>(json['byteSize']),
      photoUpdatedAt: serializer.fromJson<String?>(json['photoUpdatedAt']),
      lastTouchedAt: serializer.fromJson<String?>(json['lastTouchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'photoId': serializer.toJson<String>(photoId),
      'userId': serializer.toJson<String>(userId),
      'collectibleId': serializer.toJson<String>(collectibleId),
      'storagePath': serializer.toJson<String>(storagePath),
      'localPath': serializer.toJson<String?>(localPath),
      'remoteUrl': serializer.toJson<String?>(remoteUrl),
      'remoteUrlExpiresAt': serializer.toJson<String?>(remoteUrlExpiresAt),
      'byteSize': serializer.toJson<int?>(byteSize),
      'photoUpdatedAt': serializer.toJson<String?>(photoUpdatedAt),
      'lastTouchedAt': serializer.toJson<String?>(lastTouchedAt),
    };
  }

  PhotoCacheEntry copyWith({
    String? photoId,
    String? userId,
    String? collectibleId,
    String? storagePath,
    Value<String?> localPath = const Value.absent(),
    Value<String?> remoteUrl = const Value.absent(),
    Value<String?> remoteUrlExpiresAt = const Value.absent(),
    Value<int?> byteSize = const Value.absent(),
    Value<String?> photoUpdatedAt = const Value.absent(),
    Value<String?> lastTouchedAt = const Value.absent(),
  }) => PhotoCacheEntry(
    photoId: photoId ?? this.photoId,
    userId: userId ?? this.userId,
    collectibleId: collectibleId ?? this.collectibleId,
    storagePath: storagePath ?? this.storagePath,
    localPath: localPath.present ? localPath.value : this.localPath,
    remoteUrl: remoteUrl.present ? remoteUrl.value : this.remoteUrl,
    remoteUrlExpiresAt: remoteUrlExpiresAt.present
        ? remoteUrlExpiresAt.value
        : this.remoteUrlExpiresAt,
    byteSize: byteSize.present ? byteSize.value : this.byteSize,
    photoUpdatedAt: photoUpdatedAt.present
        ? photoUpdatedAt.value
        : this.photoUpdatedAt,
    lastTouchedAt: lastTouchedAt.present
        ? lastTouchedAt.value
        : this.lastTouchedAt,
  );
  PhotoCacheEntry copyWithCompanion(PhotoCacheEntriesCompanion data) {
    return PhotoCacheEntry(
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      userId: data.userId.present ? data.userId.value : this.userId,
      collectibleId: data.collectibleId.present
          ? data.collectibleId.value
          : this.collectibleId,
      storagePath: data.storagePath.present
          ? data.storagePath.value
          : this.storagePath,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      remoteUrl: data.remoteUrl.present ? data.remoteUrl.value : this.remoteUrl,
      remoteUrlExpiresAt: data.remoteUrlExpiresAt.present
          ? data.remoteUrlExpiresAt.value
          : this.remoteUrlExpiresAt,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      photoUpdatedAt: data.photoUpdatedAt.present
          ? data.photoUpdatedAt.value
          : this.photoUpdatedAt,
      lastTouchedAt: data.lastTouchedAt.present
          ? data.lastTouchedAt.value
          : this.lastTouchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoCacheEntry(')
          ..write('photoId: $photoId, ')
          ..write('userId: $userId, ')
          ..write('collectibleId: $collectibleId, ')
          ..write('storagePath: $storagePath, ')
          ..write('localPath: $localPath, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('remoteUrlExpiresAt: $remoteUrlExpiresAt, ')
          ..write('byteSize: $byteSize, ')
          ..write('photoUpdatedAt: $photoUpdatedAt, ')
          ..write('lastTouchedAt: $lastTouchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    photoId,
    userId,
    collectibleId,
    storagePath,
    localPath,
    remoteUrl,
    remoteUrlExpiresAt,
    byteSize,
    photoUpdatedAt,
    lastTouchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoCacheEntry &&
          other.photoId == this.photoId &&
          other.userId == this.userId &&
          other.collectibleId == this.collectibleId &&
          other.storagePath == this.storagePath &&
          other.localPath == this.localPath &&
          other.remoteUrl == this.remoteUrl &&
          other.remoteUrlExpiresAt == this.remoteUrlExpiresAt &&
          other.byteSize == this.byteSize &&
          other.photoUpdatedAt == this.photoUpdatedAt &&
          other.lastTouchedAt == this.lastTouchedAt);
}

class PhotoCacheEntriesCompanion extends UpdateCompanion<PhotoCacheEntry> {
  final Value<String> photoId;
  final Value<String> userId;
  final Value<String> collectibleId;
  final Value<String> storagePath;
  final Value<String?> localPath;
  final Value<String?> remoteUrl;
  final Value<String?> remoteUrlExpiresAt;
  final Value<int?> byteSize;
  final Value<String?> photoUpdatedAt;
  final Value<String?> lastTouchedAt;
  final Value<int> rowid;
  const PhotoCacheEntriesCompanion({
    this.photoId = const Value.absent(),
    this.userId = const Value.absent(),
    this.collectibleId = const Value.absent(),
    this.storagePath = const Value.absent(),
    this.localPath = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.remoteUrlExpiresAt = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.photoUpdatedAt = const Value.absent(),
    this.lastTouchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotoCacheEntriesCompanion.insert({
    required String photoId,
    required String userId,
    required String collectibleId,
    required String storagePath,
    this.localPath = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.remoteUrlExpiresAt = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.photoUpdatedAt = const Value.absent(),
    this.lastTouchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : photoId = Value(photoId),
       userId = Value(userId),
       collectibleId = Value(collectibleId),
       storagePath = Value(storagePath);
  static Insertable<PhotoCacheEntry> custom({
    Expression<String>? photoId,
    Expression<String>? userId,
    Expression<String>? collectibleId,
    Expression<String>? storagePath,
    Expression<String>? localPath,
    Expression<String>? remoteUrl,
    Expression<String>? remoteUrlExpiresAt,
    Expression<int>? byteSize,
    Expression<String>? photoUpdatedAt,
    Expression<String>? lastTouchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (photoId != null) 'photo_id': photoId,
      if (userId != null) 'user_id': userId,
      if (collectibleId != null) 'collectible_id': collectibleId,
      if (storagePath != null) 'storage_path': storagePath,
      if (localPath != null) 'local_path': localPath,
      if (remoteUrl != null) 'remote_url': remoteUrl,
      if (remoteUrlExpiresAt != null)
        'remote_url_expires_at': remoteUrlExpiresAt,
      if (byteSize != null) 'byte_size': byteSize,
      if (photoUpdatedAt != null) 'photo_updated_at': photoUpdatedAt,
      if (lastTouchedAt != null) 'last_touched_at': lastTouchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotoCacheEntriesCompanion copyWith({
    Value<String>? photoId,
    Value<String>? userId,
    Value<String>? collectibleId,
    Value<String>? storagePath,
    Value<String?>? localPath,
    Value<String?>? remoteUrl,
    Value<String?>? remoteUrlExpiresAt,
    Value<int?>? byteSize,
    Value<String?>? photoUpdatedAt,
    Value<String?>? lastTouchedAt,
    Value<int>? rowid,
  }) {
    return PhotoCacheEntriesCompanion(
      photoId: photoId ?? this.photoId,
      userId: userId ?? this.userId,
      collectibleId: collectibleId ?? this.collectibleId,
      storagePath: storagePath ?? this.storagePath,
      localPath: localPath ?? this.localPath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      remoteUrlExpiresAt: remoteUrlExpiresAt ?? this.remoteUrlExpiresAt,
      byteSize: byteSize ?? this.byteSize,
      photoUpdatedAt: photoUpdatedAt ?? this.photoUpdatedAt,
      lastTouchedAt: lastTouchedAt ?? this.lastTouchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (collectibleId.present) {
      map['collectible_id'] = Variable<String>(collectibleId.value);
    }
    if (storagePath.present) {
      map['storage_path'] = Variable<String>(storagePath.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (remoteUrl.present) {
      map['remote_url'] = Variable<String>(remoteUrl.value);
    }
    if (remoteUrlExpiresAt.present) {
      map['remote_url_expires_at'] = Variable<String>(remoteUrlExpiresAt.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (photoUpdatedAt.present) {
      map['photo_updated_at'] = Variable<String>(photoUpdatedAt.value);
    }
    if (lastTouchedAt.present) {
      map['last_touched_at'] = Variable<String>(lastTouchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoCacheEntriesCompanion(')
          ..write('photoId: $photoId, ')
          ..write('userId: $userId, ')
          ..write('collectibleId: $collectibleId, ')
          ..write('storagePath: $storagePath, ')
          ..write('localPath: $localPath, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('remoteUrlExpiresAt: $remoteUrlExpiresAt, ')
          ..write('byteSize: $byteSize, ')
          ..write('photoUpdatedAt: $photoUpdatedAt, ')
          ..write('lastTouchedAt: $lastTouchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalArchiveDatabase extends GeneratedDatabase {
  _$LocalArchiveDatabase(QueryExecutor e) : super(e);
  $LocalArchiveDatabaseManager get managers =>
      $LocalArchiveDatabaseManager(this);
  late final $ProfilesLocalTable profilesLocal = $ProfilesLocalTable(this);
  late final $CollectiblesLocalTable collectiblesLocal =
      $CollectiblesLocalTable(this);
  late final $CollectiblePhotosLocalTable collectiblePhotosLocal =
      $CollectiblePhotosLocalTable(this);
  late final $WishlistItemsLocalTable wishlistItemsLocal =
      $WishlistItemsLocalTable(this);
  late final $TagsLocalTable tagsLocal = $TagsLocalTable(this);
  late final $CollectibleTagLinksLocalTable collectibleTagLinksLocal =
      $CollectibleTagLinksLocalTable(this);
  late final $ArchiveSyncStatesTable archiveSyncStates =
      $ArchiveSyncStatesTable(this);
  late final $PhotoCacheEntriesTable photoCacheEntries =
      $PhotoCacheEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    profilesLocal,
    collectiblesLocal,
    collectiblePhotosLocal,
    wishlistItemsLocal,
    tagsLocal,
    collectibleTagLinksLocal,
    archiveSyncStates,
    photoCacheEntries,
  ];
}

typedef $$ProfilesLocalTableCreateCompanionBuilder =
    ProfilesLocalCompanion Function({
      required String userId,
      Value<String?> username,
      Value<String?> displayName,
      Value<String?> avatarUrl,
      Value<String?> bio,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$ProfilesLocalTableUpdateCompanionBuilder =
    ProfilesLocalCompanion Function({
      Value<String> userId,
      Value<String?> username,
      Value<String?> displayName,
      Value<String?> avatarUrl,
      Value<String?> bio,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$ProfilesLocalTableFilterComposer
    extends Composer<_$LocalArchiveDatabase, $ProfilesLocalTable> {
  $$ProfilesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProfilesLocalTableOrderingComposer
    extends Composer<_$LocalArchiveDatabase, $ProfilesLocalTable> {
  $$ProfilesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarUrl => $composableBuilder(
    column: $table.avatarUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bio => $composableBuilder(
    column: $table.bio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfilesLocalTableAnnotationComposer
    extends Composer<_$LocalArchiveDatabase, $ProfilesLocalTable> {
  $$ProfilesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarUrl =>
      $composableBuilder(column: $table.avatarUrl, builder: (column) => column);

  GeneratedColumn<String> get bio =>
      $composableBuilder(column: $table.bio, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProfilesLocalTableTableManager
    extends
        RootTableManager<
          _$LocalArchiveDatabase,
          $ProfilesLocalTable,
          ProfilesLocalData,
          $$ProfilesLocalTableFilterComposer,
          $$ProfilesLocalTableOrderingComposer,
          $$ProfilesLocalTableAnnotationComposer,
          $$ProfilesLocalTableCreateCompanionBuilder,
          $$ProfilesLocalTableUpdateCompanionBuilder,
          (
            ProfilesLocalData,
            BaseReferences<
              _$LocalArchiveDatabase,
              $ProfilesLocalTable,
              ProfilesLocalData
            >,
          ),
          ProfilesLocalData,
          PrefetchHooks Function()
        > {
  $$ProfilesLocalTableTableManager(
    _$LocalArchiveDatabase db,
    $ProfilesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfilesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfilesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfilesLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> username = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesLocalCompanion(
                userId: userId,
                username: username,
                displayName: displayName,
                avatarUrl: avatarUrl,
                bio: bio,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> username = const Value.absent(),
                Value<String?> displayName = const Value.absent(),
                Value<String?> avatarUrl = const Value.absent(),
                Value<String?> bio = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfilesLocalCompanion.insert(
                userId: userId,
                username: username,
                displayName: displayName,
                avatarUrl: avatarUrl,
                bio: bio,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfilesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalArchiveDatabase,
      $ProfilesLocalTable,
      ProfilesLocalData,
      $$ProfilesLocalTableFilterComposer,
      $$ProfilesLocalTableOrderingComposer,
      $$ProfilesLocalTableAnnotationComposer,
      $$ProfilesLocalTableCreateCompanionBuilder,
      $$ProfilesLocalTableUpdateCompanionBuilder,
      (
        ProfilesLocalData,
        BaseReferences<
          _$LocalArchiveDatabase,
          $ProfilesLocalTable,
          ProfilesLocalData
        >,
      ),
      ProfilesLocalData,
      PrefetchHooks Function()
    >;
typedef $$CollectiblesLocalTableCreateCompanionBuilder =
    CollectiblesLocalCompanion Function({
      required String id,
      required String userId,
      Value<String?> barcode,
      required String title,
      required String category,
      Value<String?> description,
      Value<String?> brand,
      Value<String?> series,
      Value<String?> franchise,
      Value<String?> lineOrSeries,
      Value<String?> characterOrSubject,
      Value<int?> releaseYear,
      Value<String?> boxStatus,
      Value<String?> itemNumber,
      Value<String?> itemCondition,
      Value<int> quantity,
      Value<double?> purchasePrice,
      Value<double?> estimatedValue,
      Value<String?> acquiredOn,
      Value<String?> notes,
      Value<bool> isFavorite,
      Value<bool> isGrail,
      Value<bool> isDuplicate,
      Value<bool> openToTrade,
      Value<String> tagsJson,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$CollectiblesLocalTableUpdateCompanionBuilder =
    CollectiblesLocalCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String?> barcode,
      Value<String> title,
      Value<String> category,
      Value<String?> description,
      Value<String?> brand,
      Value<String?> series,
      Value<String?> franchise,
      Value<String?> lineOrSeries,
      Value<String?> characterOrSubject,
      Value<int?> releaseYear,
      Value<String?> boxStatus,
      Value<String?> itemNumber,
      Value<String?> itemCondition,
      Value<int> quantity,
      Value<double?> purchasePrice,
      Value<double?> estimatedValue,
      Value<String?> acquiredOn,
      Value<String?> notes,
      Value<bool> isFavorite,
      Value<bool> isGrail,
      Value<bool> isDuplicate,
      Value<bool> openToTrade,
      Value<String> tagsJson,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$CollectiblesLocalTableFilterComposer
    extends Composer<_$LocalArchiveDatabase, $CollectiblesLocalTable> {
  $$CollectiblesLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get franchise => $composableBuilder(
    column: $table.franchise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineOrSeries => $composableBuilder(
    column: $table.lineOrSeries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterOrSubject => $composableBuilder(
    column: $table.characterOrSubject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boxStatus => $composableBuilder(
    column: $table.boxStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemNumber => $composableBuilder(
    column: $table.itemNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemCondition => $composableBuilder(
    column: $table.itemCondition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get estimatedValue => $composableBuilder(
    column: $table.estimatedValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get acquiredOn => $composableBuilder(
    column: $table.acquiredOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isGrail => $composableBuilder(
    column: $table.isGrail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDuplicate => $composableBuilder(
    column: $table.isDuplicate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get openToTrade => $composableBuilder(
    column: $table.openToTrade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectiblesLocalTableOrderingComposer
    extends Composer<_$LocalArchiveDatabase, $CollectiblesLocalTable> {
  $$CollectiblesLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get franchise => $composableBuilder(
    column: $table.franchise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineOrSeries => $composableBuilder(
    column: $table.lineOrSeries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterOrSubject => $composableBuilder(
    column: $table.characterOrSubject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boxStatus => $composableBuilder(
    column: $table.boxStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemNumber => $composableBuilder(
    column: $table.itemNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemCondition => $composableBuilder(
    column: $table.itemCondition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get estimatedValue => $composableBuilder(
    column: $table.estimatedValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get acquiredOn => $composableBuilder(
    column: $table.acquiredOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isGrail => $composableBuilder(
    column: $table.isGrail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDuplicate => $composableBuilder(
    column: $table.isDuplicate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get openToTrade => $composableBuilder(
    column: $table.openToTrade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagsJson => $composableBuilder(
    column: $table.tagsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectiblesLocalTableAnnotationComposer
    extends Composer<_$LocalArchiveDatabase, $CollectiblesLocalTable> {
  $$CollectiblesLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get series =>
      $composableBuilder(column: $table.series, builder: (column) => column);

  GeneratedColumn<String> get franchise =>
      $composableBuilder(column: $table.franchise, builder: (column) => column);

  GeneratedColumn<String> get lineOrSeries => $composableBuilder(
    column: $table.lineOrSeries,
    builder: (column) => column,
  );

  GeneratedColumn<String> get characterOrSubject => $composableBuilder(
    column: $table.characterOrSubject,
    builder: (column) => column,
  );

  GeneratedColumn<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boxStatus =>
      $composableBuilder(column: $table.boxStatus, builder: (column) => column);

  GeneratedColumn<String> get itemNumber => $composableBuilder(
    column: $table.itemNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemCondition => $composableBuilder(
    column: $table.itemCondition,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get purchasePrice => $composableBuilder(
    column: $table.purchasePrice,
    builder: (column) => column,
  );

  GeneratedColumn<double> get estimatedValue => $composableBuilder(
    column: $table.estimatedValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get acquiredOn => $composableBuilder(
    column: $table.acquiredOn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isGrail =>
      $composableBuilder(column: $table.isGrail, builder: (column) => column);

  GeneratedColumn<bool> get isDuplicate => $composableBuilder(
    column: $table.isDuplicate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get openToTrade => $composableBuilder(
    column: $table.openToTrade,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagsJson =>
      $composableBuilder(column: $table.tagsJson, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CollectiblesLocalTableTableManager
    extends
        RootTableManager<
          _$LocalArchiveDatabase,
          $CollectiblesLocalTable,
          CollectiblesLocalData,
          $$CollectiblesLocalTableFilterComposer,
          $$CollectiblesLocalTableOrderingComposer,
          $$CollectiblesLocalTableAnnotationComposer,
          $$CollectiblesLocalTableCreateCompanionBuilder,
          $$CollectiblesLocalTableUpdateCompanionBuilder,
          (
            CollectiblesLocalData,
            BaseReferences<
              _$LocalArchiveDatabase,
              $CollectiblesLocalTable,
              CollectiblesLocalData
            >,
          ),
          CollectiblesLocalData,
          PrefetchHooks Function()
        > {
  $$CollectiblesLocalTableTableManager(
    _$LocalArchiveDatabase db,
    $CollectiblesLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectiblesLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectiblesLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectiblesLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> series = const Value.absent(),
                Value<String?> franchise = const Value.absent(),
                Value<String?> lineOrSeries = const Value.absent(),
                Value<String?> characterOrSubject = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<String?> boxStatus = const Value.absent(),
                Value<String?> itemNumber = const Value.absent(),
                Value<String?> itemCondition = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<double?> estimatedValue = const Value.absent(),
                Value<String?> acquiredOn = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isGrail = const Value.absent(),
                Value<bool> isDuplicate = const Value.absent(),
                Value<bool> openToTrade = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectiblesLocalCompanion(
                id: id,
                userId: userId,
                barcode: barcode,
                title: title,
                category: category,
                description: description,
                brand: brand,
                series: series,
                franchise: franchise,
                lineOrSeries: lineOrSeries,
                characterOrSubject: characterOrSubject,
                releaseYear: releaseYear,
                boxStatus: boxStatus,
                itemNumber: itemNumber,
                itemCondition: itemCondition,
                quantity: quantity,
                purchasePrice: purchasePrice,
                estimatedValue: estimatedValue,
                acquiredOn: acquiredOn,
                notes: notes,
                isFavorite: isFavorite,
                isGrail: isGrail,
                isDuplicate: isDuplicate,
                openToTrade: openToTrade,
                tagsJson: tagsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                Value<String?> barcode = const Value.absent(),
                required String title,
                required String category,
                Value<String?> description = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> series = const Value.absent(),
                Value<String?> franchise = const Value.absent(),
                Value<String?> lineOrSeries = const Value.absent(),
                Value<String?> characterOrSubject = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<String?> boxStatus = const Value.absent(),
                Value<String?> itemNumber = const Value.absent(),
                Value<String?> itemCondition = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<double?> purchasePrice = const Value.absent(),
                Value<double?> estimatedValue = const Value.absent(),
                Value<String?> acquiredOn = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isGrail = const Value.absent(),
                Value<bool> isDuplicate = const Value.absent(),
                Value<bool> openToTrade = const Value.absent(),
                Value<String> tagsJson = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectiblesLocalCompanion.insert(
                id: id,
                userId: userId,
                barcode: barcode,
                title: title,
                category: category,
                description: description,
                brand: brand,
                series: series,
                franchise: franchise,
                lineOrSeries: lineOrSeries,
                characterOrSubject: characterOrSubject,
                releaseYear: releaseYear,
                boxStatus: boxStatus,
                itemNumber: itemNumber,
                itemCondition: itemCondition,
                quantity: quantity,
                purchasePrice: purchasePrice,
                estimatedValue: estimatedValue,
                acquiredOn: acquiredOn,
                notes: notes,
                isFavorite: isFavorite,
                isGrail: isGrail,
                isDuplicate: isDuplicate,
                openToTrade: openToTrade,
                tagsJson: tagsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectiblesLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalArchiveDatabase,
      $CollectiblesLocalTable,
      CollectiblesLocalData,
      $$CollectiblesLocalTableFilterComposer,
      $$CollectiblesLocalTableOrderingComposer,
      $$CollectiblesLocalTableAnnotationComposer,
      $$CollectiblesLocalTableCreateCompanionBuilder,
      $$CollectiblesLocalTableUpdateCompanionBuilder,
      (
        CollectiblesLocalData,
        BaseReferences<
          _$LocalArchiveDatabase,
          $CollectiblesLocalTable,
          CollectiblesLocalData
        >,
      ),
      CollectiblesLocalData,
      PrefetchHooks Function()
    >;
typedef $$CollectiblePhotosLocalTableCreateCompanionBuilder =
    CollectiblePhotosLocalCompanion Function({
      required String id,
      required String userId,
      required String collectibleId,
      required String storageBucket,
      required String storagePath,
      Value<String?> caption,
      Value<bool> isPrimary,
      Value<int> displayOrder,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$CollectiblePhotosLocalTableUpdateCompanionBuilder =
    CollectiblePhotosLocalCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> collectibleId,
      Value<String> storageBucket,
      Value<String> storagePath,
      Value<String?> caption,
      Value<bool> isPrimary,
      Value<int> displayOrder,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$CollectiblePhotosLocalTableFilterComposer
    extends Composer<_$LocalArchiveDatabase, $CollectiblePhotosLocalTable> {
  $$CollectiblePhotosLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectibleId => $composableBuilder(
    column: $table.collectibleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storageBucket => $composableBuilder(
    column: $table.storageBucket,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectiblePhotosLocalTableOrderingComposer
    extends Composer<_$LocalArchiveDatabase, $CollectiblePhotosLocalTable> {
  $$CollectiblePhotosLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectibleId => $composableBuilder(
    column: $table.collectibleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storageBucket => $composableBuilder(
    column: $table.storageBucket,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get caption => $composableBuilder(
    column: $table.caption,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPrimary => $composableBuilder(
    column: $table.isPrimary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectiblePhotosLocalTableAnnotationComposer
    extends Composer<_$LocalArchiveDatabase, $CollectiblePhotosLocalTable> {
  $$CollectiblePhotosLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get collectibleId => $composableBuilder(
    column: $table.collectibleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storageBucket => $composableBuilder(
    column: $table.storageBucket,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<bool> get isPrimary =>
      $composableBuilder(column: $table.isPrimary, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
    column: $table.displayOrder,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CollectiblePhotosLocalTableTableManager
    extends
        RootTableManager<
          _$LocalArchiveDatabase,
          $CollectiblePhotosLocalTable,
          CollectiblePhotosLocalData,
          $$CollectiblePhotosLocalTableFilterComposer,
          $$CollectiblePhotosLocalTableOrderingComposer,
          $$CollectiblePhotosLocalTableAnnotationComposer,
          $$CollectiblePhotosLocalTableCreateCompanionBuilder,
          $$CollectiblePhotosLocalTableUpdateCompanionBuilder,
          (
            CollectiblePhotosLocalData,
            BaseReferences<
              _$LocalArchiveDatabase,
              $CollectiblePhotosLocalTable,
              CollectiblePhotosLocalData
            >,
          ),
          CollectiblePhotosLocalData,
          PrefetchHooks Function()
        > {
  $$CollectiblePhotosLocalTableTableManager(
    _$LocalArchiveDatabase db,
    $CollectiblePhotosLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectiblePhotosLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CollectiblePhotosLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CollectiblePhotosLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> collectibleId = const Value.absent(),
                Value<String> storageBucket = const Value.absent(),
                Value<String> storagePath = const Value.absent(),
                Value<String?> caption = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectiblePhotosLocalCompanion(
                id: id,
                userId: userId,
                collectibleId: collectibleId,
                storageBucket: storageBucket,
                storagePath: storagePath,
                caption: caption,
                isPrimary: isPrimary,
                displayOrder: displayOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String collectibleId,
                required String storageBucket,
                required String storagePath,
                Value<String?> caption = const Value.absent(),
                Value<bool> isPrimary = const Value.absent(),
                Value<int> displayOrder = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectiblePhotosLocalCompanion.insert(
                id: id,
                userId: userId,
                collectibleId: collectibleId,
                storageBucket: storageBucket,
                storagePath: storagePath,
                caption: caption,
                isPrimary: isPrimary,
                displayOrder: displayOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectiblePhotosLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalArchiveDatabase,
      $CollectiblePhotosLocalTable,
      CollectiblePhotosLocalData,
      $$CollectiblePhotosLocalTableFilterComposer,
      $$CollectiblePhotosLocalTableOrderingComposer,
      $$CollectiblePhotosLocalTableAnnotationComposer,
      $$CollectiblePhotosLocalTableCreateCompanionBuilder,
      $$CollectiblePhotosLocalTableUpdateCompanionBuilder,
      (
        CollectiblePhotosLocalData,
        BaseReferences<
          _$LocalArchiveDatabase,
          $CollectiblePhotosLocalTable,
          CollectiblePhotosLocalData
        >,
      ),
      CollectiblePhotosLocalData,
      PrefetchHooks Function()
    >;
typedef $$WishlistItemsLocalTableCreateCompanionBuilder =
    WishlistItemsLocalCompanion Function({
      required String id,
      required String userId,
      required String title,
      required String category,
      Value<String?> description,
      Value<String?> brand,
      Value<String?> series,
      Value<String?> franchise,
      Value<String?> lineOrSeries,
      Value<String?> characterOrSubject,
      Value<int?> releaseYear,
      Value<String?> boxStatus,
      Value<String?> priority,
      Value<double?> targetPrice,
      Value<String?> notes,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });
typedef $$WishlistItemsLocalTableUpdateCompanionBuilder =
    WishlistItemsLocalCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> title,
      Value<String> category,
      Value<String?> description,
      Value<String?> brand,
      Value<String?> series,
      Value<String?> franchise,
      Value<String?> lineOrSeries,
      Value<String?> characterOrSubject,
      Value<int?> releaseYear,
      Value<String?> boxStatus,
      Value<String?> priority,
      Value<double?> targetPrice,
      Value<String?> notes,
      Value<String?> createdAt,
      Value<String?> updatedAt,
      Value<int> rowid,
    });

class $$WishlistItemsLocalTableFilterComposer
    extends Composer<_$LocalArchiveDatabase, $WishlistItemsLocalTable> {
  $$WishlistItemsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get franchise => $composableBuilder(
    column: $table.franchise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lineOrSeries => $composableBuilder(
    column: $table.lineOrSeries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get characterOrSubject => $composableBuilder(
    column: $table.characterOrSubject,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get boxStatus => $composableBuilder(
    column: $table.boxStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetPrice => $composableBuilder(
    column: $table.targetPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WishlistItemsLocalTableOrderingComposer
    extends Composer<_$LocalArchiveDatabase, $WishlistItemsLocalTable> {
  $$WishlistItemsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get series => $composableBuilder(
    column: $table.series,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get franchise => $composableBuilder(
    column: $table.franchise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lineOrSeries => $composableBuilder(
    column: $table.lineOrSeries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get characterOrSubject => $composableBuilder(
    column: $table.characterOrSubject,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get boxStatus => $composableBuilder(
    column: $table.boxStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetPrice => $composableBuilder(
    column: $table.targetPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WishlistItemsLocalTableAnnotationComposer
    extends Composer<_$LocalArchiveDatabase, $WishlistItemsLocalTable> {
  $$WishlistItemsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get series =>
      $composableBuilder(column: $table.series, builder: (column) => column);

  GeneratedColumn<String> get franchise =>
      $composableBuilder(column: $table.franchise, builder: (column) => column);

  GeneratedColumn<String> get lineOrSeries => $composableBuilder(
    column: $table.lineOrSeries,
    builder: (column) => column,
  );

  GeneratedColumn<String> get characterOrSubject => $composableBuilder(
    column: $table.characterOrSubject,
    builder: (column) => column,
  );

  GeneratedColumn<int> get releaseYear => $composableBuilder(
    column: $table.releaseYear,
    builder: (column) => column,
  );

  GeneratedColumn<String> get boxStatus =>
      $composableBuilder(column: $table.boxStatus, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<double> get targetPrice => $composableBuilder(
    column: $table.targetPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WishlistItemsLocalTableTableManager
    extends
        RootTableManager<
          _$LocalArchiveDatabase,
          $WishlistItemsLocalTable,
          WishlistItemsLocalData,
          $$WishlistItemsLocalTableFilterComposer,
          $$WishlistItemsLocalTableOrderingComposer,
          $$WishlistItemsLocalTableAnnotationComposer,
          $$WishlistItemsLocalTableCreateCompanionBuilder,
          $$WishlistItemsLocalTableUpdateCompanionBuilder,
          (
            WishlistItemsLocalData,
            BaseReferences<
              _$LocalArchiveDatabase,
              $WishlistItemsLocalTable,
              WishlistItemsLocalData
            >,
          ),
          WishlistItemsLocalData,
          PrefetchHooks Function()
        > {
  $$WishlistItemsLocalTableTableManager(
    _$LocalArchiveDatabase db,
    $WishlistItemsLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WishlistItemsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WishlistItemsLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WishlistItemsLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> series = const Value.absent(),
                Value<String?> franchise = const Value.absent(),
                Value<String?> lineOrSeries = const Value.absent(),
                Value<String?> characterOrSubject = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<String?> boxStatus = const Value.absent(),
                Value<String?> priority = const Value.absent(),
                Value<double?> targetPrice = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WishlistItemsLocalCompanion(
                id: id,
                userId: userId,
                title: title,
                category: category,
                description: description,
                brand: brand,
                series: series,
                franchise: franchise,
                lineOrSeries: lineOrSeries,
                characterOrSubject: characterOrSubject,
                releaseYear: releaseYear,
                boxStatus: boxStatus,
                priority: priority,
                targetPrice: targetPrice,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String title,
                required String category,
                Value<String?> description = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> series = const Value.absent(),
                Value<String?> franchise = const Value.absent(),
                Value<String?> lineOrSeries = const Value.absent(),
                Value<String?> characterOrSubject = const Value.absent(),
                Value<int?> releaseYear = const Value.absent(),
                Value<String?> boxStatus = const Value.absent(),
                Value<String?> priority = const Value.absent(),
                Value<double?> targetPrice = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<String?> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WishlistItemsLocalCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                category: category,
                description: description,
                brand: brand,
                series: series,
                franchise: franchise,
                lineOrSeries: lineOrSeries,
                characterOrSubject: characterOrSubject,
                releaseYear: releaseYear,
                boxStatus: boxStatus,
                priority: priority,
                targetPrice: targetPrice,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WishlistItemsLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalArchiveDatabase,
      $WishlistItemsLocalTable,
      WishlistItemsLocalData,
      $$WishlistItemsLocalTableFilterComposer,
      $$WishlistItemsLocalTableOrderingComposer,
      $$WishlistItemsLocalTableAnnotationComposer,
      $$WishlistItemsLocalTableCreateCompanionBuilder,
      $$WishlistItemsLocalTableUpdateCompanionBuilder,
      (
        WishlistItemsLocalData,
        BaseReferences<
          _$LocalArchiveDatabase,
          $WishlistItemsLocalTable,
          WishlistItemsLocalData
        >,
      ),
      WishlistItemsLocalData,
      PrefetchHooks Function()
    >;
typedef $$TagsLocalTableCreateCompanionBuilder =
    TagsLocalCompanion Function({
      required String id,
      required String userId,
      required String name,
      Value<String?> createdAt,
      Value<int> rowid,
    });
typedef $$TagsLocalTableUpdateCompanionBuilder =
    TagsLocalCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String?> createdAt,
      Value<int> rowid,
    });

class $$TagsLocalTableFilterComposer
    extends Composer<_$LocalArchiveDatabase, $TagsLocalTable> {
  $$TagsLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TagsLocalTableOrderingComposer
    extends Composer<_$LocalArchiveDatabase, $TagsLocalTable> {
  $$TagsLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TagsLocalTableAnnotationComposer
    extends Composer<_$LocalArchiveDatabase, $TagsLocalTable> {
  $$TagsLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$TagsLocalTableTableManager
    extends
        RootTableManager<
          _$LocalArchiveDatabase,
          $TagsLocalTable,
          TagsLocalData,
          $$TagsLocalTableFilterComposer,
          $$TagsLocalTableOrderingComposer,
          $$TagsLocalTableAnnotationComposer,
          $$TagsLocalTableCreateCompanionBuilder,
          $$TagsLocalTableUpdateCompanionBuilder,
          (
            TagsLocalData,
            BaseReferences<
              _$LocalArchiveDatabase,
              $TagsLocalTable,
              TagsLocalData
            >,
          ),
          TagsLocalData,
          PrefetchHooks Function()
        > {
  $$TagsLocalTableTableManager(_$LocalArchiveDatabase db, $TagsLocalTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsLocalTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsLocalTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsLocalTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsLocalCompanion(
                id: id,
                userId: userId,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsLocalCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagsLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalArchiveDatabase,
      $TagsLocalTable,
      TagsLocalData,
      $$TagsLocalTableFilterComposer,
      $$TagsLocalTableOrderingComposer,
      $$TagsLocalTableAnnotationComposer,
      $$TagsLocalTableCreateCompanionBuilder,
      $$TagsLocalTableUpdateCompanionBuilder,
      (
        TagsLocalData,
        BaseReferences<_$LocalArchiveDatabase, $TagsLocalTable, TagsLocalData>,
      ),
      TagsLocalData,
      PrefetchHooks Function()
    >;
typedef $$CollectibleTagLinksLocalTableCreateCompanionBuilder =
    CollectibleTagLinksLocalCompanion Function({
      required String userId,
      required String collectibleId,
      required String tagId,
      Value<String?> createdAt,
      Value<int> rowid,
    });
typedef $$CollectibleTagLinksLocalTableUpdateCompanionBuilder =
    CollectibleTagLinksLocalCompanion Function({
      Value<String> userId,
      Value<String> collectibleId,
      Value<String> tagId,
      Value<String?> createdAt,
      Value<int> rowid,
    });

class $$CollectibleTagLinksLocalTableFilterComposer
    extends Composer<_$LocalArchiveDatabase, $CollectibleTagLinksLocalTable> {
  $$CollectibleTagLinksLocalTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectibleId => $composableBuilder(
    column: $table.collectibleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectibleTagLinksLocalTableOrderingComposer
    extends Composer<_$LocalArchiveDatabase, $CollectibleTagLinksLocalTable> {
  $$CollectibleTagLinksLocalTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectibleId => $composableBuilder(
    column: $table.collectibleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tagId => $composableBuilder(
    column: $table.tagId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectibleTagLinksLocalTableAnnotationComposer
    extends Composer<_$LocalArchiveDatabase, $CollectibleTagLinksLocalTable> {
  $$CollectibleTagLinksLocalTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get collectibleId => $composableBuilder(
    column: $table.collectibleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tagId =>
      $composableBuilder(column: $table.tagId, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$CollectibleTagLinksLocalTableTableManager
    extends
        RootTableManager<
          _$LocalArchiveDatabase,
          $CollectibleTagLinksLocalTable,
          CollectibleTagLinksLocalData,
          $$CollectibleTagLinksLocalTableFilterComposer,
          $$CollectibleTagLinksLocalTableOrderingComposer,
          $$CollectibleTagLinksLocalTableAnnotationComposer,
          $$CollectibleTagLinksLocalTableCreateCompanionBuilder,
          $$CollectibleTagLinksLocalTableUpdateCompanionBuilder,
          (
            CollectibleTagLinksLocalData,
            BaseReferences<
              _$LocalArchiveDatabase,
              $CollectibleTagLinksLocalTable,
              CollectibleTagLinksLocalData
            >,
          ),
          CollectibleTagLinksLocalData,
          PrefetchHooks Function()
        > {
  $$CollectibleTagLinksLocalTableTableManager(
    _$LocalArchiveDatabase db,
    $CollectibleTagLinksLocalTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectibleTagLinksLocalTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$CollectibleTagLinksLocalTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CollectibleTagLinksLocalTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String> collectibleId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectibleTagLinksLocalCompanion(
                userId: userId,
                collectibleId: collectibleId,
                tagId: tagId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                required String collectibleId,
                required String tagId,
                Value<String?> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectibleTagLinksLocalCompanion.insert(
                userId: userId,
                collectibleId: collectibleId,
                tagId: tagId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectibleTagLinksLocalTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalArchiveDatabase,
      $CollectibleTagLinksLocalTable,
      CollectibleTagLinksLocalData,
      $$CollectibleTagLinksLocalTableFilterComposer,
      $$CollectibleTagLinksLocalTableOrderingComposer,
      $$CollectibleTagLinksLocalTableAnnotationComposer,
      $$CollectibleTagLinksLocalTableCreateCompanionBuilder,
      $$CollectibleTagLinksLocalTableUpdateCompanionBuilder,
      (
        CollectibleTagLinksLocalData,
        BaseReferences<
          _$LocalArchiveDatabase,
          $CollectibleTagLinksLocalTable,
          CollectibleTagLinksLocalData
        >,
      ),
      CollectibleTagLinksLocalData,
      PrefetchHooks Function()
    >;
typedef $$ArchiveSyncStatesTableCreateCompanionBuilder =
    ArchiveSyncStatesCompanion Function({
      required String userId,
      Value<String?> remoteSyncStamp,
      Value<String?> lastSyncAt,
      Value<String?> lastSyncCheckAt,
      Value<bool> hasCompletedInitialSync,
      Value<int> rowid,
    });
typedef $$ArchiveSyncStatesTableUpdateCompanionBuilder =
    ArchiveSyncStatesCompanion Function({
      Value<String> userId,
      Value<String?> remoteSyncStamp,
      Value<String?> lastSyncAt,
      Value<String?> lastSyncCheckAt,
      Value<bool> hasCompletedInitialSync,
      Value<int> rowid,
    });

class $$ArchiveSyncStatesTableFilterComposer
    extends Composer<_$LocalArchiveDatabase, $ArchiveSyncStatesTable> {
  $$ArchiveSyncStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteSyncStamp => $composableBuilder(
    column: $table.remoteSyncStamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastSyncCheckAt => $composableBuilder(
    column: $table.lastSyncCheckAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasCompletedInitialSync => $composableBuilder(
    column: $table.hasCompletedInitialSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArchiveSyncStatesTableOrderingComposer
    extends Composer<_$LocalArchiveDatabase, $ArchiveSyncStatesTable> {
  $$ArchiveSyncStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteSyncStamp => $composableBuilder(
    column: $table.remoteSyncStamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastSyncCheckAt => $composableBuilder(
    column: $table.lastSyncCheckAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasCompletedInitialSync => $composableBuilder(
    column: $table.hasCompletedInitialSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArchiveSyncStatesTableAnnotationComposer
    extends Composer<_$LocalArchiveDatabase, $ArchiveSyncStatesTable> {
  $$ArchiveSyncStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get remoteSyncStamp => $composableBuilder(
    column: $table.remoteSyncStamp,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastSyncCheckAt => $composableBuilder(
    column: $table.lastSyncCheckAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get hasCompletedInitialSync => $composableBuilder(
    column: $table.hasCompletedInitialSync,
    builder: (column) => column,
  );
}

class $$ArchiveSyncStatesTableTableManager
    extends
        RootTableManager<
          _$LocalArchiveDatabase,
          $ArchiveSyncStatesTable,
          ArchiveSyncState,
          $$ArchiveSyncStatesTableFilterComposer,
          $$ArchiveSyncStatesTableOrderingComposer,
          $$ArchiveSyncStatesTableAnnotationComposer,
          $$ArchiveSyncStatesTableCreateCompanionBuilder,
          $$ArchiveSyncStatesTableUpdateCompanionBuilder,
          (
            ArchiveSyncState,
            BaseReferences<
              _$LocalArchiveDatabase,
              $ArchiveSyncStatesTable,
              ArchiveSyncState
            >,
          ),
          ArchiveSyncState,
          PrefetchHooks Function()
        > {
  $$ArchiveSyncStatesTableTableManager(
    _$LocalArchiveDatabase db,
    $ArchiveSyncStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArchiveSyncStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArchiveSyncStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArchiveSyncStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> userId = const Value.absent(),
                Value<String?> remoteSyncStamp = const Value.absent(),
                Value<String?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncCheckAt = const Value.absent(),
                Value<bool> hasCompletedInitialSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArchiveSyncStatesCompanion(
                userId: userId,
                remoteSyncStamp: remoteSyncStamp,
                lastSyncAt: lastSyncAt,
                lastSyncCheckAt: lastSyncCheckAt,
                hasCompletedInitialSync: hasCompletedInitialSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userId,
                Value<String?> remoteSyncStamp = const Value.absent(),
                Value<String?> lastSyncAt = const Value.absent(),
                Value<String?> lastSyncCheckAt = const Value.absent(),
                Value<bool> hasCompletedInitialSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArchiveSyncStatesCompanion.insert(
                userId: userId,
                remoteSyncStamp: remoteSyncStamp,
                lastSyncAt: lastSyncAt,
                lastSyncCheckAt: lastSyncCheckAt,
                hasCompletedInitialSync: hasCompletedInitialSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArchiveSyncStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalArchiveDatabase,
      $ArchiveSyncStatesTable,
      ArchiveSyncState,
      $$ArchiveSyncStatesTableFilterComposer,
      $$ArchiveSyncStatesTableOrderingComposer,
      $$ArchiveSyncStatesTableAnnotationComposer,
      $$ArchiveSyncStatesTableCreateCompanionBuilder,
      $$ArchiveSyncStatesTableUpdateCompanionBuilder,
      (
        ArchiveSyncState,
        BaseReferences<
          _$LocalArchiveDatabase,
          $ArchiveSyncStatesTable,
          ArchiveSyncState
        >,
      ),
      ArchiveSyncState,
      PrefetchHooks Function()
    >;
typedef $$PhotoCacheEntriesTableCreateCompanionBuilder =
    PhotoCacheEntriesCompanion Function({
      required String photoId,
      required String userId,
      required String collectibleId,
      required String storagePath,
      Value<String?> localPath,
      Value<String?> remoteUrl,
      Value<String?> remoteUrlExpiresAt,
      Value<int?> byteSize,
      Value<String?> photoUpdatedAt,
      Value<String?> lastTouchedAt,
      Value<int> rowid,
    });
typedef $$PhotoCacheEntriesTableUpdateCompanionBuilder =
    PhotoCacheEntriesCompanion Function({
      Value<String> photoId,
      Value<String> userId,
      Value<String> collectibleId,
      Value<String> storagePath,
      Value<String?> localPath,
      Value<String?> remoteUrl,
      Value<String?> remoteUrlExpiresAt,
      Value<int?> byteSize,
      Value<String?> photoUpdatedAt,
      Value<String?> lastTouchedAt,
      Value<int> rowid,
    });

class $$PhotoCacheEntriesTableFilterComposer
    extends Composer<_$LocalArchiveDatabase, $PhotoCacheEntriesTable> {
  $$PhotoCacheEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get collectibleId => $composableBuilder(
    column: $table.collectibleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteUrlExpiresAt => $composableBuilder(
    column: $table.remoteUrlExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUpdatedAt => $composableBuilder(
    column: $table.photoUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastTouchedAt => $composableBuilder(
    column: $table.lastTouchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PhotoCacheEntriesTableOrderingComposer
    extends Composer<_$LocalArchiveDatabase, $PhotoCacheEntriesTable> {
  $$PhotoCacheEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get photoId => $composableBuilder(
    column: $table.photoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get collectibleId => $composableBuilder(
    column: $table.collectibleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUrl => $composableBuilder(
    column: $table.remoteUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteUrlExpiresAt => $composableBuilder(
    column: $table.remoteUrlExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUpdatedAt => $composableBuilder(
    column: $table.photoUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastTouchedAt => $composableBuilder(
    column: $table.lastTouchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PhotoCacheEntriesTableAnnotationComposer
    extends Composer<_$LocalArchiveDatabase, $PhotoCacheEntriesTable> {
  $$PhotoCacheEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get collectibleId => $composableBuilder(
    column: $table.collectibleId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get storagePath => $composableBuilder(
    column: $table.storagePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get remoteUrl =>
      $composableBuilder(column: $table.remoteUrl, builder: (column) => column);

  GeneratedColumn<String> get remoteUrlExpiresAt => $composableBuilder(
    column: $table.remoteUrlExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<String> get photoUpdatedAt => $composableBuilder(
    column: $table.photoUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastTouchedAt => $composableBuilder(
    column: $table.lastTouchedAt,
    builder: (column) => column,
  );
}

class $$PhotoCacheEntriesTableTableManager
    extends
        RootTableManager<
          _$LocalArchiveDatabase,
          $PhotoCacheEntriesTable,
          PhotoCacheEntry,
          $$PhotoCacheEntriesTableFilterComposer,
          $$PhotoCacheEntriesTableOrderingComposer,
          $$PhotoCacheEntriesTableAnnotationComposer,
          $$PhotoCacheEntriesTableCreateCompanionBuilder,
          $$PhotoCacheEntriesTableUpdateCompanionBuilder,
          (
            PhotoCacheEntry,
            BaseReferences<
              _$LocalArchiveDatabase,
              $PhotoCacheEntriesTable,
              PhotoCacheEntry
            >,
          ),
          PhotoCacheEntry,
          PrefetchHooks Function()
        > {
  $$PhotoCacheEntriesTableTableManager(
    _$LocalArchiveDatabase db,
    $PhotoCacheEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoCacheEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoCacheEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoCacheEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> photoId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> collectibleId = const Value.absent(),
                Value<String> storagePath = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> remoteUrlExpiresAt = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                Value<String?> photoUpdatedAt = const Value.absent(),
                Value<String?> lastTouchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotoCacheEntriesCompanion(
                photoId: photoId,
                userId: userId,
                collectibleId: collectibleId,
                storagePath: storagePath,
                localPath: localPath,
                remoteUrl: remoteUrl,
                remoteUrlExpiresAt: remoteUrlExpiresAt,
                byteSize: byteSize,
                photoUpdatedAt: photoUpdatedAt,
                lastTouchedAt: lastTouchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String photoId,
                required String userId,
                required String collectibleId,
                required String storagePath,
                Value<String?> localPath = const Value.absent(),
                Value<String?> remoteUrl = const Value.absent(),
                Value<String?> remoteUrlExpiresAt = const Value.absent(),
                Value<int?> byteSize = const Value.absent(),
                Value<String?> photoUpdatedAt = const Value.absent(),
                Value<String?> lastTouchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PhotoCacheEntriesCompanion.insert(
                photoId: photoId,
                userId: userId,
                collectibleId: collectibleId,
                storagePath: storagePath,
                localPath: localPath,
                remoteUrl: remoteUrl,
                remoteUrlExpiresAt: remoteUrlExpiresAt,
                byteSize: byteSize,
                photoUpdatedAt: photoUpdatedAt,
                lastTouchedAt: lastTouchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PhotoCacheEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalArchiveDatabase,
      $PhotoCacheEntriesTable,
      PhotoCacheEntry,
      $$PhotoCacheEntriesTableFilterComposer,
      $$PhotoCacheEntriesTableOrderingComposer,
      $$PhotoCacheEntriesTableAnnotationComposer,
      $$PhotoCacheEntriesTableCreateCompanionBuilder,
      $$PhotoCacheEntriesTableUpdateCompanionBuilder,
      (
        PhotoCacheEntry,
        BaseReferences<
          _$LocalArchiveDatabase,
          $PhotoCacheEntriesTable,
          PhotoCacheEntry
        >,
      ),
      PhotoCacheEntry,
      PrefetchHooks Function()
    >;

class $LocalArchiveDatabaseManager {
  final _$LocalArchiveDatabase _db;
  $LocalArchiveDatabaseManager(this._db);
  $$ProfilesLocalTableTableManager get profilesLocal =>
      $$ProfilesLocalTableTableManager(_db, _db.profilesLocal);
  $$CollectiblesLocalTableTableManager get collectiblesLocal =>
      $$CollectiblesLocalTableTableManager(_db, _db.collectiblesLocal);
  $$CollectiblePhotosLocalTableTableManager get collectiblePhotosLocal =>
      $$CollectiblePhotosLocalTableTableManager(
        _db,
        _db.collectiblePhotosLocal,
      );
  $$WishlistItemsLocalTableTableManager get wishlistItemsLocal =>
      $$WishlistItemsLocalTableTableManager(_db, _db.wishlistItemsLocal);
  $$TagsLocalTableTableManager get tagsLocal =>
      $$TagsLocalTableTableManager(_db, _db.tagsLocal);
  $$CollectibleTagLinksLocalTableTableManager get collectibleTagLinksLocal =>
      $$CollectibleTagLinksLocalTableTableManager(
        _db,
        _db.collectibleTagLinksLocal,
      );
  $$ArchiveSyncStatesTableTableManager get archiveSyncStates =>
      $$ArchiveSyncStatesTableTableManager(_db, _db.archiveSyncStates);
  $$PhotoCacheEntriesTableTableManager get photoCacheEntries =>
      $$PhotoCacheEntriesTableTableManager(_db, _db.photoCacheEntries);
}
