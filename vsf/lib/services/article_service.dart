import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/article_model.dart';

class ArticleService {
  static final ArticleService _instance = ArticleService._internal();
  
  factory ArticleService() => _instance;
  
  ArticleService._internal();

  static const String BASE_URL = 'http://localhost:3000/api';

  /// Get all articles
  Future<List<ArticleModel>> getAllArticles() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/articles'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((a) => ArticleModel(
          id: a['id'],
          title: a['title'],
          description: a['description'],
          content: a['content'] ?? '',
          imageUrl: a['image_url'],
          category: a['category'],
          authorName: a['author_name'],
          publishedDate: DateTime.parse(a['published_date']),
          views: a['views'] ?? 0,
        )).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  /// Get featured articles (for home page)
  Future<List<ArticleModel>> getFeaturedArticles() async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/articles/featured'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((a) => ArticleModel(
          id: a['id'],
          title: a['title'],
          description: a['description'],
          content: a['content'] ?? '',
          imageUrl: a['image_url'],
          category: a['category'],
          authorName: a['author_name'],
          publishedDate: DateTime.parse(a['published_date']),
          views: a['views'] ?? 0,
        )).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  /// Get single article detail
  Future<ArticleModel?> getArticleDetail(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/articles/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final a = jsonDecode(response.body);
        return ArticleModel(
          id: a['id'],
          title: a['title'],
          description: a['description'],
          content: a['content'],
          imageUrl: a['image_url'],
          category: a['category'],
          authorName: a['author_name'],
          publishedDate: DateTime.parse(a['published_date']),
          views: a['views'] ?? 0,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error: $e');
      return null;
    }
  }

  /// Search articles
  Future<List<ArticleModel>> searchArticles(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/articles/search?title=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((a) => ArticleModel(
          id: a['id'],
          title: a['title'],
          description: a['description'],
          content: a['content'] ?? '',
          imageUrl: a['image_url'],
          category: a['category'],
          authorName: a['author_name'],
          publishedDate: DateTime.parse(a['published_date']),
          views: a['views'] ?? 0,
        )).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }

  /// Get articles by category
  Future<List<ArticleModel>> getArticlesByCategory(String category) async {
    try {
      final response = await http.get(
        Uri.parse('$BASE_URL/articles/category/$category'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((a) => ArticleModel(
          id: a['id'],
          title: a['title'],
          description: a['description'],
          content: a['content'] ?? '',
          imageUrl: a['image_url'],
          category: a['category'],
          authorName: a['author_name'],
          publishedDate: DateTime.parse(a['published_date']),
          views: a['views'] ?? 0,
        )).toList();
      }
      return [];
    } catch (e) {
      print('❌ Error: $e');
      return [];
    }
  }
}