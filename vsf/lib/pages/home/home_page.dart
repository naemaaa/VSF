import 'package:flutter/material.dart';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:vsf/pages/activity/activity_detail_page.dart';
import '../../services/session_service.dart';
import '../../services/article_service.dart';
import '../../services/event_service.dart'; 
import 'package:url_launcher/url_launcher.dart';
import '../../models/user_model.dart';
import '../../models/event_model.dart';
import '../../models/article_model.dart';
import '../../models/user_stats_model.dart';
import '../article/article_list_page.dart';
import '../../models/notification_model.dart';
import '../../pages/notification/notification_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  UserModel? _currentUser;
  UserStats? _userStats;
  late final Box<UserModel> _userBox;
  late final Box<UserStats> _statsBox;
  int _unreadNotificationCount = 0;
  late Box<NotificationModel> _notificationBox;
  
  List<EventModel> _activeEvents = []; 
  List<ArticleModel> _articles = [];
  
  bool _loadingData = false; 
  
  final ArticleService _articleService = ArticleService();
  final EventService _eventService = EventService(); 

  Future<void> _loadUnreadNotifications() async {
    try {
      if (_currentUser == null) return;
      
      int unreadCount = 0;
      for (var notif in _notificationBox.values) {
        if (notif.userId == _currentUser!.id && !notif.isRead) {
          unreadCount++;
        }
      }
      
      if (mounted) {
        setState(() => _unreadNotificationCount = unreadCount);
      }
    } catch (e) {
      print('⚠️ Error loading unread notifications: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _userBox = Hive.box<UserModel>('users');
    _statsBox = Hive.box<UserStats>('user_stats');
    _notificationBox = Hive.box<NotificationModel>('notifications');  
    
    _loadCurrentUser();
    _loadData();
    _loadUnreadNotifications(); 
    
    _userBox.listenable().addListener(() {
      _loadCurrentUser();
      if (mounted) setState(() {});
    });
    
    _statsBox.listenable().addListener(() {
      if (_currentUser != null) {
        _loadUserStats(_currentUser!.id);
      }
    });

    _notificationBox.listenable().addListener(() {
      _loadUnreadNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadCurrentUser();
      _loadData();
    }
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

  Future<void> _loadData({bool forceRefresh = false}) async {
    if (_loadingData && !forceRefresh) return;
    
    setState(() => _loadingData = true);
    
    try {
      final events = await _eventService.getActiveEvents(forceRefresh: forceRefresh);
      final articles = await _articleService.getFeaturedArticles();
      
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () => _loadData(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ===== BLUE HEADER SECTION =====
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Top
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Beranda',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const NotificationListPage(),
                                      ),
                                    );
                                  },
                                ),
                                if (_unreadNotificationCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        _unreadNotificationCount.toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Greeting Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: _currentUser != null && 
                                    _currentUser!.profileImagePath != null && 
                                    _currentUser!.profileImagePath!.isNotEmpty
                                    ? ClipOval(
                                        child: _currentUser!.profileImagePath!.startsWith('http') 
                                          ? Image.network(
                                              _currentUser!.profileImagePath!,
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Text(
                                                _currentUser!.initials,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          : Image.file(
                                              File(_currentUser!.profileImagePath!),
                                              width: 64,
                                              height: 64,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Text(
                                                _currentUser!.initials,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                      )
                                    : Text(
                                        _currentUser?.initials ?? '?',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Halo,',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentUser?.displayName ?? 'Pengguna',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
                        const SizedBox(height: 20),

                        // Stats Cards (Inline)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.people,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      (_userStats?.totalParticipations ?? 0).toString(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Partisipasi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.payments,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatCurrency(_userStats?.totalDonations ?? 0),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Donasi',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ===== CONTENT SECTION =====
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Articles Section
                    Row(
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
                    const SizedBox(height: 12),
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
                                  itemCount: _articles.length,
                                  itemBuilder: (context, index) {
                                    final article = _articles[index];
                                    return GestureDetector(
                                      onTap: () => _openArticle(article.sourceUrl ?? ''),
                                      child: Container(
                                        width: 280,
                                        margin: const EdgeInsets.only(right: 12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.08),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(16),
                                              ),
                                              child: Image.network(
                                                article.imageUrl,
                                                height: 140,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                errorBuilder: (c, e, s) => Container(
                                                  height: 140,
                                                  color: Colors.grey[200],
                                                  child: const Icon(Icons.image),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[50],
                                                      borderRadius: BorderRadius.circular(6),
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
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    article.formattedDate,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey[500],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                    const SizedBox(height: 32),

                    // Popular Activities Section
                    Row(
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
                    const SizedBox(height: 12),
                    _loadingData
                        ? const Center(child: CircularProgressIndicator())
                        : _activeEvents.isEmpty
                            ? Center(
                                child: Text(
                                  'Tidak ada event aktif',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _activeEvents.take(3).length,
                                itemBuilder: (context, index) {
                                  final event = _activeEvents[index];
                                  return GestureDetector(
                                    onTap: () {
                                      if (_currentUser == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Login untuk melihat detail'),
                                          ),
                                        );
                                        return;
                                      }
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ActivityDetailPage(
                                            event: event,
                                            currentUser: _currentUser!,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              bottomLeft: Radius.circular(16),
                                            ),
                                            child: Image.network(
                                              event.imageUrl ?? '',
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.image),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[50],
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      event.category,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.blue[600],
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    event.title,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.people,
                                                        size: 12,
                                                        color: Colors.grey[500],
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${event.currentVolunteerCount}/${event.targetVolunteerCount}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}