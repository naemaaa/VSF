import 'package:hive/hive.dart'; // Tambahkan import Hive

part 'article_model.g.dart';

@HiveType(typeId: 6) // Asumsi 6 adalah ID unik. Cek apakah ada konflik dengan model lain.
class ArticleModel {
  @HiveField(0) final String id;
  @HiveField(1) final String title;
  @HiveField(2) final String description;
  @HiveField(3) final String content;
  @HiveField(4) final String imageUrl;
  @HiveField(5) final String? category;
  @HiveField(6) final String? authorName;
  @HiveField(7) final DateTime publishedDate;
  @HiveField(8) final String? sourceUrl;
  @HiveField(9) final int views;

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.imageUrl,
    this.category,
    this.authorName,
    required this.publishedDate,
    this.views = 0,
    required this.sourceUrl,
  });

  String get formattedDate {
    return '${publishedDate.day} ${_monthName(publishedDate.month)} ${publishedDate.year}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  // Tambahkan factory method untuk konversi JSON (dari API)
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String,
      category: json['category'] as String?,
      authorName: json['author_name'] as String?,
      // Pastikan date di-parse dengan aman (misal dari string ISO)
      publishedDate: DateTime.parse(json['published_date'] as String), 
      sourceUrl: json['source_url'] as String,
      views: json['views'] as int? ?? 0,
    );
  }

  @override
  String toString() => 'ArticleModel(id: $id, title: $title)';
}
