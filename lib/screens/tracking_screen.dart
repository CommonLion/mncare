import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  DateTime _selectedDate = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _trackingData = {
    'poop': 0,
    'food': 0,
    'vomit': 0,
    'water': 0,
  };
  String? _selectedPetId;
  List<Pet> _pets = [];

  @override
  void initState() {
    super.initState();
    _fetchPets();
  }

  Future<void> _fetchPets() async {
    if (user == null) return;

    final querySnapshot = await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('pets')
        .get();

    setState(() {
      _pets = querySnapshot.docs
          .map((doc) => Pet(id: doc.id, name: doc.data()['petName'] as String))
          .toList();
      if (_pets.isNotEmpty) {
        _selectedPetId = _pets.first.id; // 여기를 current petid로 모든 화면에대한 세션으로 유지
        _loadTrackingData();
      }
    });
  }

  Future<void> _loadTrackingData() async {
    if (user == null || _selectedPetId == null) return;

    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final DocumentSnapshot doc = await _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('pets')
        .doc(_selectedPetId)
        .collection('trackings')
        .doc(formattedDate)
        .get();
    print('선택된 펫 ID: $_selectedPetId');

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      print("Document exists: ${doc.data()}"); // 로그 추가
      if (data != null) {
        setState(() {
          _trackingData = {
            'poop': data['poop'] != null ? data['poop'] as int : 0,
            'food': data['food'] != null ? data['food'] as int : 0,
            'vomit': data['vomit'] != null ? data['vomit'] as int : 0,
            'water': data['water'] != null ? data['water'] as int : 0,
          };
        });
      }
    } else {
      print("Document does not exist"); // 로그 추가
      setState(() {
        _trackingData = {
          'poop': 0,
          'food': 0,
          'vomit': 0,
          'water': 0,
        };
      });
    }
  }

  Future<void> _updateTrackingData(String key, int value) async {
    if (user == null || _selectedPetId == null || !isToday()) return;

    final String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final DocumentReference docRef = _firestore
        .collection('users')
        .doc(user!.uid)
        .collection('pets')
        .doc(_selectedPetId)
        .collection('trackings')
        .doc(formattedDate);

    setState(() {
      _trackingData[key] = value;
    });

    await docRef.set(_trackingData, SetOptions(merge: true));
  }

  bool isToday() {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
           _selectedDate.month == now.month &&
           _selectedDate.day == now.day;
  }

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _loadTrackingData();
      });
    }
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
                onPressed: !isToday() ? null : () {
                  if (_trackingData[key]! > 0) {
                    _updateTrackingData(key, _trackingData[key]! - 1);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: !isToday() ? null : () {
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),  
            ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _selectedDate,
            calendarFormat: CalendarFormat.week,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _loadTrackingData();
              });
            },
            headerVisible: false,
            daysOfWeekVisible: true,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: _presentDatePicker,
              child: Text('날짜 선택'),
            ),
          ),
          if (_pets.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: DropdownButton<String>(
                  value: _selectedPetId,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPetId = newValue;
                      _loadTrackingData();
                    });
                  },
                  items: _pets.map<DropdownMenuItem<String>>((Pet pet) {
                    return DropdownMenuItem<String>(
                      value: pet.id,
                      child: Text(pet.name),
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                _buildTrackingItem('변', 'poop'),
                _buildTrackingItem('사료', 'food'),
                _buildTrackingItem('구토', 'vomit'),
                _buildTrackingItem('물', 'water'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Pet {
  final String id;
  final String name;

  Pet({required this.id, required this.name});
}
