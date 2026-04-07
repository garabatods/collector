import 'package:collectorapp/features/collection/data/models/collectible_model.dart';
import 'package:collectorapp/features/collection/data/models/collectible_photo_model.dart';
import 'package:collectorapp/features/collection/data/models/tag_model.dart';
import 'package:collectorapp/features/collection/data/repositories/collectible_photos_repository.dart';
import 'package:collectorapp/features/collection/data/services/upcitemdb_barcode_lookup_service.dart';
import 'package:collectorapp/features/profile/data/models/profile_model.dart';
import 'package:collectorapp/features/wishlist/data/models/wishlist_item_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileModel', () {
    test('maps Supabase JSON into a profile and back to upsert JSON', () {
      final model = ProfileModel.fromJson({
        'id': 'user-1',
        'username': 'collector_01',
        'display_name': 'Collector One',
        'avatar_url': 'https://example.com/avatar.png',
        'bio': 'Loves sixth scale.',
        'created_at': '2026-04-04T10:00:00Z',
        'updated_at': '2026-04-04T10:05:00Z',
      });

      expect(model.id, 'user-1');
      expect(model.username, 'collector_01');
      expect(
        model.toUpsertJson(userId: 'user-1'),
        {
          'id': 'user-1',
          'username': 'collector_01',
          'display_name': 'Collector One',
          'avatar_url': 'https://example.com/avatar.png',
          'bio': 'Loves sixth scale.',
        },
      );
    });
  });

  group('CollectibleModel', () {
    test('maps collector-specific fields from Supabase JSON', () {
      final model = CollectibleModel.fromJson({
        'id': 'item-1',
        'user_id': 'user-1',
        'barcode': '012345678905',
        'title': 'Darth Vader',
        'category': 'Action Figures',
        'franchise': 'Star Wars',
        'series': 'The Black Series',
        'line_or_series': 'The Black Series',
        'character_or_subject': 'Darth Vader',
        'release_year': 2024,
        'box_status': 'boxed',
        'quantity': 2,
        'is_duplicate': true,
        'collectible_tags': [
          {
            'tag': {
              'id': 'tag-1',
              'user_id': 'user-1',
              'name': 'Display Shelf',
            },
          },
        ],
        'created_at': '2026-04-04T10:00:00Z',
      });

      expect(model.barcode, '012345678905');
      expect(model.tags.single.name, 'Display Shelf');
      expect(model.franchise, 'Star Wars');
      expect(model.lineOrSeries, 'The Black Series');
      expect(model.characterOrSubject, 'Darth Vader');
      expect(model.releaseYear, 2024);
      expect(model.boxStatus, 'boxed');
      expect(model.isDuplicate, isTrue);
    });

    test('writes both series columns for compatibility', () {
      const model = CollectibleModel(
        barcode: '012345678905',
        title: 'Batman',
        category: 'Memorabilia',
        lineOrSeries: 'Animated Series',
      );

      expect(
        model.toInsertJson(userId: 'user-1'),
        containsPair('barcode', '012345678905'),
      );
      expect(
        model.toInsertJson(userId: 'user-1'),
        containsPair('series', 'Animated Series'),
      );
      expect(
        model.toInsertJson(userId: 'user-1'),
        containsPair('line_or_series', 'Animated Series'),
      );
    });
  });

  group('TagModel', () {
    test('maps Supabase JSON into a tag and back to insert JSON', () {
      final model = TagModel.fromJson({
        'id': 'tag-1',
        'user_id': 'user-1',
        'name': 'Display Shelf',
        'created_at': '2026-04-05T10:00:00Z',
      });

      expect(model.id, 'tag-1');
      expect(model.userId, 'user-1');
      expect(model.name, 'Display Shelf');
      expect(
        model.toInsertJson(userId: 'user-1'),
        {
          'user_id': 'user-1',
          'name': 'Display Shelf',
        },
      );
    });
  });

  group('CollectiblePhotoModel', () {
    test('maps storage metadata cleanly', () {
      final model = CollectiblePhotoModel.fromJson({
        'id': 'photo-1',
        'collectible_id': 'item-1',
        'storage_bucket': 'collectible-photos',
        'storage_path': 'user-1/item-1/main.jpg',
        'is_primary': true,
        'display_order': 0,
      });

      expect(model.collectibleId, 'item-1');
      expect(model.storageBucket, 'collectible-photos');
      expect(model.isPrimary, isTrue);
    });

    test('builds the expected storage path structure for uploads', () {
      final path = CollectiblePhotosRepository.buildPrimaryStoragePath(
        userId: 'user-1',
        collectibleId: 'item-1',
        originalFileName: 'figure.png',
      );

      expect(path, startsWith('user-1/item-1/primary-'));
      expect(path, endsWith('.png'));
    });

    test('maps common file types to supported storage content types', () {
      expect(
        CollectiblePhotosRepository.contentTypeForFileName('photo.jpeg'),
        'image/jpeg',
      );
      expect(
        CollectiblePhotosRepository.contentTypeForFileName('photo.heic'),
        'image/heic',
      );
      expect(
        CollectiblePhotosRepository.contentTypeForFileName('photo.webp'),
        'image/webp',
      );
    });
  });

  group('WishlistItemModel', () {
    test('maps wishlist collector metadata and preserves line_or_series', () {
      const model = WishlistItemModel(
        title: 'Spider-Man 2099',
        category: 'Action Figures',
        franchise: 'Marvel',
        lineOrSeries: 'Marvel Legends',
        characterOrSubject: 'Spider-Man 2099',
        releaseYear: 2025,
        boxStatus: 'sealed',
      );

      final json = model.toInsertJson(userId: 'user-1');

      expect(json['franchise'], 'Marvel');
      expect(json['line_or_series'], 'Marvel Legends');
      expect(json['series'], 'Marvel Legends');
      expect(json['box_status'], 'sealed');
    });
  });

  group('UpcItemDbBarcodeLookupService', () {
    test('maps collector toy products into app categories', () {
      expect(
        UpcItemDbBarcodeLookupService.suggestCollectorCategory(
          rawCategory: 'Toys & Games > Toy Figures & Playsets',
          title: 'Star Wars The Vintage Collection Boba Fett',
        ),
        'Action Figures',
      );
    });

    test('maps card products into trading cards', () {
      expect(
        UpcItemDbBarcodeLookupService.suggestCollectorCategory(
          rawCategory: 'Collectibles > Trading Cards',
          title: 'Pokemon Scarlet & Violet Booster Pack',
        ),
        'Trading Cards',
      );
    });
  });
}
