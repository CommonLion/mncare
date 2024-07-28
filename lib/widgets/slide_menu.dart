import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mncare/screens/input_info_screen.dart';

class SlideMenu extends StatelessWidget {
  const SlideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.orange,
            ),
            child: Text(
              '메뉴',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('프로필'),
            onTap: () {
              // 프로필 페이지로 이동하는 로직
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('설정'),
            onTap: () {
              // 설정 페이지로 이동하는 로직
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('정보'),
            onTap: () {
              // 정보 페이지로 이동하는 로직
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('펫추가'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const InputInfoScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }
}
