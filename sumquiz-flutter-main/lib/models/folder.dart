import 'package:hive/hive.dart';

part 'folder.g.dart';

@HiveType(typeId: 5)
class Folder extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String userId;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  Folder({
    required this.id,
    required this.name,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  Folder.empty() {
    id = '';
    name = '';
    userId = '';
    createdAt = DateTime.now();
    updatedAt = DateTime.now();
  }
}
