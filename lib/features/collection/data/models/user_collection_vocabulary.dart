import 'tag_model.dart';

class UserCollectionVocabulary {
  const UserCollectionVocabulary({
    this.categories = const [],
    this.brands = const [],
    this.franchises = const [],
    this.series = const [],
    this.tags = const [],
  });

  final List<String> categories;
  final List<String> brands;
  final List<String> franchises;
  final List<String> series;
  final List<TagModel> tags;
}
