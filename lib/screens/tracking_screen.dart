import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final DateTime _currentDate = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _trackingData = {
    'poop': 0,
    'food': 0,
    'vomit': 0,
    'water': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    if (user == null) return;

    final String formattedDate = DateFormat('yyyy-MM-dd').format(_currentDate);
    final DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('pets')
        .doc('petId') // 실제 petId를 여기에 넣어야 합니다. //currentUser.petId
        .collection('tracking')
        .doc(formattedDate)
        .get();

    if (doc.exists) {
      setState(() {
        _trackingData = Map<String, int>.from(doc.data() as Map);
      });
    }
  }

  Future<void> _updateTrackingData(String key, int value) async {
    if (user == null) return;

    final String formattedDate = DateFormat('yyyy-MM-dd').format(_currentDate);
    final DocumentReference docRef = _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('pets')
        .doc('petId') // 실제 petId를 여기에 넣어야 합니다. //currentUser.petId
        .collection('tracking')
        .doc(formattedDate);

    setState(() {
      _trackingData[key] = value;
    });

    await docRef.set(_trackingData, SetOptions(merge: true));
  }

  Widget _buildTrackingItem(String label, String key) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          Text(_trackingData[key].toString(), style: TextStyle(fontSize: 24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: () {
                  if (_trackingData[key]! > 0) {
                    _updateTrackingData(key, _trackingData[key]! - 1);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  _updateTrackingData(key, _trackingData[key]! + 1);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('트래킹 화면'),
        centerTitle: true,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          _buildTrackingItem('변', 'poop'),
          _buildTrackingItem('사료', 'food'),
          _buildTrackingItem('구토', 'vomit'),
          _buildTrackingItem('물', 'water'),
        ],
      ),
    );
  }
}
