import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:mncare/screens/trackings/detail_screen.dart';
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
        _selectedPetId = _pets.first.id;
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
      print("Document exists: ${doc.data()}");
      if (data != null) {
        setState(() {
          _trackingData = {
            'poop': data['poop'] ?? 0,
            'food': data['food'] ?? 0,
            'vomit': data['vomit'] ?? 0,
            'water': data['water'] ?? 0,
          };
        });
      }
    } else {
      print("Document does not exist");
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

  String getTranslatedLabel(String label) {
    switch (label) {
      case 'water':
        return '물';
      case 'poop':
        return '대변';
      case 'food':
        return '사료';
      case 'vomit':
        return '구토';
      default:
        return label;
    }
  }

  Widget _buildTrackingItem(String label, String key) {
    String translatedLabel = getTranslatedLabel(label);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(translatedLabel, style: TextStyle(fontSize: 18)),
              ),
              IconButton(
                icon: Icon(Icons.info_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      //이부분이 왜 필요한데?
                      builder: (context) => DetailScreen(
                        label: translatedLabel,
                        value: _trackingData[key] ?? 0,
                        dailyGoal: _trackingData['daily_goal_$key'] ??
                            100, // 예시로 일일 목표 기본값을 100으로 설정
                        feedingTimes: _trackingData['feeding_times_$key'] ??
                            3, // 예시로 사료 주는 횟수 기본값을 3으로 설정
                        onSave: (int newGoal, int newTimes) {
                          setState(() {
                            _trackingData['daily_goal_$key'] = newGoal;
                            _trackingData['feeding_times_$key'] = newTimes;
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.delete_outline),
                onPressed: () {
                  setState(() {
                    _trackingData[key] = 0;
                  });
                  _updateTrackingData(key, 0);
                },
              ),
            ],
          ),
          Text(_trackingData[key].toString(), style: TextStyle(fontSize: 24)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.remove),
                onPressed: !isToday()
                    ? null
                    : () {
                        if (_trackingData[key]! > 0) {
                          _updateTrackingData(key, _trackingData[key]! - 1);
                        }
                      },
              ),
              IconButton(
                icon: Icon(Icons.add),
                onPressed: !isToday()
                    ? null
                    : () {
                        _updateTrackingData(key, _trackingData[key]! + 1);
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await _fetchPets();
    await _loadTrackingData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(_selectedDate),
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: _presentDatePicker,
                    ),
                  ],
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
              ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _trackingData.length,
                itemBuilder: (context, index) {
                  String key = _trackingData.keys.elementAt(index);
                  return _buildTrackingItem(key, key);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Pet {
  final String id;
  final String name;

  Pet({required this.id, required this.name});
}
