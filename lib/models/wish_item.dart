import 'package:hive/hive.dart';

part 'wish_item.g.dart';

@HiveType(typeId: 0)
class WishItem extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String? link;

  @HiveField(2)
  String? description;

  WishItem({required this.title, this.link, this.description});
}
