class ArticleModel {
  final String id;
  final String title;
  final String description;
  final String content;
  final String? imageUrl;
  final String? category;
  final String? authorName;
  final DateTime publishedDate;
  final int views;

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    this.imageUrl,
    this.category,
    this.authorName,
    required this.publishedDate,
    this.views = 0,
  });

  String get formattedDate {
    return '${publishedDate.day} ${_monthName(publishedDate.month)} ${publishedDate.year}';
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  @override
  String toString() => 'ArticleModel(id: $id, title: $title)';
}