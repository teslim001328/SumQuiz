import 'package:hive/hive.dart';

part 'local_summary.g.dart';

@HiveType(typeId: 0)
class LocalSummary extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String content;

  @HiveField(2)
  late DateTime timestamp;

  @HiveField(3)
  late bool isSynced;

  @HiveField(4)
  late String userId;

  @HiveField(5)
  late String title;

  @HiveField(6)
  late List<String> tags;

  LocalSummary({
    required this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isSynced = false,
    required this.userId,
    this.tags = const [],
  });

  LocalSummary.empty() {
    id = '';
    title = '';
    content = '';
    timestamp = DateTime.now();
    isSynced = false;
    userId = '';
    tags = [];
  }
}
