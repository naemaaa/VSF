// home_page.dart
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vsf/pages/activity/activity_detail_page.dart';
import '../../services/session_service.dart';
import '../../services/article_service.dart';
import '../../services/event_service.dart'; // <-- BARU: Import EventService
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../models/article_model.dart';
import '../../models/user_stats_model.dart';
import '../article/article_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserModel? _currentUser;
  UserStats? _userStats;
  late final Box<UserModel> _userBox;
  late final Box<UserStats> _statsBox;
  
  List<EventModel> _activeEvents = []; // <-- Event aktif
  List<ArticleModel> _articles = [];
  
  bool _loadingData = false; // <-- Loading state gabungan
  
  final ArticleService _articleService = ArticleService();
  final EventService _eventService = EventService(); // <-- Event Service instance

  @override
  void initState() {
    super.initState();
    _userBox = Hive.box<UserModel>('users');
    _statsBox = Hive.box<UserStats>('user_stats');
    
    _loadCurrentUser();
    _loadData();
    
    _userBox.listenable().addListener(() {
      _loadCurrentUser();
      if (mounted) setState(() {});
    });
    
    _statsBox.listenable().addListener(() {
      if (_currentUser != null) {
        _loadUserStats(_currentUser!.id);
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    final user = await SessionService().getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
      
      if (user != null) {
        _loadUserStats(user.id);
      }
    }
  }

  void _loadUserStats(String userId) {
    try {
      UserStats? stats;
      for (var stat in _statsBox.values) {
        if (stat.userId == userId) {
          stats = stat;
          break;
        }
      }

      if (stats == null) {
        // Create new stats entry if not found
        stats = UserStats(userId: userId);
        _statsBox.add(stats);
      }

      if (mounted) {
        setState(() {
          _userStats = stats;
        });
      }
    } catch (e) {
      print('❌ Error loading user stats: $e');
    }
  }

  /// Load event dan artikel dari Service (API/Cache)
  Future<void> _loadData({bool forceRefresh = false}) async {
    if (_loadingData && !forceRefresh) return;
    
    setState(() => _loadingData = true);
    
    try {
      // 1. Load Event Aktif (dari API dengan caching)
      final events = await _eventService.getActiveEvents(forceRefresh: forceRefresh);

      // 2. Load Artikel Unggulan (dari API dengan caching)
      final articles = await _articleService.getFeaturedArticles();
      
      // Urutkan event berdasarkan popularitas untuk "Aktivitas Populer"
      events.sort((a, b) => b.currentVolunteerCount.compareTo(a.currentVolunteerCount));
      
      if (mounted) {
        setState(() {
          _activeEvents = events;
          _articles = articles;
          _loadingData = false;
        });
      }
    } catch (e) {
      print('❌ Error loading data: $e');
      if (mounted) {
        setState(() => _loadingData = false);
      }
    }
  }

  String _formatCurrency(int amount) {
    return 'Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }

  Future<void> _openArticle(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka artikel')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Beranda',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan greeting
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.orange[100],
                      child: _currentUser != null && _currentUser!.profileImagePath != null && _currentUser!.profileImagePath!.isNotEmpty
                          ? ClipOval(
                              child: _currentUser!.profileImagePath!.startsWith('http') 
                                ? Image.network(
                                    _currentUser!.profileImagePath!,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => _initialsPlaceholder(),
                                  )
                                : Image.file(
                                    File(_currentUser!.profileImagePath!),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => _initialsPlaceholder(),
                                  ),
                            )
                          : _initialsPlaceholder(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Halo,',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            _currentUser?.displayName ?? 'Pengguna',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Statistik Cards - Per User
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.people,
                        label: 'Partisipasi',
                        value: (_userStats?.totalParticipations ?? 0).toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.payments,
                        label: 'Donasi Saya',
                        value: _formatCurrency(_userStats?.totalDonations ?? 0),
                        color: Colors.green,
                        isSmallValue: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Artikel Kemanusiaan Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Artikel Kemanusiaan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ArticleListPage(),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Semua',
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                    ),
                  ],
                ),
              ),

              // ARTIKEL LIST dengan Loading State
              _loadingData
                  ? const SizedBox(
                      height: 260,
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _articles.isEmpty
                      ? SizedBox(
                          height: 260,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.article_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada artikel',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 260,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _articles.length,
                            itemBuilder: (context, index) {
                              final article = _articles[index];
                              return _buildArticleCard(article);
                            },
                          ),
                        ),

              const SizedBox(height: 24),

              // Aktivitas Populer Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Aktivitas Populer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'Lainnya',
                        style: TextStyle(color: Colors.blue[600]),
                      ),
                    ),
                  ],
                ),
              ),

              // Event Cards
              _loadingData
                ? const Center(child: Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 20),
                    child: CircularProgressIndicator(),
                  ))
                : _activeEvents.isEmpty 
                  ? Center(child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: Text('Tidak ada event aktif saat ini.', style: TextStyle(color: Colors.grey[600])),
                    ))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _activeEvents.take(3).length, // Hanya tampilkan 3 yang terpopuler
                      itemBuilder: (context, index) {
                        final event = _activeEvents[index];
                        return _buildEventCard(event);
                      },
                    ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper untuk inisial
  Widget _initialsPlaceholder() {
    return Text(
      _currentUser?.initials ?? '?',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.orange[800],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isSmallValue = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallValue ? 14 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(ArticleModel article) {
    return GestureDetector(
      onTap: () => _openArticle(article.sourceUrl ?? ''),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                article.imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 48),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article.category ?? 'Umum',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.formattedDate,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    // Navigasi ke ActivityDetailPage
    void navigateToDetail() {
      if (_currentUser == null) {
        // Handle case where user is not logged in
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda harus login untuk melihat detail kegiatan.')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityDetailPage(event: event, currentUser: _currentUser!),
        ),
      );
    }
    
    return GestureDetector(
      onTap: navigateToDetail,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                event.imageUrl ?? 'https://via.placeholder.com/400x200',
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 160,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, size: 64),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.category,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location.shortAddress, // Gunakan getter dari EventLocationModel
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${event.currentVolunteerCount}/${event.targetVolunteerCount} Volunteer',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: event.volunteerPercentage / 100,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}