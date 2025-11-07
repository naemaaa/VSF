// TODO Implement this library.
import 'package:flutter/material.dart';
import 'package:vsf/pages/home/home_page.dart';
import 'package:vsf/pages/profile/profile_page.dart';
import 'package:vsf/pages/activity/activity_list_page.dart';
import 'package:vsf/pages/activity/my_activities_page.dart';
import 'package:vsf/pages/activity/organizer_activities_page.dart';
import '../models/user_model.dart';


class MainScreen extends StatefulWidget {
  final UserModel currentUser;

  const MainScreen({super.key, required this.currentUser});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(), // Beranda
      ActivityListPage(currentUser: widget.currentUser), // Cari
      // Aktivitas: different view for org vs individual
      widget.currentUser.isOrganization
          ? OrganizerActivitiesPage(currentUser: widget.currentUser)
          : MyActivitiesPage(currentUser: widget.currentUser),
      ProfilePage(currentUser: widget.currentUser),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[600],
        unselectedItemColor: Colors.grey[400],
        selectedFontSize: 12,
        unselectedFontSize: 12,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Cari',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_outlined),
            activeIcon: Icon(Icons.event),
            label: 'Aktivitas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}