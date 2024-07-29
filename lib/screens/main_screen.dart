import 'package:flutter/material.dart';

import 'calendar/calendar_screen.dart';
import 'community_screen.dart';
import 'home_screen.dart';
import 'pet_doctor_screen.dart';
import 'trackings/tracking_screen.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/slide_menu.dart';
import '../widgets/top_app_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 2; // 홈 화면을 기본으로 설정
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const TrackingScreen(),
    const CalendarScreen(),
    const HomeScreen(),
    const PetDoctorScreen(),
    const CommunityScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: TopAppBar(
        selectedIndex: _selectedIndex,
        onMenuPressed: _openEndDrawer,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      endDrawer: SlideMenu(),
    );
  }
}
