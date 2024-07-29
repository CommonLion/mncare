import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  final String label;
  final int value;
  final int dailyGoal;
  final int feedingTimes;
  final Function(int, int) onSave;

  DetailScreen({
    required this.label,
    required this.value,
    required this.dailyGoal,
    required this.feedingTimes,
    required this.onSave,
  });

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late int _dailyGoal;
  late int _feedingTimes;

  @override
  void initState() {
    super.initState();
    _dailyGoal = widget.dailyGoal;
    _feedingTimes = widget.feedingTimes;
  }

  void _saveChanges() {
    widget.onSave(_dailyGoal, _feedingTimes);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.label} 상세보기'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${widget.label}: ${widget.value}', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '일일 목표 사료의 양 (g)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _dailyGoal = int.tryParse(value) ?? _dailyGoal;
                });
              },
              controller: TextEditingController(text: _dailyGoal.toString()),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: '사료 주는 횟수',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _feedingTimes = int.tryParse(value) ?? _feedingTimes;
                });
              },
              controller: TextEditingController(text: _feedingTimes.toString()),
            ),
          ],
        ),
      ),
    );
  }
}
