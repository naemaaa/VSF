import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/article_model.dart';

class ArticleService {
  static final ArticleService _instance = ArticleService._internal();
  
  factory ArticleService() => _instance;
  
  ArticleService._internal();

  static const String SUPABASE_URL = 'https://jazhzojpgcumghslmquk.supabase.co';
  static const String SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imphemh6b2pwZ2N1bWdoc2xtcXVrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3OTk5MzUsImV4cCI6MjA3NzM3NTkzNX0.uPzc8dVI-LgDXY2aS_K8rSWx7kdwL5oV6xBHS9j1xEo';
  
  final _headers = {
    'Content-Type': 'application/json',
    'apikey': SUPABASE_ANON_KEY,
    'Authorization': 'Bearer $SUPABASE_ANON_KEY',
  };

  /// Get all articles from API with caching
  Future<List<ArticleModel>> getAllArticles({bool forceRefresh = false}) async {
    final articleBox = Hive.box<ArticleModel>('articles');
    
    // 1. Cek cache dulu (offline-first)
    if (!forceRefresh && articleBox.isNotEmpty) {
      print('📦 Loading articles from cache (${articleBox.length} items)');
      return articleBox.values.toList();
    }

    // 2. Fetch dari API
    try {
      print('🌐 Fetching articles from Supabase API...');
      final response = await http.get(
      Uri.parse('$SUPABASE_URL/rest/v1/articles?order=published_date.desc'),
      headers: _headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('✅ Fetched ${data.length} articles from API');
        
        final articles = data.map((json) => ArticleModel(
          id: json['id'].toString(),
          title: json['title'] ?? '',
          description: json['description'] ?? '',
          content: json['content'] ?? '',
          imageUrl: json['image_url'] ?? 'https://via.placeholder.com/400x200',
          category: json['category'],
          authorName: json['author_name'],
          sourceUrl: json['source_url'],
          publishedDate: DateTime.parse(json['published_date']),
          views: json['views'] ?? 0,
        )).toList();
        
        // 3. Simpan ke cache
        await _updateCache(articles);
        
        return articles;
      } else {
        print('❌ API Error: ${response.statusCode}');
        // Fallback ke cache jika ada
        if (articleBox.isNotEmpty) {
          print('📦 Using cached data as fallback');
          return articleBox.values.toList();
        }
        return [];
      }
    } catch (e) {
      print('❌ Network Error: $e');
      // Fallback ke cache
      if (articleBox.isNotEmpty) {
        print('📦 Using cached data (offline mode)');
        return articleBox.values.toList();
      }
      return [];
    }
  }

  /// Update cache (clear old, add new)
  Future<void> _updateCache(List<ArticleModel> articles) async {
    final articleBox = Hive.box<ArticleModel>('articles');
    await articleBox.clear();
    for (var article in articles) {
      await articleBox.put(article.id, article);
    }
    print('💾 Cache updated with ${articles.length} articles');
  }

  /// Get featured articles (limit 5)
  Future<List<ArticleModel>> getFeaturedArticles() async {
    final all = await getAllArticles();
    return all.take(5).toList();
  }

  /// Get single article detail
  Future<ArticleModel?> getArticleDetail(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$SUPABASE_URL/articles?id=eq.$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final json = data.first;
          return ArticleModel(
            id: json['id'].toString(),
            title: json['title'] ?? '',
            description: json['description'] ?? '',
            content: json['content'] ?? '',
            imageUrl: json['image_url'] ?? 'https://via.placeholder.com/400x200',
            category: json['category'],
            authorName: json['author_name'],
            sourceUrl: json['source_url'],
            publishedDate: DateTime.parse(json['published_date']),
            views: json['views'] ?? 0,
          );
        }
      }
      return null;
    } catch (e) {
      print('❌ Error: $e');
      return null;
    }
  }

  /// Search articles
  Future<List<ArticleModel>> searchArticles(String query) async {
    final all = await getAllArticles();
    final lowerQuery = query.toLowerCase();
    return all.where((a) => 
      a.title.toLowerCase().contains(lowerQuery) ||
      a.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// Get articles by category
  Future<List<ArticleModel>> getArticlesByCategory(String category) async {
    final all = await getAllArticles();
    return all.where((a) => a.category == category).toList();
  }
}