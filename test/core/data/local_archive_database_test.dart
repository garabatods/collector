import 'dart:io';

import 'package:collectorapp/core/data/local_archive_database.dart';
import 'package:collectorapp/features/collection/data/models/collectible_model.dart';
import 'package:collectorapp/features/collection/data/models/tag_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalArchiveDatabase database;

  setUp(() {
    database = LocalArchiveDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  test('creates the local archive indexes', () async {
    final rows = await database
        .customSelect(
          "select name from sqlite_master where type = 'index' and name like '%_local_%_idx'",
        )
        .get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(names, contains('collectibles_local_user_created_idx'));
    expect(names, contains('collectibles_local_user_category_idx'));
    expect(names, contains('collectible_photos_local_user_item_idx'));
    expect(names, contains('tags_local_user_name_idx'));
  });

  test(
    'reads one collectible without loading a different user archive',
    () async {
      final firstItem = CollectibleModel(
        id: 'item-1',
        userId: 'user-1',
        title: 'Batman',
        category: 'Comics',
        createdAt: DateTime.utc(2026, 8, 13),
      );
      const otherUserItem = CollectibleModel(
        id: 'item-2',
        userId: 'user-2',
        title: 'Superman',
        category: 'Comics',
      );
      await database.upsertCollectible(firstItem, 'user-1');
      await database.upsertCollectible(otherUserItem, 'user-2');

      final item = await database
          .watchCollectibleById('user-1', 'item-1')
          .first;
      final inaccessible = await database
          .watchCollectibleById('user-1', 'item-2')
          .first;

      expect(item?.title, 'Batman');
      expect(inaccessible, isNull);
    },
  );

  test('returns local collectibles and tags for suggestions', () async {
    const item = CollectibleModel(
      id: 'item-1',
      userId: 'user-1',
      title: 'Darth Vader',
      category: 'Action Figures',
      brand: 'Hasbro',
    );
    const tag = TagModel(id: 'tag-1', userId: 'user-1', name: 'Display Shelf');
    await database.upsertCollectible(item, 'user-1');
    await database.upsertTag(tag, 'user-1');

    final items = await database.getCollectibles('user-1');
    final tags = await database.getTags('user-1');

    expect(items.single.brand, 'Hasbro');
    expect(tags.single.name, 'Display Shelf');
  });

  test('v3 index migration preserves an existing local collection', () async {
    await database.close();
    final directory = await Directory.systemTemp.createTemp(
      'collector-local-db-test-',
    );
    final file = File('${directory.path}/archive.sqlite');
    try {
      final original = LocalArchiveDatabase.forTesting(NativeDatabase(file));
      await original.upsertCollectible(
        const CollectibleModel(
          id: 'existing-item',
          userId: 'user-1',
          title: 'Existing Item',
          category: 'Memorabilia',
        ),
        'user-1',
      );
      await original.customStatement('pragma user_version = 2');
      await original.customStatement(
        'drop index if exists collectibles_local_user_created_idx',
      );
      await original.close();

      final upgraded = LocalArchiveDatabase.forTesting(NativeDatabase(file));
      final existing = await upgraded.getCollectibles('user-1');
      final index = await upgraded
          .customSelect(
            "select name from sqlite_master where type = 'index' "
            "and name = 'collectibles_local_user_created_idx'",
          )
          .getSingleOrNull();

      expect(existing.single.title, 'Existing Item');
      expect(index, isNotNull);
      await upgraded.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
